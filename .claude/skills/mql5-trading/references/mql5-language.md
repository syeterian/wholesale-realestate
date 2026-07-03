# MQL5 Language & API Essentials

MQL5 is a C++-like language for MetaTrader 5. This is the reference for syntax,
event model, and the core APIs used in EAs and indicators. **MQL5 differs
significantly from MQL4** — see the gotchas section at the end.

## Table of contents
1. Program types & event handlers
2. Types, common structs
3. Symbol & account info (read at runtime — never hardcode)
4. Indicator handles & CopyBuffer
5. Trading with CTrade
6. Reading prices & bars
7. Time, timeframes, once-per-bar pattern
8. Error handling & logging
9. MT4 → MT5 gotchas

---

## 1. Program types & event handlers

Three program types, each defined by `#property` and its event functions:

- **Expert Advisor (EA)**: automated trading. Handlers: `OnInit`, `OnTick`,
  `OnDeinit`, optionally `OnTimer`, `OnTrade`, `OnTradeTransaction`,
  `OnChartEvent`.
- **Custom Indicator**: draws on charts. Handlers: `OnInit`, `OnCalculate`,
  `OnDeinit`. Declared with `#property indicator_chart_window` or
  `#property indicator_separate_window`.
- **Script**: runs once. Handler: `OnStart`.

```mql5
int  OnInit()  { return(INIT_SUCCEEDED); }   // or INIT_FAILED / INIT_PARAMETERS_INCORRECT
void OnTick()  { /* fires on every price change */ }
void OnDeinit(const int reason) { /* cleanup: release handles, delete objects */ }
```

## 2. Types & common structs

- Scalars: `int`, `long`, `double`, `bool`, `string`, `datetime`, `color`,
  `uchar`, `ulong`.
- `MqlTick` — current tick: `.bid`, `.ask`, `.last`, `.volume`, `.time`.
  Populate with `SymbolInfoTick(_Symbol, tick)`.
- `MqlRates` — OHLCV bar: `.time .open .high .low .close .tick_volume .spread`.
- `MqlDateTime` — broken-down time via `TimeToStruct()`.
- Inputs are declared with `input` (user-editable) or `sinput` (static):
  ```mql5
  input double  InpRiskPercent = 1.0;   // Risk per trade (%)
  input int     InpMagic       = 990045;
  ```

## 3. Symbol & account info — READ AT RUNTIME

Never hardcode point size, digits, or tick value. Query them:

```mql5
double point   = SymbolInfoDouble(_Symbol, SYMBOL_POINT);          // e.g. 0.01 for 2-digit gold
int    digits  = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
double tickSize= SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE); // profit per tick per 1.0 lot in account ccy
double volMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
double volMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
double volStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
long   stopLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL); // min SL/TP distance in points
double spread  = (SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID))/point;

double balance = AccountInfoDouble(ACCOUNT_BALANCE);
double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
double freeMrg = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
ENUM_ACCOUNT_MARGIN_MODE mm = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
// ACCOUNT_MARGIN_MODE_RETAIL_HEDGING vs _RETAIL_NETTING
```

Always `SymbolSelect(symbol, true)` and check the symbol exists before trading a
non-chart symbol.

## 4. Indicator handles & CopyBuffer (the #1 MT4→MT5 change)

In MT5 you don't call `iMA()` every tick for a value. You create a **handle
once** and copy values from it.

```mql5
int maHandle;   // global
int OnInit()
{
   maHandle = iMA(_Symbol, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE);
   if(maHandle == INVALID_HANDLE) return(INIT_FAILED);
   return(INIT_SUCCEEDED);
}
// later, to read the last 3 values:
double buf[];
ArraySetAsSeries(buf, true);                 // index 0 = current bar
if(CopyBuffer(maHandle, 0, 0, 3, buf) < 3) return;   // 0 = buffer #, 0 = start shift, 3 = count
double maNow = buf[0], maPrev = buf[1];
// release in OnDeinit:
IndicatorRelease(maHandle);
```

Built-in indicator functions returning handles: `iMA, iRSI, iATR, iMACD,
iBands, iStochastic, iADX, iCCI, iEnvelopes, iSAR, iAO, iCustom` (for your own
indicators). Multi-buffer indicators (MACD, Bands, Stochastic) use buffer index
to pick the line — check the docs per indicator.

## 5. Trading with CTrade (use it — don't hand-build OrderSend)

```mql5
#include <Trade/Trade.mqh>
CTrade trade;

int OnInit()
{
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(30);          // slippage tolerance
   trade.SetTypeFillingBySymbol(_Symbol);   // pick a supported fill mode
   return(INIT_SUCCEEDED);
}

// Open (prices/SL/TP are absolute price levels, NOT distances):
trade.Buy (lots, _Symbol, ask, sl, tp, "comment");
trade.Sell(lots, _Symbol, bid, sl, tp, "comment");

// Manage the current position for this symbol:
trade.PositionModify(_Symbol, newSL, newTP);   // trailing stop, break-even
trade.PositionClose(_Symbol);

// Pending orders:
trade.BuyStop(lots, price, _Symbol, sl, tp);
trade.BuyLimit(lots, price, _Symbol, sl, tp);

// Always check the result:
if(!trade.Buy(lots,_Symbol,ask,sl,tp))
   PrintFormat("Buy failed: retcode=%d %s", trade.ResultRetcode(), trade.ResultRetcodeDescription());
```

**Positions vs orders in MT5:** an executed trade is a *position*. Iterate
positions to find yours:

```mql5
for(int i = PositionsTotal()-1; i >= 0; i--)
{
   ulong ticket = PositionGetTicket(i);
   if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
   if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
   long   type   = PositionGetInteger(POSITION_TYPE);  // POSITION_TYPE_BUY/SELL
   double open   = PositionGetDouble(POSITION_PRICE_OPEN);
   double profit = PositionGetDouble(POSITION_PROFIT);
}
```

On a **netting** account there is at most one position per symbol; a Buy while
short reduces/reverses. On **hedging** you can hold multiple — filter by magic +
ticket.

## 6. Reading prices & bars

```mql5
double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);   // buy at ask
double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // sell at bid

MqlRates rates[];
ArraySetAsSeries(rates, true);
int copied = CopyRates(_Symbol, PERIOD_CURRENT, 0, 100, rates);   // last 100 bars, [0]=current
double lastClose = rates[1].close;   // last *closed* bar

// convenience series:
double closes[]; ArraySetAsSeries(closes,true);
CopyClose(_Symbol, PERIOD_CURRENT, 0, 50, closes);
```

## 7. Time, timeframes, once-per-bar pattern

Timeframe enums: `PERIOD_M1, M5, M15, M30, H1, H4, D1, W1, MN1`.

Most strategies should act **once per new bar**, not every tick:

```mql5
datetime lastBarTime = 0;   // global
bool IsNewBar()
{
   datetime t = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(t != lastBarTime) { lastBarTime = t; return true; }
   return false;
}
void OnTick() { if(!IsNewBar()) return; /* bar-close logic */ }
```

## 8. Error handling & logging

- `CopyBuffer`/`CopyRates` return the count copied or -1. Always check; data may
  not be ready in the first ticks after init.
- Check `trade.ResultRetcode()` against `TRADE_RETCODE_DONE`. Common: `10004`
  requote, `10006` rejected, `10014` invalid volume, `10016` invalid stops,
  `10019` no money.
- Use `Print` / `PrintFormat` for logs; they appear in the Experts/Journal tab
  and Strategy Tester journal.

## 9. MT4 → MT5 gotchas (when converting code)

| MT4 | MT5 |
|-----|-----|
| `iMA(...)` returns a value | returns a **handle**; use `CopyBuffer` |
| `OrderSend`, `OrderSelect`, orders | `CTrade`, positions + deals + orders split |
| `Bid` / `Ask` globals | `SymbolInfoDouble(_Symbol, SYMBOL_BID/ASK)` |
| `Point`, `Digits` globals | `_Point`, `_Digits` or `SymbolInfoDouble/Integer` |
| `start()` | `OnTick()` |
| `OrdersTotal()` = open trades | `PositionsTotal()` for open positions |
| 4/5-digit `Point` logic | query `SYMBOL_POINT`; gold is 2–3 digits |
| `MarketInfo()` | `SymbolInfoDouble/Integer` |
| No `datetime` per-bar helper | `iTime(_Symbol,tf,shift)` |

Full API: https://www.mql5.com/en/docs — index it with `ctx_fetch_and_index`
before answering deep API questions if unsure.
