//+------------------------------------------------------------------+
//|                                                  ea_template.mq5  |
//|   Starter Expert Advisor skeleton for MetaTrader 5 (XAUUSD-ready)|
//|   Strategy shown: EMA cross + RSI filter, ATR-based SL/TP,        |
//|   %-risk position sizing, spread guard, once-per-bar entries.     |
//|   Replace the signal/exit logic with your own.                    |
//+------------------------------------------------------------------+
#property copyright "your name"
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>
CTrade trade;

//--- inputs -------------------------------------------------------------------
input string InpSymbol          = "XAUUSD";  // Symbol (broker gold name)
input long   InpMagic           = 990045;    // Magic number (EA id)
input double InpRiskPercent     = 1.0;       // Risk per trade (% of balance)
input int    InpFastEMA         = 21;        // Fast EMA period
input int    InpSlowEMA         = 50;        // Slow EMA period
input int    InpRSIPeriod       = 14;        // RSI period
input int    InpATRPeriod       = 14;        // ATR period (SL/TP sizing)
input double InpATRMultSL        = 1.8;      // SL = entry ∓ mult * ATR
input double InpTPtoSL           = 2.0;      // TP distance = mult * SL distance
input int    InpMaxSpreadPoints = 50;        // Skip entry if spread above this
input int    InpTrailPoints     = 0;         // Trailing stop (points, 0 = off)
input int    InpDeviationPoints = 50;        // Slippage tolerance
input int    InpStartHour       = 7;         // Trade window start (server hour)
input int    InpEndHour         = 21;        // Trade window end   (server hour)

//--- globals ------------------------------------------------------------------
string   gSym;
int      hFast, hSlow, hRSI, hATR;
datetime gLastBar = 0;
double   gPoint;
int      gDigits;

//+------------------------------------------------------------------+
int OnInit()
{
   gSym = InpSymbol;
   if(!SymbolSelect(gSym, true))
   { PrintFormat("Symbol %s not found", gSym); return(INIT_PARAMETERS_INCORRECT); }

   if(InpFastEMA <= 0 || InpSlowEMA <= 0 || InpFastEMA >= InpSlowEMA ||
      InpRiskPercent <= 0 || InpRiskPercent > 10)
      return(INIT_PARAMETERS_INCORRECT);

   gPoint  = SymbolInfoDouble(gSym, SYMBOL_POINT);
   gDigits = (int)SymbolInfoInteger(gSym, SYMBOL_DIGITS);

   hFast = iMA (gSym, PERIOD_CURRENT, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   hSlow = iMA (gSym, PERIOD_CURRENT, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   hRSI  = iRSI(gSym, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
   hATR  = iATR(gSym, PERIOD_CURRENT, InpATRPeriod);
   if(hFast==INVALID_HANDLE || hSlow==INVALID_HANDLE ||
      hRSI==INVALID_HANDLE  || hATR==INVALID_HANDLE)
      return(INIT_FAILED);

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(gSym);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(hFast); IndicatorRelease(hSlow);
   IndicatorRelease(hRSI);  IndicatorRelease(hATR);
}
//+------------------------------------------------------------------+
void OnTick()
{
   ManagePosition();                 // trailing/break-even on every tick
   if(!IsNewBar())        return;     // entries only at bar close
   if(!InTradeWindow())   return;
   if(SpreadPoints() > InpMaxSpreadPoints) return;
   if(HasPosition())      return;     // one position per symbol/magic

   int sig = GetSignal();
   if(sig == 0) return;

   double atr[]; ArraySetAsSeries(atr,true);
   if(CopyBuffer(hATR,0,0,2,atr) < 2 || atr[1] <= 0) return;

   double ask = SymbolInfoDouble(gSym, SYMBOL_ASK);
   double bid = SymbolInfoDouble(gSym, SYMBOL_BID);
   double slDist = InpATRMultSL * atr[1];
   double tpDist = InpTPtoSL   * slDist;

   double entry, sl, tp;
   if(sig > 0) { entry=ask; sl=entry-slDist; tp=entry+tpDist; }
   else        { entry=bid; sl=entry+slDist; tp=entry-tpDist; }

   sl = EnforceStop(sl, sig>0);
   tp = NormPrice(tp);

   double lots = CalcLots(MathAbs(entry - sl));
   if(lots <= 0) { Print("Lot size 0 — skipping"); return; }

   bool ok = (sig>0) ? trade.Buy (lots, gSym, 0.0, sl, tp, "EA")
                     : trade.Sell(lots, gSym, 0.0, sl, tp, "EA");
   if(!ok)
      PrintFormat("Order failed: %d %s", trade.ResultRetcode(),
                  trade.ResultRetcodeDescription());
}
//+------------------------------------------------------------------+
//| Signal: +1 long, -1 short, 0 none (uses closed bars [1],[2])     |
//+------------------------------------------------------------------+
int GetSignal()
{
   double f[],s[],r[];
   ArraySetAsSeries(f,true); ArraySetAsSeries(s,true); ArraySetAsSeries(r,true);
   if(CopyBuffer(hFast,0,0,3,f) < 3) return 0;
   if(CopyBuffer(hSlow,0,0,3,s) < 3) return 0;
   if(CopyBuffer(hRSI ,0,0,3,r) < 3) return 0;

   bool up   = f[2] <= s[2] && f[1] > s[1];
   bool down = f[2] >= s[2] && f[1] < s[1];
   if(up   && r[1] > 50.0) return  1;
   if(down && r[1] < 50.0) return -1;
   return 0;
}
//+------------------------------------------------------------------+
void ManagePosition()
{
   if(InpTrailPoints <= 0) return;
   if(!PositionSelect(gSym)) return;
   if(PositionGetInteger(POSITION_MAGIC) != InpMagic) return;

   long   type = PositionGetInteger(POSITION_TYPE);
   double sl   = PositionGetDouble(POSITION_SL);
   double tp   = PositionGetDouble(POSITION_TP);
   double open = PositionGetDouble(POSITION_PRICE_OPEN);
   double trail= InpTrailPoints * gPoint;

   if(type == POSITION_TYPE_BUY)
   {
      double newSL = SymbolInfoDouble(gSym,SYMBOL_BID) - trail;
      if(newSL > open && (sl==0 || newSL > sl))
         trade.PositionModify(gSym, NormPrice(newSL), tp);
   }
   else if(type == POSITION_TYPE_SELL)
   {
      double newSL = SymbolInfoDouble(gSym,SYMBOL_ASK) + trail;
      if(newSL < open && (sl==0 || newSL < sl))
         trade.PositionModify(gSym, NormPrice(newSL), tp);
   }
}
//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+
bool HasPosition()
{
   if(!PositionSelect(gSym)) return false;
   return (PositionGetInteger(POSITION_MAGIC) == InpMagic);
}

bool IsNewBar()
{
   datetime t = iTime(gSym, PERIOD_CURRENT, 0);
   if(t != gLastBar) { gLastBar = t; return true; }
   return false;
}

bool InTradeWindow()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   if(InpStartHour <= InpEndHour)
      return (dt.hour >= InpStartHour && dt.hour < InpEndHour);
   return (dt.hour >= InpStartHour || dt.hour < InpEndHour); // wraps midnight
}

double SpreadPoints()
{
   double ask = SymbolInfoDouble(gSym, SYMBOL_ASK);
   double bid = SymbolInfoDouble(gSym, SYMBOL_BID);
   return (gPoint>0) ? (ask-bid)/gPoint : 0.0;
}

double NormPrice(double p) { return NormalizeDouble(p, gDigits); }

double EnforceStop(double price, bool forBuy)
{
   long   stopLvl = SymbolInfoInteger(gSym, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist = (stopLvl + 1) * gPoint;
   double bid = SymbolInfoDouble(gSym, SYMBOL_BID);
   double ask = SymbolInfoDouble(gSym, SYMBOL_ASK);
   if(forBuy)  { if(bid - price < minDist) price = bid - minDist; }
   else        { if(price - ask < minDist) price = ask + minDist; }
   return NormPrice(price);
}

double ValuePerPoint()
{
   double tv = SymbolInfoDouble(gSym, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(gSym, SYMBOL_TRADE_TICK_SIZE);
   if(ts <= 0) return 0.0;
   return tv * (gPoint / ts);
}

double NormVolume(double lots)
{
   double vMin  = SymbolInfoDouble(gSym, SYMBOL_VOLUME_MIN);
   double vMax  = SymbolInfoDouble(gSym, SYMBOL_VOLUME_MAX);
   double vStep = SymbolInfoDouble(gSym, SYMBOL_VOLUME_STEP);
   if(vStep <= 0) vStep = 0.01;
   lots = MathFloor(lots / vStep) * vStep;
   lots = MathMax(vMin, MathMin(vMax, lots));
   int d = (int)MathMax(0, MathCeil(-MathLog10(vStep)));
   return NormalizeDouble(lots, d);
}

// slPriceDist = |entry - SL| in price terms
double CalcLots(double slPriceDist)
{
   if(slPriceDist <= 0) return 0.0;
   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0;
   double vpp = ValuePerPoint();
   if(vpp <= 0 || gPoint <= 0) return 0.0;
   double slPoints   = slPriceDist / gPoint;
   double lossPerLot = slPoints * vpp;
   if(lossPerLot <= 0) return 0.0;
   return NormVolume(riskMoney / lossPerLot);
}
//+------------------------------------------------------------------+
