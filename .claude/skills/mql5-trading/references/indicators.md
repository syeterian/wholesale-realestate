# Custom Indicators

How to write a custom indicator in MQL5. Start from
`assets/indicator_template.mq5`. Indicators compute values into **buffers** and
optionally plot them; EAs consume them via `iCustom` + `CopyBuffer`.

## Anatomy

```
#property indicator_chart_window   OR   indicator_separate_window
#property indicator_buffers N      // total buffers (plotted + calc)
#property indicator_plots   M      // how many are drawn
#property indicator_labelX / colorX / typeX / widthX   // per-plot styling
inputs
double buffers[]                   // one array per buffer, bound in OnInit
OnInit()      SetIndexBuffer, PlotIndexSetX, IndicatorSetString(name)
OnCalculate() the compute loop
```

## Buffer binding (OnInit)

```mql5
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "MyRSI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_width1  2

double MainBuffer[];    // plotted
double CalcBuffer[];    // intermediate, not drawn

int OnInit()
{
   SetIndexBuffer(0, MainBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, CalcBuffer, INDICATOR_CALCULATIONS);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   IndicatorSetString(INDICATOR_SHORTNAME, "MyRSI(14)");
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
   return(INIT_SUCCEEDED);
}
```

`SetIndexBuffer` types: `INDICATOR_DATA` (plotted), `INDICATOR_CALCULATIONS`
(internal), `INDICATOR_COLOR_INDEX` (for `DRAW_COLOR_*`).

## OnCalculate — the two forms

MetaTrader calls `OnCalculate` on each tick/history update. Two prototypes;
pick one.

**Price-array form** (most flexible):
```mql5
int OnCalculate(const int rates_total,      // bars available now
                const int prev_calculated,  // bars already computed last call
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long   &tick_volume[],
                const long   &volume[],
                const int    &spread[])
{
   // Only compute new/unfinished bars:
   int start = (prev_calculated == 0) ? BeginBars : prev_calculated - 1;
   for(int i = start; i < rates_total; i++)
   {
      if(i < Period) { MainBuffer[i] = 0.0; continue; }   // warm-up guard
      MainBuffer[i] = /* your formula using close[i], close[i-1], ... */ ;
   }
   return(rates_total);   // return value becomes next call's prev_calculated
}
```

**Key performance rule:** never recompute the whole history every tick. Use
`prev_calculated` to update only the newest bar(s). Returning `rates_total`
tells MT5 everything up to now is done.

By default indicator arrays here are **series-as-timeline** (index 0 = oldest).
If you prefer `[0]=current`, call `ArraySetAsSeries` on the buffers, but be
consistent — mixing conventions is the most common indicator bug.

## Drawing styles (`indicator_typeN`)

`DRAW_LINE`, `DRAW_HISTOGRAM`, `DRAW_ARROW`, `DRAW_SECTION`, `DRAW_FILLING`,
`DRAW_CANDLES`, and `DRAW_COLOR_*` variants (need a color buffer). Levels for
separate-window indicators:
```mql5
#property indicator_level1 70.0
#property indicator_level2 30.0
#property indicator_minimum 0.0
#property indicator_maximum 100.0
```

## Empty values

Where an indicator has no value (warm-up bars, gaps), set the buffer to the
plot's empty value (`PLOT_EMPTY_VALUE`, often `0.0` or `EMPTY_VALUE`) so nothing
is drawn.

## Consuming another indicator's values from an EA

```mql5
int h = iCustom(_Symbol, PERIOD_CURRENT, "MyRSI", 14 /*inputs in order*/);
double b[]; ArraySetAsSeries(b,true);
CopyBuffer(h, 0 /*buffer index*/, 0, 3, b);
```
The buffer index in `CopyBuffer` matches the `SetIndexBuffer` index in the
indicator. Document your buffer order in a comment so EA authors know which line
is which.

## Multi-timeframe indicators

To read a higher timeframe, create the source handle on that timeframe
(`iMA(_Symbol, PERIOD_H1, ...)`) and copy from it; align by `time[]` when
plotting onto the current chart.

## Common pitfalls
- Forgetting the warm-up guard → garbage/`nan` at the start of history.
- Recomputing all bars each tick → slow, laggy chart.
- Wrong `indicator_buffers`/`indicator_plots` counts → compile or draw errors.
- Series/non-series index confusion between buffers and price arrays.
