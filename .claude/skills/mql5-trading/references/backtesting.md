# Backtesting & Optimization (Strategy Tester)

How to test an EA in MetaTrader 5 and, crucially, how to avoid fooling yourself.
Gold data quality matters more than most instruments because of spikes and
variable spread.

## Compile first
1. Open the `.mq5` in **MetaEditor**.
2. Press **F7** (Compile). Fix errors/warnings — treat warnings as errors for
   trading code.
3. The compiled `.ex5` appears under the same folder; the EA shows up in the
   MT5 Navigator under Expert Advisors.

## Running a backtest
1. In MT5: **View → Strategy Tester** (Ctrl+R).
2. Select the EA, the **symbol** (the exact gold symbol your broker uses), and
   the **timeframe** your EA trades.
3. **Date range**: test across varied regimes — trending, ranging, and at least
   one high-volatility news period.
4. **Modelling**: prefer **"Every tick based on real ticks"** if the broker
   provides real tick data; otherwise "Every tick." Avoid "Open prices only"
   except for a rough sanity pass.
5. **Deposit / leverage / currency**: match what you'll trade live.
6. Set **inputs**, then **Start**.

## Spread setting (gold-critical)
- The tester's **Spread** field: "Current" uses live spread; a fixed value lets
  you stress-test. Gold's real spread is variable and widens on news — test with
  a **realistic-to-pessimistic** fixed spread, not the tightest.
- If your edge disappears under a slightly wider spread, it isn't robust.

## Reading results
- **Net profit** alone means little. Look at:
  - **Profit factor** (>1.3 is a start; be skeptical of >3 on few trades).
  - **Max drawdown %** — can you stomach it? Gold DDs are large.
  - **Expected payoff**, **Sharpe**, **recovery factor**.
  - **Number of trades** — <100 is statistically weak.
  - Equity curve shape — smooth vs one lucky trade.

## Optimization (and its dangers)
- Strategy Tester → **Optimization**: sweep input ranges (genetic algo for large
  spaces). Use **forward optimization** (tester's forward period) to hold out
  data.
- **Overfitting is the default outcome.** Guard against it:
  - Optimize on one period, **validate on unseen data** (forward/out-of-sample).
  - Prefer **broad plateaus** of good parameters over sharp single-point peaks.
  - Keep few parameters; each added input multiplies overfit risk.
  - Sanity-check that the "best" params make trading sense.

## Beyond the tester
1. **Forward test on a demo account** for weeks — real spread, real slippage,
   real news, real gold rollover behavior.
2. Start live at **minimum lot** and scale only after live results match
   expectations.
3. Watch for tester-vs-live divergence: fill modes, requotes, and gold's spread
   spikes commonly erase paper edges.

## Debugging in the tester
- Add `Print`/`PrintFormat` logs; view them in the tester's **Journal**.
- Use **Visual mode** to watch trades on the chart and confirm entries/exits
  fire where you expect (check you're using closed bars, not repainting).
- MetaEditor supports **debugging on history** (F5) with breakpoints for logic
  bugs.

## Checklist before calling an EA "done"
- [ ] Compiles with no warnings.
- [ ] Sized from % risk; SL always set; volume & stops normalized.
- [ ] Spread guard + session filter present (gold).
- [ ] Backtested on real ticks across multiple regimes incl. news.
- [ ] Validated out-of-sample / forward, not just optimized.
- [ ] Demo forward-tested.
- [ ] User warned: past performance ≠ future results; start at min lot.
