# Expert Advisors (EAs)

How to structure an automated trading EA in MQL5. Start from
`assets/ea_template.mq5`. This file covers anatomy, the trade lifecycle, and
reusable patterns.

## Anatomy

```
#property        headers (copyright, version, strict)
inputs           user parameters (risk, SL/TP, indicator periods, magic)
globals          indicator handles, CTrade object, state (lastBarTime)
OnInit()         create handles, configure CTrade, validate inputs → INIT_SUCCEEDED
OnTick()         the strategy loop (usually gated by IsNewBar)
OnDeinit()       IndicatorRelease, cleanup
helpers          CalcLots, position checks, signal functions
```

## OnInit checklist

1. Validate inputs (risk % in sane range, periods > 0). Return
   `INIT_PARAMETERS_INCORRECT` if bad.
2. Confirm the symbol is available: `SymbolSelect(InpSymbol, true)`.
3. Create every indicator handle; bail with `INIT_FAILED` on `INVALID_HANDLE`.
4. Configure `CTrade`: magic number, deviation, filling mode.
5. Cache symbol properties (point, digits, volMin/Max/Step, stops level).

## The OnTick loop (recommended shape)

```mql5
void OnTick()
{
   // 1. Manage existing position first (trailing stop / break-even / exit).
   ManageOpenPosition();

   // 2. Only evaluate new entries on a new bar (avoids intrabar noise & repaint).
   if(!IsNewBar()) return;

   // 3. Ensure indicator data is ready.
   if(!RefreshSignals()) return;

   // 4. One position per symbol/magic? If already in, stop.
   if(HasOpenPosition()) return;

   // 5. Signal → size → guard → execute.
   int signal = GetSignal();               // +1 long, -1 short, 0 none
   if(signal == 0) return;

   double sl = ComputeStopLoss(signal);
   double tp = ComputeTakeProfit(signal, sl);
   double lots = CalcLotsByRisk(sl);       // see risk-management.md
   if(lots <= 0) return;

   if(signal > 0) trade.Buy (lots, _Symbol, 0.0, sl, tp, "EA long");
   else           trade.Sell(lots, _Symbol, 0.0, sl, tp, "EA short");
}
```

## Signal functions

Keep signal logic pure and testable — read indicator buffers, return
`+1/-1/0`. Example EMA-cross with RSI filter:

```mql5
int GetSignal()
{
   double fast[], slow[], rsi[];
   ArraySetAsSeries(fast,true); ArraySetAsSeries(slow,true); ArraySetAsSeries(rsi,true);
   if(CopyBuffer(hFast,0,0,3,fast) < 3) return 0;
   if(CopyBuffer(hSlow,0,0,3,slow) < 3) return 0;
   if(CopyBuffer(hRsi ,0,0,3,rsi ) < 3) return 0;

   bool crossUp   = fast[2] <= slow[2] && fast[1] > slow[1];   // use closed bars [1],[2]
   bool crossDown = fast[2] >= slow[2] && fast[1] < slow[1];

   if(crossUp   && rsi[1] > 50.0) return  1;
   if(crossDown && rsi[1] < 50.0) return -1;
   return 0;
}
```

Use **closed bars** (`[1]`, `[2]`), not the forming bar `[0]`, so signals don't
repaint.

## Stop loss / take profit

Compute SL/TP as **absolute price levels**, then normalize and enforce the
broker's minimum stop distance (`SYMBOL_TRADE_STOPS_LEVEL`). See
`references/risk-management.md` for `NormalizePrice` and stops-level clamping.
Common SL methods:
- **Fixed points**: `sl = entry ∓ InpStopPoints * point`.
- **ATR-based** (good for gold's changing volatility):
  `sl = entry ∓ InpAtrMult * atr[1]`.
- **Structure**: recent swing high/low from `CopyRates`.

## Managing the open position

```mql5
void ManageOpenPosition()
{
   if(!PositionSelect(_Symbol)) return;
   if(PositionGetInteger(POSITION_MAGIC) != InpMagic) return;

   long   type = PositionGetInteger(POSITION_TYPE);
   double open = PositionGetDouble(POSITION_PRICE_OPEN);
   double sl   = PositionGetDouble(POSITION_SL);
   double bid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // Trailing stop by points:
   double trail = InpTrailPoints * _Point;
   if(type == POSITION_TYPE_BUY)
   {
      double newSL = bid - trail;
      if(newSL > open && (sl == 0 || newSL > sl))
         trade.PositionModify(_Symbol, NormalizePrice(newSL), PositionGetDouble(POSITION_TP));
   }
   else if(type == POSITION_TYPE_SELL)
   {
      double newSL = ask + trail;
      if(newSL < open && (sl == 0 || newSL < sl))
         trade.PositionModify(_Symbol, NormalizePrice(newSL), PositionGetDouble(POSITION_TP));
   }
}
```

Break-even: once profit ≥ X points, move SL to entry (+ a few points buffer).

## Trade filters (strongly recommended for gold)

- **Spread guard**: skip entries when current spread > `InpMaxSpreadPoints`
  (gold spreads blow out around news/rollover).
- **Session filter**: only trade London/NY hours (see `references/xauusd.md`).
- **News filter**: optionally pause around high-impact USD releases.
- **Max positions / max daily loss**: hard stop the EA for the day after N
  losses or a drawdown threshold.

## Netting vs hedging

- **Netting**: one position per symbol. A reverse signal can flip it in one
  trade; check `POSITION_TYPE` before adding.
- **Hedging**: multiple positions allowed; filter strictly by `InpMagic` and
  ticket so the EA only touches its own trades.

## Events beyond OnTick

- `OnTimer()` — periodic tasks (`EventSetTimer(seconds)` in OnInit). Good for
  housekeeping without waiting for ticks.
- `OnTradeTransaction()` — react to fills/SL/TP hits precisely.
- `OnChartEvent()` — buttons/objects if you add a dashboard.
