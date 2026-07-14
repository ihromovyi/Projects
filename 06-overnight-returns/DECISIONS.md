# Decision log

A short record of the choices I made and why — the point is to show reasoning,
not just results.

## Data
- **SPY, plus QQQ and IWM** rather than single stocks: maximally liquid ETFs, no
  survivorship bias (an index ETF does not disappear from the market the way a
  single company can). QQQ/IWM are an out-of-sample cross-check.
- **From 2000:** ~26 years spanning several regimes (dot-com bust, 2008, ZIRP,
  COVID, 2022), so the result is not tied to one market environment.
- **`auto_adjust=True`:** adjusts Open and Close with the same factor, so the
  overnight/intraday split is not distorted by the ex-dividend price drop (which
  lands at the open). Without this the overnight leg would be biased down.
- **Committed the raw CSVs:** reproducibility must not depend on Yahoo Finance
  staying available or unchanged. My sanity checks also caught a real Yahoo glitch
  (a date duplicated several times in one pull) — proof of why raw data is never
  trusted blindly.

## Method
- **Compounding identity as a self-test:** `(1+Night)(1+Day) = (1+Whole)` verified
  to ~1e-16. If it broke, the likeliest cause would be a missing `shift(1)`
  (look-ahead bias). A test that makes the code prove itself.
- **Log scale on cumulative charts:** equal percentage moves get equal slope, so
  early and late years are visually comparable.
- **t-test, interpreted carefully:** daily returns have fat tails and volatility
  clustering, so they violate the i.i.d. assumption — I treat p-values as
  directional. I also flag that the night-vs-day *difference* is not significant
  (p ≈ 0.17) even though it is economically large.
- **Transaction costs as the honesty check:** the overnight leg looks great until
  you count ~500 trades/year. Charging `2 × cost` per day shows it turns negative
  around 2 bps/trade. This reframes the result from "strategy" to "analytical
  fact". Buy-and-hold is excluded from the cost sweep because it barely trades.
- **Slices instead of parameter optimization:** there are no parameters to
  optimize (a virtue), so robustness = slicing the data — by weekday, and across
  three ETFs. The effect survives.

## Scope
- Kept it deliberately small and finished rather than large and half-done.
- I also tested a weekend-only version of my own (hold Friday→Monday) to try to
  cut the trade count; the "sleeping market pays more" intuition did **not** hold,
  so I replaced it with the cleaner weekday breakdown. An honest null result is
  still a result.
