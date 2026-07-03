# Trading XAUUSD (Gold) — Instrument-Specific Notes

XAUUSD (spot gold vs USD) trades very differently from forex pairs. Bake these
realities into every EA/indicator. **Query broker values at runtime; the numbers
below are typical, not universal.**

## Symbol naming varies by broker
Gold is not always `XAUUSD`. Seen in the wild: `XAUUSD`, `XAUUSD.m`,
`XAUUSD.i`, `XAUUSD_i`, `XAUUSD-ECN`, `GOLD`, `GOLD.spot`. **Make the symbol an
input**, default `XAUUSD`, and verify with `SymbolSelect(sym, true)` /
`SymbolInfoInteger(sym, SYMBOL_SELECT)`.

## Digits, point, and "pips" — the biggest source of bugs
- Gold is usually quoted with **2 digits** (e.g. `2345.67`), so
  `SYMBOL_POINT = 0.01`. Some brokers use **3 digits** (`0.001`).
- There is no universal "pip" for gold. Traders often call a **$1.00 move a
  "dollar"** and a **$0.10 move a "pip,"** but do not rely on this — work in
  **points** (the broker's `SYMBOL_POINT`) everywhere in code.
- A "100-pip" forex habit translates to a huge distance on gold. Size stops in
  **ATR or dollars of price**, not a hardcoded point count copied from a forex EA.

Always:
```mql5
double point  = SymbolInfoDouble(sym, SYMBOL_POINT);
int    digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
```

## Contract size & tick value
- Standard contract is typically **100 troy ounces per 1.0 lot**, so a $1.00
  price move on 1.0 lot ≈ **$100** P/L (in USD account). Micro/cent accounts
  differ.
- Don't assume — read `SYMBOL_TRADE_TICK_VALUE` and `SYMBOL_TRADE_TICK_SIZE`
  and derive value-per-point:
  `valuePerPoint = SYMBOL_TRADE_TICK_VALUE * (SYMBOL_POINT / SYMBOL_TRADE_TICK_SIZE)`.
  See `references/risk-management.md`.
- Min lot is usually `0.01`; check `SYMBOL_VOLUME_MIN/STEP`.

## Spread & execution
- Gold spreads are **wider and more variable** than majors — often several
  dollars, and they **blow out around news, rollover (server midnight), and
  session open**. Always include a **spread guard** (`InpMaxSpreadPoints`).
- Slippage is real; set a reasonable `CTrade::SetDeviationInPoints` (e.g. 30–100
  points depending on digits) and check for requotes.
- Respect `SYMBOL_TRADE_STOPS_LEVEL` and `SYMBOL_TRADE_FREEZE_LEVEL` — gold's
  minimum stop distance is often larger than forex.

## Volatility
- Gold is a **high-volatility** instrument. Daily ranges of $20–$50+ are common,
  and spikes of $10 in minutes happen on news. This means:
  - **Wider stops** than forex — a tight fixed stop gets wicked out constantly.
  - **Smaller lot sizes** for the same account risk %.
  - **ATR-based sizing** adapts better than fixed points. `iATR(sym, tf, 14)`.

## Sessions & timing (server time may not be your local time!)
- Most action is in the **London (≈07:00–16:00 GMT)** and **New York
  (≈12:00–21:00 GMT)** sessions, with the **London/NY overlap (≈12:00–16:00
  GMT)** the most liquid/volatile.
- The **Asian session** is quieter and more range-bound.
- Beware the **daily rollover** (broker server midnight): spreads widen, swaps
  are charged. Read the broker's server offset; don't assume GMT.

## News sensitivity
Gold reacts violently to USD and rates news. High-impact events to optionally
filter around:
- **FOMC** rate decisions & minutes, Fed speakers.
- **US CPI / PPI** (inflation).
- **NFP / Non-Farm Payrolls** (first Friday).
- **US GDP, retail sales**, geopolitical risk headlines.
Consider a **news blackout** input that pauses new entries around these.

## Correlations to be aware of
- **Inverse to the US Dollar Index (DXY)** most of the time.
- Inverse-ish to **US real yields**; a safe-haven bid during risk-off.
- Loosely correlated with silver (XAGUSD) and other precious metals.

## Practical defaults for a gold EA
- Symbol: `input string InpSymbol = "XAUUSD";`
- SL/TP: ATR-based (e.g. SL = 1.5–2.0 × ATR(14), TP = 2–3 × SL distance).
- Max spread guard: expose as input; typical starting point a few dollars in
  points (e.g. 50 points on 2-digit = $0.50 — tune to your broker).
- Risk: **≤1% per trade**; gold's volatility punishes oversizing.
- Trade window: restrict to London/NY overlap unless the strategy is explicitly
  a range/Asian-session play.
- Always demo-test across a news week before going live.
