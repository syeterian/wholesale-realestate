//+------------------------------------------------------------------+
//|                                           indicator_template.mq5  |
//|   Starter custom indicator skeleton for MetaTrader 5.            |
//|   Demo: EMA + upper/lower ATR bands (a simple volatility channel),|
//|   drawn in the chart window. Replace with your own formula.       |
//+------------------------------------------------------------------+
#property copyright "your name"
#property version   "1.00"
#property strict

#property indicator_chart_window
#property indicator_buffers 4          // 3 plotted + 1 calc
#property indicator_plots   3

//--- plot 0: mid EMA
#property indicator_label1  "Mid EMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGold
#property indicator_width1  2
//--- plot 1: upper band
#property indicator_label2  "Upper"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_DOT
//--- plot 2: lower band
#property indicator_label3  "Lower"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDodgerBlue
#property indicator_style3  STYLE_DOT

//--- inputs
input int    InpEMAPeriod = 50;    // EMA period
input int    InpATRPeriod = 14;    // ATR period
input double InpATRMult    = 2.0;  // Band width (× ATR)

//--- buffers
double MidBuf[];    // plot 0
double UpBuf[];     // plot 1
double LoBuf[];     // plot 2
double AtrBuf[];    // calc only

//--- source handles
int hEMA, hATR;

//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, MidBuf, INDICATOR_DATA);
   SetIndexBuffer(1, UpBuf,  INDICATOR_DATA);
   SetIndexBuffer(2, LoBuf,  INDICATOR_DATA);
   SetIndexBuffer(3, AtrBuf, INDICATOR_CALCULATIONS);

   IndicatorSetString(INDICATOR_SHORTNAME,
      StringFormat("ATR Channel(%d,%d,%.1f)", InpEMAPeriod, InpATRPeriod, InpATRMult));
   IndicatorSetInteger(INDICATOR_DIGITS, (int)_Digits);

   hEMA = iMA (_Symbol, PERIOD_CURRENT, InpEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   hATR = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
   if(hEMA == INVALID_HANDLE || hATR == INVALID_HANDLE)
      return(INIT_FAILED);

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(hEMA);
   IndicatorRelease(hATR);
}
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long   &tick_volume[],
                const long   &volume[],
                const int    &spread[])
{
   int need = MathMax(InpEMAPeriod, InpATRPeriod);
   if(rates_total < need) return(0);

   // Copy source-indicator values aligned to this buffer's indexing.
   // (Default: index 0 = oldest, same as price arrays here.)
   if(CopyBuffer(hEMA, 0, 0, rates_total, MidBuf) <= 0) return(prev_calculated);
   if(CopyBuffer(hATR, 0, 0, rates_total, AtrBuf) <= 0) return(prev_calculated);

   int start = (prev_calculated > 1) ? prev_calculated - 1 : need;
   for(int i = start; i < rates_total; i++)
   {
      double band = InpATRMult * AtrBuf[i];
      UpBuf[i] = MidBuf[i] + band;
      LoBuf[i] = MidBuf[i] - band;
   }
   return(rates_total);
}
//+------------------------------------------------------------------+
