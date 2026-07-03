# Risk Management & Position Sizing

The non-negotiable safety layer for any EA. Every trade must: size from account
risk, carry a stop loss, and respect broker volume/stop constraints. Gold's
volatility makes correct sizing especially important — the same dollar risk buys
a much smaller lot than on a forex major.

## Value per point (the foundation)

`SYMBOL_TRADE_TICK_VALUE` is profit for a one-tick move on 1.0 lot, in account
currency. Convert to value per *point*:

```mql5
double ValuePerPoint(string sym)
{
   double tickVal  = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   double point    = SymbolInfoDouble(sym, SYMBOL_POINT);
   if(tickSize <= 0) return 0.0;
   return tickVal * (point / tickSize);   // account-ccy P/L per point per 1.0 lot
}
```

## Position sizing by % risk

```mql5
// slPriceDistance = |entry - stopLoss| in PRICE terms (not points).
double CalcLots(string sym, double riskPercent, double slPriceDistance)
{
   if(slPriceDistance <= 0) return 0.0;

   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * riskPercent / 100.0;

   double point   = SymbolInfoDouble(sym, SYMBOL_POINT);
   double vpp     = ValuePerPoint(sym);                 // per 1.0 lot, per point
   if(vpp <= 0 || point <= 0) return 0.0;

   double slPoints    = slPriceDistance / point;
   double lossPerLot  = slPoints * vpp;                 // loss on 1.0 lot if SL hit
   if(lossPerLot <= 0) return 0.0;

   double lots = riskMoney / lossPerLot;
   return NormalizeVolume(sym, lots);
}
```

## Normalize volume to broker constraints (ALWAYS)

```mql5
double NormalizeVolume(string sym, double lots)
{
   double vMin  = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   double vMax  = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   double vStep = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   if(vStep <= 0) vStep = 0.01;

   lots = MathFloor(lots / vStep) * vStep;    // round DOWN to a valid step
   lots = MathMax(vMin, MathMin(vMax, lots));

   int stepDigits = (int)MathCeil(-MathLog10(vStep));
   return NormalizeDouble(lots, MathMax(0, stepDigits));
}
```
Rounding **down** keeps you at or under the intended risk. If the rounded lot is
below `vMin`, either skip the trade or accept `vMin` — but then the trade risks
*more* than the target %, so warn/log it.

## Normalize prices & respect the stops level

```mql5
double NormalizePrice(string sym, double price)
{
   int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   return NormalizeDouble(price, digits);
}

// Clamp an SL/TP so it's at least the broker minimum distance from market.
double EnforceStops(string sym, double price, bool isStopForBuy)
{
   double point   = SymbolInfoDouble(sym, SYMBOL_POINT);
   long   stopLvl = SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist = (stopLvl + 1) * point;
   double bid = SymbolInfoDouble(sym, SYMBOL_BID);
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   // Example for a BUY's stop loss (must sit below bid by >= minDist):
   if(isStopForBuy && (bid - price) < minDist) price = bid - minDist;
   return NormalizePrice(sym, price);
}
```
`10016 invalid stops` almost always means you ignored `SYMBOL_TRADE_STOPS_LEVEL`
or didn't normalize to `SYMBOL_DIGITS`.

## Account-level guards (put a ceiling on bad days)

Track these in globals and check in `OnTick`:
- **Max open positions** for this EA/magic.
- **Max daily loss %**: at start of each day snapshot balance; if
  equity drops below `balance*(1 - maxDailyLoss/100)`, stop opening trades and
  optionally flatten.
- **Max consecutive losses**: pause the EA after N in a row.
- **Margin check**: don't open if resulting margin would exceed a safe fraction
  of free margin (`OrderCalcMargin`).

```mql5
double marginNeeded;
if(OrderCalcMargin(ORDER_TYPE_BUY, sym, lots, ask, marginNeeded))
   if(marginNeeded > AccountInfoDouble(ACCOUNT_MARGIN_FREE) * 0.5) return; // too big
```

## Sizing philosophy for gold
- Default **risk ≤ 1%** per trade; 0.25–0.5% while validating a new strategy.
- Prefer **ATR-based stops** so lot size auto-shrinks when volatility rises.
- Never martingale/grid on a live account without understanding that one adverse
  gold spike can wipe the account. If a user asks for a grid/martingale EA,
  build it but state the ruin risk plainly.
- The math above assumes account currency = USD-ish quote handling. For
  cross-currency accounts, `SYMBOL_TRADE_TICK_VALUE` already accounts for
  conversion, so the formulas still hold — but verify in the tester.
