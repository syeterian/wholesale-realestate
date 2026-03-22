---
name: wholesale-realestate
description: Full wholesale real estate workflow — search for deals in a city/area, analyze numbers (ARV, MAO, repair costs), make an offer, and close/assign the contract. Use when user mentions wholesaling, finding deals, searching for properties, making offers, assigning contracts, or asks about real estate investment analysis.
tools: Read, Write, Glob, Grep, Bash, WebSearch, mcp__plugin_context-mode_context-mode__ctx_fetch_and_index, mcp__plugin_context-mode_context-mode__ctx_search, mcp__plugin_context-mode_context-mode__ctx_batch_execute
---

# Wholesale Real Estate — Full Workflow

Guide the user through every stage of a wholesale real estate deal from lead to close.

---

## Stage 0: Deal Finder (Search by City / Area)

**Trigger:** User says "find deals in [city]", "search [area]", "what's available in [zip/city]", or similar.

### Step 1 — Collect search parameters

Ask the user:
```
City or area to search:
Property types (SFR, multi-family, both):
Max price (leave blank for no limit):
Min bedrooms (default: 2):
Any specific zip codes or neighborhoods? (optional):
```

### Step 2 — Run motivated-seller searches

Use **WebSearch** with the following query patterns (substitute user's city/area):

```
Motivated seller search queries to run in parallel:

1. site:zillow.com "[CITY]" "price reduced" "as-is" -agent
2. site:craigslist.org "[CITY]" "motivated seller" OR "must sell" OR "as-is" real estate
3. site:redfin.com "[CITY]" "fixer" OR "TLC" OR "as-is" "days on market"
4. "[CITY] foreclosure listings" OR "[CITY] pre-foreclosure homes for sale"
5. "[CITY] tax delinquent property list [YEAR]" OR "[CITY] tax lien properties"
6. site:facebook.com "marketplace" "[CITY]" "we buy houses" OR "FSBO" OR "cash only"
7. "[CITY] probate real estate listings" OR "[CITY] estate sale homes"
8. "[CITY] absentee owner properties for sale"
```

Run at minimum queries 1, 2, 3, and 4. Run all 8 for a thorough search.

### Step 3 — Fetch and index promising results

For each promising URL found in search results, use `ctx_fetch_and_index(url, source)` to pull the full listing details. Label the source as `"deal-[address]"` so results can be searched later.

### Step 4 — Score and filter leads

For each property found, score it on the **Motivated Seller Score (MSS)**:

| Signal | Points |
|--------|--------|
| Listed as "as-is" or "fixer" | +2 |
| Price reduced (any reduction) | +2 |
| DOM > 60 days | +2 |
| DOM > 90 days | +3 |
| Listed below estimated ARV by >30% | +3 |
| Foreclosure / pre-foreclosure | +3 |
| Probate / estate sale | +2 |
| Tax delinquent | +3 |
| FSBO (no agent) | +1 |
| Vacant / abandoned indicator | +2 |

**Score thresholds:**
- 8+ points → Hot Lead (pursue immediately)
- 5–7 points → Warm Lead (worth investigating)
- < 5 points → Skip

### Step 5 — Present results table

Output a ranked table of the top leads found:

```
## Deal Finder Results — [CITY/AREA]
Search date: [today's date]

| # | Address | Price | Est. ARV | Est. Repairs | MSS | Status | Source |
|---|---------|-------|----------|--------------|-----|--------|--------|
| 1 | ...     | $...  | $...     | $...         | 10  | Hot    | Zillow |
| 2 | ...     | $...  | $...     | $...         | 7   | Warm   | CL     |
...

Hot Leads: X | Warm Leads: Y | Total found: Z
```

For ARV and repair estimates, use neighborhood price data from search results and apply conservative estimates (note they are estimates until comps are run).

### Step 6 — Offer next action

After presenting results, ask:
```
Which property would you like to dig deeper on?
→ Type a number to run full deal analysis (Stage 2 onward)
→ Type "search more" to expand the search
→ Type "export" to save results to a file
```

If user says **"export"**, write the results table to `wholesale-leads-[CITY]-[DATE].md` in the current directory.

If user picks a property, automatically continue to **Stage 2** (Deal Analysis) with that property pre-filled.

---

## Stage 1: Qualify an Existing Lead

Ask the user for the property address or lead source, then help them qualify the lead.

**Motivated Seller Checklist:**
- Distressed property (visible repairs, code violations, tax liens)?
- Owner situation: divorce, probate, foreclosure, out-of-state landlord, tired landlord?
- Days on market (DOM > 90 = motivated)?
- Asking price vs. estimated ARV?

**Lead Sources to suggest if user has no deal yet:**
- Driving for dollars (Propstream, DealMachine)
- Direct mail (tax delinquent lists, absentee owners)
- MLS — expired/cancelled listings
- Bandit signs, Facebook Marketplace FSBO, Craigslist
- Probate court records, foreclosure auction lists

---

## Stage 2: Analyze the Deal

Collect the following inputs from the user, then calculate the offer.

### Inputs to Gather
```
Property address:
Bedrooms / Bathrooms / Sqft:
Year built:
Estimated ARV (After Repair Value): $
Estimated repair costs: $
Your wholesale fee target: $
End buyer's desired profit margin (default 20%):
Holding/closing costs estimate (default 10% of ARV):
```

### MAO Formula (Maximum Allowable Offer)
```
MAO = ARV × 0.70 − Repairs − Wholesale Fee

Example:
  ARV:          $200,000
  × 70%:        $140,000
  − Repairs:    − $30,000
  − Wholesale:  − $10,000
  MAO:          $100,000
```

### Deal Scorecard
| Metric | Value | Pass? |
|--------|-------|-------|
| Offer ≤ MAO | | ✅ / ❌ |
| ARV source (comps) | | ✅ / ❌ |
| Repair estimate source | | ✅ / ❌ |
| End buyer identified | | ✅ / ❌ |
| Assignment fee ≥ $5,000 | | ✅ / ❌ |

Output the completed scorecard and state whether the deal passes.

---

## Stage 3: Run Comps (ARV Estimation)

Help the user estimate ARV from comparables.

**Comp criteria (SAME criteria as end buyer's lender will use):**
- Within 1 mile (0.5 mile in urban areas)
- Sold within last 6 months
- Similar sqft (±20%), bed/bath, style
- After-repaired condition

**If user has no comps yet**, instruct them to:
1. Pull from MLS, Zillow, Redfin, Realtor.com
2. Use Propstream or BatchLeads for off-market data
3. Ask a local real estate agent for a quick CMA

Calculate: `ARV = Average price per sqft of comps × Subject property sqft`

---

## Stage 4: Make the Offer

### Offer Conversation Script
Present this to the user to use with the seller:

```
"Hi [Seller], based on what the home needs and what similar homes
are selling for in the area, I can offer you $[MAO] cash, as-is,
close in [14–21] days, no commissions, no contingencies.

Would that work for you?"
```

**Negotiation anchors:**
- Start at MAO − 5–10% to leave room to negotiate up
- Emphasize speed, certainty, and no repairs needed
- If seller counters high, ask: "What's the lowest you'd go to close quickly?"

### Purchase and Sale Agreement checklist
- Property address (legal description)
- Purchase price = your offer
- Earnest money deposit (typically $500–$2,000)
- Inspection / due diligence period (7–14 days)
- **Assignment clause**: "And/or assigns" after buyer's name — CRITICAL
- Closing date
- As-is clause

---

## Stage 5: Find an End Buyer & Assign the Contract

### End Buyer Sources
- Your existing cash buyer list
- Local REIA (Real Estate Investor Association) meetings
- Facebook Groups: "We Buy Houses [City]", local investor groups
- Bigger Pockets forums
- Craigslist "Real Estate Wanted" section
- Other wholesalers (co-wholesale)

### Assignment of Contract
```
Assignment Fee = End Buyer's Purchase Price − Your Contract Price

Example:
  Your contract:    $100,000
  End buyer pays:   $110,000
  Your fee:         $10,000
```

**Assignment Agreement must include:**
- Original contract reference
- Assignor (you) and Assignee (end buyer) details
- Assignment fee amount
- End buyer takes over all rights and obligations

---

## Stage 6: Close the Deal

### Closing Checklist
- [ ] Title company / closing attorney selected (use investor-friendly title co.)
- [ ] Title search ordered — confirm no liens beyond seller's mortgage
- [ ] End buyer has proof of funds or hard money approval
- [ ] Assignment agreement signed and delivered to title
- [ ] Closing date confirmed with all parties
- [ ] Assignment fee collected at closing (wire or cashier's check)
- [ ] Disbursement sheet reviewed before signing

### Post-Close
- Add end buyer to your buyers list with purchase criteria
- Send thank-you to seller
- Track deal in your CRM: address, ARV, repair, sale price, fee, closing date
- Analyze: what went right / wrong for next deal

---

## Key Formulas Reference

| Formula | Equation |
|---------|----------|
| MAO | ARV × 0.70 − Repairs − Wholesale Fee |
| Assignment Fee | End Buyer Price − Contract Price |
| ARV per sqft | Comp Sale Price ÷ Comp Sqft |
| Subject ARV | ARV/sqft × Subject Sqft |
| Net to Seller | Contract Price − Seller's Liens − Closing Costs |

---

## Quick Commands

When the user provides deal numbers, automatically run Stage 2 analysis and output the MAO and Deal Scorecard without asking for permission.

When the user says "I have a deal" or provides an address, start at Stage 1 and walk through each stage sequentially, asking only for the inputs needed at each step.
