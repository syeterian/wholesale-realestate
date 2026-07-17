# County Court-Records Portals — lookup reference

Most U.S. counties expose public case search on one of a few court-management systems.
Identify the system, then use its Advanced/Case search to filter by **case filed date** and **case type**.

## By system

| Vendor / system | Common URL patterns | Search entry | Notes |
|-----------------|--------------------|--------------|-------|
| **Tyler Technologies — Odyssey** | `research.[st].tylerhost.net`, `[county].tylerhost.net`, `[county].tylertech.cloud` | "Smart Search" / "Advanced Filtering Search" | Largest footprint. Ohio statewide = `research.oh.tylerhost.net`. |
| **Tyler — re:SearchOH / statewide** | `[state].tylerhost.net` | "Advanced Search" | Some states aggregate all counties. |
| **Odyssey Portal (self-hosted)** | `publicaccess.[county].gov`, `courts.[county].gov`, `[county]courts.[state].gov` | "Case Records Search" | |
| **CourtView / Equivant** | County Clerk of Courts site → "Online Docket" / "Court Records Search" | "Search Cases" | Common in the Midwest. |
| **eCourts / Journal Technologies** | `[county].ecourt.com`, `[state]courts.gov` | "Portal" | |
| **County Clerk of Courts (custom)** | `[county]clerk.gov`, `clerkofcourts.[county].gov` | "Case Search" / "Docket Search" | |
| **Recorder / Auditor (liens, deeds)** | `recorder.[county].gov`, `[county]auditor.gov` | "Official Records" / "Property Search" | Use for lien filings + ownership confirmation. |

## How to find a county's portal

Run **WebSearch** with these patterns (substitute county + state):

- `"[COUNTY] [STATE] clerk of courts public case search"`
- `"[COUNTY] [STATE] court records advanced search"`
- `"[COUNTY] [STATE] tylerhost"` (finds Tyler/Odyssey installs fast)
- `"[COUNTY] [STATE] auditor property search"` (for Stage 4 ownership confirmation)

## Search tips inside the portal

- Set **Case Filed Date** to a rolling 30-day window; re-run monthly (fresh distress = fresh motivation).
- Filter by **Case Type / Case Category** where available — go straight to Foreclosure, Probate/Estate, Domestic Relations, Forcible Entry & Detainer (eviction), and Civil (liens/judgments).
- Export or copy: case number, party caption, case type, file date.
- Save as CSV with header `case_number,caption,case_type,file_date` to feed `scripts/score_cases.py`.

## The seven distress lists (what to pull)

1. Tax delinquency / tax foreclosure
2. Mortgage foreclosure
3. Probate / estate
4. Divorce / dissolution
5. Eviction / landlord (forcible entry & detainer)
6. Code violations / condemnation / nuisance
7. Liens & civil judgments (mechanic's, HOA, money judgments)
