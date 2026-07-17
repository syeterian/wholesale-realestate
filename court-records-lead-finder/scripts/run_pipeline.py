#!/usr/bin/env python3
"""Automated lead pipeline: Apify distressed-property dataset -> ranked callable leads.

This is the "no copy/paste" stage. Claude runs the Apify actor
(dominvo/distressed-property-ai-scraper or a probate/foreclosure leads actor) via
MCP, saves the dataset JSON, and hands it here. This script fuses signals per
property, scores each with the wholesale-tuned rubric, and prints a ranked,
contact-enriched lead sheet ready to dial.

Usage:
    python3 run_pipeline.py <apify_dataset.json> [--min-score N] [--format table|csv|json]

Accepts either a raw Apify dataset export (list of records) or {"items": [...]}.
Tolerant to the several actor schemas in this space — it looks for address,
owner, phone, and signal type across common field names.
"""
import argparse
import json
import sys
from collections import defaultdict

# Signal weight map — mirrors the Court Case Distress Score, keyed on the
# machine-readable signal/mode names the distressed-property actors emit.
SIGNAL_POINTS = {
    "tax_delinquent": 4,
    "tax_lien": 4,
    "tax_sale": 4,
    "foreclosure_auctions": 4,
    "foreclosure": 4,
    "pre_foreclosure": 4,
    "sheriff_sale": 4,
    "notice_of_default": 4,
    "probate_filings": 3,
    "probate": 3,
    "code_violations": 3,
    "demolition_permits": 3,
    "condemnation": 3,
    "vacant_registry": 2,
    "vacant": 2,
    "fire_incidents": 2,
    "eviction": 2,
    "lien": 2,
    "high_equity": 2,        # owner-state: great for a cash offer
    "absentee_owner": 1,     # owner-state: often more motivated
}
STACK_BONUS = 2              # 2+ distinct distress signals on one parcel

# Field-name candidates (actors in this niche don't share one schema).
ADDR_KEYS = ("address", "property_address", "site_address", "situs_address", "full_address")
OWNER_KEYS = ("owner_name", "owner", "defendant", "decedent", "mailing_name", "name")
PHONE_KEYS = ("phone", "phones", "phone_number", "owner_phone", "primary_phone")
SIGNAL_KEYS = ("mode", "signal_type", "event_type", "eventType", "source", "violation_type")
KEY_KEYS = ("parcel_key", "parcel_id", "parcelid", "bbl", "apn", "case_number")


def _first(d, keys):
    for k in keys:
        v = d.get(k)
        if v not in (None, "", [], {}):
            return v
    return None


def flatten(rec):
    """Merge the record's top level with its nested payload into one dict."""
    out = dict(rec)
    payload = rec.get("payload")
    if isinstance(payload, dict):
        for k, v in payload.items():
            out.setdefault(k, v)
    return out


def signal_of(rec) -> str:
    raw = (_first(rec, SIGNAL_KEYS) or "").strip().lower()
    return raw.replace("-", "_").replace(" ", "_")


def phone_str(val) -> str:
    if isinstance(val, list):
        return ", ".join(str(x) for x in val if x)
    return str(val) if val else ""


def load(path):
    with open(path) as f:
        data = json.load(f)
    if isinstance(data, dict):
        data = data.get("items") or data.get("data") or []
    return [flatten(r) for r in data if isinstance(r, dict)]


def group(records):
    """Fuse rows into one entry per property (parcel key, else address)."""
    props = defaultdict(lambda: {"signals": set(), "owner": "", "phone": "",
                                 "address": "", "raw_signals": []})
    for r in records:
        key = _first(r, KEY_KEYS) or _first(r, ADDR_KEYS) or id(r)
        p = props[key]
        sig = signal_of(r)
        if sig:
            p["signals"].add(sig)
            p["raw_signals"].append(sig)
        p["address"] = p["address"] or (_first(r, ADDR_KEYS) or "")
        p["owner"] = p["owner"] or (_first(r, OWNER_KEYS) or "")
        p["phone"] = p["phone"] or phone_str(_first(r, PHONE_KEYS))
    return props


def score(props):
    out = []
    for p in props.values():
        signals = p["signals"]
        pts = 0
        reasons = []
        # take the single highest-value signal as the base, add the rest lighter
        ranked = sorted(signals, key=lambda s: SIGNAL_POINTS.get(s, 0), reverse=True)
        for i, s in enumerate(ranked):
            w = SIGNAL_POINTS.get(s, 0)
            if w == 0:
                continue
            add = w if i == 0 else max(1, w // 2)   # stacked signals count, discounted
            pts += add
            reasons.append(f"{s} (+{add})")
        distinct = [s for s in signals if SIGNAL_POINTS.get(s, 0) > 0]
        if len(distinct) >= 2:
            pts += STACK_BONUS
            reasons.append(f"{len(distinct)} stacked signals (+{STACK_BONUS})")
        tier = "Hot" if pts >= 6 else "Warm" if pts >= 3 else "Skip"
        out.append({
            "owner": p["owner"] or "(unknown — skip-trace)",
            "address": p["address"],
            "phone": p["phone"] or "(needs skip-trace)",
            "signals": ", ".join(sorted(distinct)),
            "score": pts,
            "tier": tier,
            "why": "; ".join(reasons) or "no scored signal",
        })
    out.sort(key=lambda x: x["score"], reverse=True)
    return out


def render(rows, fmt):
    if fmt == "json":
        return json.dumps(rows, indent=2)
    if fmt == "csv":
        cols = ("score", "tier", "owner", "address", "phone", "signals", "why")
        lines = [",".join(cols)]
        for r in rows:
            lines.append(",".join(f'"{r[c]}"' for c in cols))
        return "\n".join(lines)
    lines = [f"{'#':>2}  {'SCORE':>5}  {'Tier':<5}  {'Owner':<22}  {'Address':<30}  {'Phone':<16}  Signals",
             "-" * 120]
    for i, r in enumerate(rows, 1):
        lines.append(f"{i:>2}  {r['score']:>5}  {r['tier']:<5}  {r['owner'][:22]:<22}  "
                     f"{r['address'][:30]:<30}  {r['phone'][:16]:<16}  {r['signals']}")
    hot = sum(1 for r in rows if r["tier"] == "Hot")
    warm = sum(1 for r in rows if r["tier"] == "Warm")
    lines += ["-" * 120,
              f"Properties: {len(rows)}  |  Hot: {hot}  |  Warm: {warm}  |  Skip: {len(rows)-hot-warm}",
              "Call Hot leads first. Confirm ownership + value on the county auditor site before offering."]
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description="Rank distressed-property leads from an Apify dataset.")
    ap.add_argument("input", help="Apify dataset JSON export")
    ap.add_argument("--min-score", type=int, default=0)
    ap.add_argument("--format", choices=["table", "csv", "json"], default="table")
    args = ap.parse_args()
    try:
        records = load(args.input)
    except FileNotFoundError:
        sys.exit(f"error: file not found: {args.input}")
    if not records:
        sys.exit("error: no records in dataset")
    ranked = [r for r in score(group(records)) if r["score"] >= args.min_score]
    print(render(ranked, args.format))


if __name__ == "__main__":
    main()
