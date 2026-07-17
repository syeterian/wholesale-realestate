---
name: court-records-lead-finder
description: Turn public court dockets into a ranked list of motivated-seller real estate leads. Use when the user wants to scrape lawsuits/court records, find distressed property owners, pull foreclosure/probate/tax/eviction lists, score court cases for wholesaling, or asks to build a motivated-seller lead list from public records.
---

# Court Records Lead Finder

Turn free, public court dockets into a ranked list of motivated-seller leads for real estate wholesaling.

**The logic:** defendants in certain lawsuits are financially distressed and often own real estate they need to offload fast — a tax lien, a foreclosure filing, an inherited house stuck in probate, a divorce forcing a sale. Court records are public and updated daily. AI reads hundreds of case captions and flags the handful worth calling.

This skill runs the full loop: **locate portal → pull dockets → score with AI → confirm ownership → skip-trace → hand off to offer.**

---

## Stage 1 — Locate the county court-records portal

Ask the user for their **county and state**. Then identify the portal. Most U.S. counties run one of these systems (full list in `references/court-portals.md`):

| System | URL pattern | Search entry point |
|--------|-------------|--------------------|
| Tyler Technologies (Odyssey) | `research.[st].tylerhost.net`, `[county].tylerhost.net` | "Advanced Search" |
| Odyssey Portal | `publicaccess.[county].gov`, `[county]courts.[state].gov` | "Case Records Search" |
| CourtView / eCourts | County Clerk of Courts → "Online Docket" | "Search Cases" |
| County Clerk / Recorder | `[county].gov` → Court/Land Records | for lien & deed filings |

If unsure, run **WebSearch**: `"[COUNTY] [STATE] clerk of courts public case search"`.

Example the user already knows: Ohio → `research.oh.tylerhost.net`.

## Stage 2 — Pull the dockets (the "seven lists")

In **Advanced Search**, filter by **Case Filed Date** (last 30 days, repeat monthly) and by case type. These seven categories produce motivated-seller leads:

1. **Tax delinquency / tax foreclosure** — "Treasurer v.", "Dept. of Taxation v."
2. **Mortgage foreclosure** — "Bank v.", "Mortgage v."
3. **Probate / estate** — "Estate of", decedent estates
4. **Divorce / dissolution** — domestic relations
5. **Eviction / landlord** — forcible entry & detainer
6. **Code violations / nuisance** — city v. owner, condemnation
7. **Liens & judgments** — mechanic's/HOA liens, civil judgments

Copy the results (case number, parties/caption, case type, file date). Paste them to the user's clipboard or save to a CSV with columns: `case_number,caption,case_type,file_date`.

## Stage 3 — Score the cases with AI

Take the pasted/saved case list and score every case with the **Court Case Distress Score (CCDS)**. Use the bundled script for a deterministic, repeatable ranking:

```bash
python3 scripts/score_cases.py <input.csv|input.json> [--min-score N] [--format table|csv|json]
```

The script keyword-classifies each case caption/type into a distress category and assigns points:

| Signal | Points |
|--------|--------|
| Tax foreclosure / tax delinquency | +4 |
| Mortgage foreclosure | +4 |
| Probate / estate of decedent | +3 |
| Code violation / condemnation | +3 |
| Divorce forcing property sale | +2 |
| Eviction filed by owner (tired landlord) | +2 |
| Mechanic's / HOA lien or civil judgment | +2 |
| Defendant is an individual (not a business) | +1 |
| Same owner appears in multiple filings | +2 |

**Tiers:** 6+ = Hot, 3–5 = Warm, <3 = Skip.

If the user just pastes raw text (not a file), classify it inline using the same rubric and output the ranked table yourself — the script encodes the same rules so results match.

## Stage 4 — Confirm they own real property

For each Hot/Warm lead, verify on the **county auditor / assessor** site (search `"[COUNTY] [STATE] auditor property search"`):
- Name matches a property owner
- Property address + assessed/market value
- Owner-occupied vs. absentee (absentee often = more motivated)

Drop any lead that owns no real estate.

## Stage 5 — Skip-trace for contact info

- Free: `truepeoplesearch.com`, `fastpeoplesearch.com`, `cyberbackgroundchecks.com`
- Paid/bulk (better phone accuracy): BatchLeads, PropStream, Skip Genie, REISkip

## Stage 6 — Hand off to the offer

For each confirmed, skip-traced lead, compute the **Maximum Allowable Offer** before calling:

```
MAO = ARV × 0.70 − Repairs − Wholesale Fee
```

Offer script:
> "Hi [name], I buy houses in [area] cash, as-is, and can close in 2–3 weeks — no repairs, no agent fees. Based on the condition and comps I can offer $[MAO]. Would that help you out?"

Expect ~1 in 10–20 to say yes. Get it under contract with an **"and/or assigns"** clause, then assign to a cash buyer for your fee.

---

## Compliance note

Court records and county assessor data are public. When calling: honor Do-Not-Call requests, follow your state's telemarketing and TCPA rules (manually-dialed calls are generally fine; **automated dialers/texts need prior consent**), and never misrepresent who you are or claim to be affiliated with the court. This skill is a lead-sourcing tool, not legal or investment advice.

---

## Quick start

1. `python3 scripts/score_cases.py assets/sample_dockets.csv` — see the workflow on sample data.
2. Replace the sample CSV with real dockets pulled from your county portal.
3. Confirm ownership → skip-trace → call the Hot leads first.
