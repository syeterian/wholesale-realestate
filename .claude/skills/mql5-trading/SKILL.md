---
name: mql5-trading
description: >
  Build, debug, and optimize MetaTrader 5 (MQL5) Expert Advisors and custom
  indicators, with a focus on trading XAUUSD (gold). Use this skill WHENEVER the
  user mentions MetaTrader, MT5, MQL5, .mq5/.mqh/.ex5 files, Expert Advisors
  (EAs), trading bots, custom indicators, backtesting in the Strategy Tester, or
  writing/converting any automated trading logic — even if they don't say
  "MQL5" explicitly. Also trigger for gold/XAUUSD trading strategies, position
  sizing, stop-loss/take-profit logic, or MT4→MT5 conversions.
---

# MQL5 Trading — Expert Advisors & Indicators (XAUUSD focus)

Author production-quality MetaTrader 5 code: Expert Advisors (automated
strategies) and custom indicators, tuned for the realities of trading gold
(XAUUSD). This skill encodes correct MQL5 idioms, gold-specific pitfalls, and a
safety-first approach to live money.

## Golden rules (read every time)

1. **Never ship a "market order at OnTick" bot without risk controls.** Every EA
   must compute lot size from account risk %, set a stop loss, and respect
   min/max/step volume. See `references/risk-management.md`.
2. **XAUUSD is not a forex pair.** Point/pip value, contract size, spread, and
   volatility differ from EURUSD. Never hardcode `0.0001` or assume 5-digit
   pricing. Always read symbol properties at runtime. See `references/xauusd.md`.
3. **MQL5 ≠ MQL4.** In MT5, indicators return *handles* (create once in
   `OnInit`, read with `CopyBuffer`), trading goes through the `CTrade` class,
   and positions are managed (not orders like MT4). See
   `references/mql5-language.md`.
4. **State the assumptions, warn on the risks.** This code moves real money.
   When you deliver an EA, tell the user exactly what it does, its assumptions
   (broker symbol name, hedging vs netting, timeframe), and that it must be
   backtested and demo-tested before live use. You write tools; you do not give
   financial advice or promise profits.

## Workflow

Follow these steps. Read the referenced files *as you reach the relevant step* —
don't preload everything.

### 1. Clarify the spec
Pin down before writing code:
- **EA or indicator?** (Or an indicator consumed by an EA.)
- **Strategy logic**: entry, exit, filters (which indicators, thresholds).
- **Timeframe(s)** and whether it trades every tick or once per bar.
- **Risk model**: fixed lots vs % risk, SL/TP method (fixed points, ATR, swing).
- **Symbol name**: brokers name gold differently (`XAUUSD`, `XAUUSD.m`,
  `GOLD`, `XAUUSD_i`). Make it an input, default `XAUUSD`.
- **Account type**: hedging or netting (affects position handling).

If the user is vague, propose a sensible default strategy and confirm, rather
than stalling.

### 2. Choose the artifact and read its reference
- **Expert Advisor** → read `references/expert-advisors.md`, start from
  `assets/ea_template.mq5`.
- **Custom indicator** → read `references/indicators.md`, start from
  `assets/indicator_template.mq5`.
- Any MQL5 syntax/API question → `references/mql5-language.md`.

### 3. Write the code
- Start from the matching template in `assets/` — it already has the correct
  `#property` headers, input block, handle lifecycle, and error handling.
- Bake in the gold-specific handling from `references/xauusd.md` and the sizing
  helpers from `references/risk-management.md`.
- Save EAs and indicators as `.mq5`; shared code as `.mqh`.

### 4. Explain how to build & test
The user compiles in **MetaEditor** (F7) and runs in the **Strategy Tester**.
Walk them through it and flag gold-specific test settings (spread, modelling
quality, tick data). See `references/backtesting.md`.

### 5. Deliver responsibly
Summarize what the EA does, list its inputs, restate assumptions, and remind the
user to backtest + forward-test on demo before any live account.

## File map

| File | When to read it |
|------|-----------------|
| `references/mql5-language.md` | MQL5 syntax, events, indicator handles, `CTrade`, common APIs, MT4→MT5 gotchas |
| `references/expert-advisors.md` | EA anatomy, `OnTick`, order flow, trailing stops, once-per-bar logic |
| `references/indicators.md` | Custom indicator anatomy, buffers, `OnCalculate`, plotting |
| `references/xauusd.md` | Gold specifics: point/pip value, spreads, sessions, news, volatility |
| `references/risk-management.md` | Position sizing, SL/TP, normalization, broker constraints |
| `references/backtesting.md` | Strategy Tester setup, optimization, avoiding overfitting |
| `assets/ea_template.mq5` | Starting skeleton for any EA |
| `assets/indicator_template.mq5` | Starting skeleton for any custom indicator |

## Non-negotiable disclaimers to pass on to the user
- Trading leveraged instruments (especially gold) can lose more than deposited.
- Backtest results do not guarantee future performance.
- Always demo-test. Start live with minimum lot size.
- This skill produces software, not investment advice.
