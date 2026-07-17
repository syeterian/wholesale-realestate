#!/usr/bin/env python3
"""Court Case Distress Score (CCDS) — rank court dockets by motivated-seller potential.

Usage:
    python3 score_cases.py <input.csv|input.json> [--min-score N] [--format table|csv|json]

Input columns / keys (case-insensitive): case_number, caption, case_type, file_date
`caption` is the party line, e.g. "State of Ohio Dept. of Taxation v. Vincent Sample".
Only `caption` is strictly required; case_type improves accuracy.
"""
import argparse
import csv
import json
import re
import sys
from collections import Counter

# (label, points, regex) — first matching category sets the base distress score.
CATEGORIES = [
    ("Tax foreclosure / delinquency", 4,
     r"tax(ation)?|treasurer|delinquen|tax lien|tax certificate"),
    ("Mortgage foreclosure", 4,
     r"foreclos|mortgage|deed of trust|\bbank\b|savings|credit union|loan servic"),
    ("Probate / estate", 3,
     r"estate of|probate|decedent|deceased|executor|administrator of|guardianship"),
    ("Code violation / condemnation", 3,
     r"code (enforce|violation)|condemn|nuisance|housing court|building department|blight"),
    ("Divorce / dissolution", 2,
     r"divorce|dissolution|in re (the )?marriage|domestic relations|legal separation"),
    ("Eviction (tired landlord)", 2,
     r"evict|forcible entry|detainer|f\.?e\.?d\.?|unlawful detainer|landlord"),
    ("Lien / civil judgment", 2,
     r"mechanic'?s lien|hoa lien|home ?owners? assoc|judgment|judgement|money owed|breach of contract"),
]

# Business / non-person markers → NOT an individual (no +1 individual bonus).
BUSINESS = re.compile(
    r"\b(llc|l\.l\.c|inc\b|incorporated|corp\b|corporation|company|co\.|ltd|"
    r"lp\b|llp|trust|properties|holdings|group|bank|association|partners|"
    r"enterprises|management|realty|authority|board|commission|agency|"
    r"unknown heirs|city of|county of|state of|department)\b",
    re.I)

EVICTION = re.compile(r"evict|forcible entry|detainer|unlawful detainer", re.I)
ESTATE = re.compile(r"(?:matter of the |in re:? |^)estate of\s+(.+?)"
                    r"(?:\s+v[.s]?\.?\s|,|$)", re.I)
ROLE_PREFIX = re.compile(
    r"^(tenant|defendant|plaintiff|unknown|in re:? (the )?marriage of\s+)", re.I)


def _clean(name: str) -> str:
    name = re.sub(r"\(.*?\)", "", name)            # drop parentheticals
    name = ROLE_PREFIX.sub("", name.strip())        # drop role labels / "In re marriage of"
    return name.strip(" .,")


def owner_of_interest(caption: str, blob: str) -> str:
    """The party who likely owns the property — varies by case type.

    - Probate/estate: the decedent named after 'Estate of'.
    - Eviction: the landlord = plaintiff (party before 'v.'), the tired seller.
    - Everything else: the defendant (party after 'v.').
    """
    m = ESTATE.search(caption)
    if m:
        return _clean(m.group(1))
    parts = re.split(r"\bv[.s]?\.?\s", caption, maxsplit=1, flags=re.I)
    if EVICTION.search(blob) and len(parts) > 1:
        return _clean(parts[0])                     # plaintiff / landlord
    return _clean(parts[1] if len(parts) > 1 else caption)


def norm_name(name: str) -> str:
    return re.sub(r"[^a-z ]", "", name.lower()).strip()


def classify(text: str):
    for label, pts, pat in CATEGORIES:
        if re.search(pat, text, re.I):
            return label, pts
    return "Uncategorized", 0


def load(path: str):
    if path.lower().endswith(".json"):
        with open(path) as f:
            data = json.load(f)
        rows = data if isinstance(data, list) else data.get("cases", [])
    else:
        with open(path, newline="") as f:
            rows = list(csv.DictReader(f))
    # normalize keys to lowercase
    return [{(k or "").strip().lower(): (v or "") for k, v in r.items()} for r in rows]


def score(rows):
    # Pre-count owners to award the "multiple filings" bonus.
    def owner(r):
        cap = r.get("caption", "")
        return owner_of_interest(cap, f"{cap} {r.get('case_type', '')}")
    ocount = Counter(norm_name(owner(r)) for r in rows if r.get("caption"))
    out = []
    for r in rows:
        cap = r.get("caption", "")
        blob = f"{cap} {r.get('case_type', '')}"
        label, pts = classify(blob)
        dfn = owner_of_interest(cap, blob)
        reasons = [label] if pts else []
        total = pts
        if cap and dfn and not BUSINESS.search(dfn):
            total += 1
            reasons.append("individual owner (+1)")
        if dfn and ocount[norm_name(dfn)] > 1:
            total += 2
            reasons.append("multiple filings (+2)")
        tier = "Hot" if total >= 6 else "Warm" if total >= 3 else "Skip"
        out.append({
            "defendant": dfn,
            "category": label,
            "case_number": r.get("case_number", ""),
            "case_type": r.get("case_type", ""),
            "file_date": r.get("file_date", ""),
            "ccds": total,
            "tier": tier,
            "why": "; ".join(reasons) or "no distress signal",
        })
    out.sort(key=lambda x: x["ccds"], reverse=True)
    return out


def render(rows, fmt):
    if fmt == "json":
        return json.dumps(rows, indent=2)
    if fmt == "csv":
        buf = ["defendant,category,case_number,ccds,tier,why"]
        for r in rows:
            buf.append(",".join(f'"{r[k]}"' for k in
                       ("defendant", "category", "case_number", "ccds", "tier", "why")))
        return "\n".join(buf)
    # table
    lines = [f"{'#':>2}  {'CCDS':>4}  {'Tier':<5}  {'Defendant / Owner':<26}  {'Category':<28}  Why",
             "-" * 110]
    for i, r in enumerate(rows, 1):
        lines.append(f"{i:>2}  {r['ccds']:>4}  {r['tier']:<5}  "
                     f"{r['defendant'][:26]:<26}  {r['category'][:28]:<28}  {r['why']}")
    hot = sum(1 for r in rows if r["tier"] == "Hot")
    warm = sum(1 for r in rows if r["tier"] == "Warm")
    lines += ["-" * 110, f"Total: {len(rows)} cases  |  Hot: {hot}  |  Warm: {warm}  |  "
              f"Skip: {len(rows) - hot - warm}"]
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description="Score court dockets for motivated-seller potential (CCDS).")
    ap.add_argument("input", help="CSV or JSON file of cases")
    ap.add_argument("--min-score", type=int, default=0, help="Only show cases with CCDS >= N")
    ap.add_argument("--format", choices=["table", "csv", "json"], default="table")
    args = ap.parse_args()

    try:
        rows = load(args.input)
    except FileNotFoundError:
        sys.exit(f"error: file not found: {args.input}")
    if not rows:
        sys.exit("error: no cases found in input")

    ranked = [r for r in score(rows) if r["ccds"] >= args.min_score]
    print(render(ranked, args.format))


if __name__ == "__main__":
    main()
