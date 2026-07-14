import yfinance as yf
import pandas as pd

# SPY is the main ticker; QQQ and IWM are used to cross-check the effect on other ETFs.
TICKERS = ["SPY", "QQQ", "IWM"]

for ticker in TICKERS:
    df = yf.download(ticker, start="2000-01-01", auto_adjust=True, progress=False)

    if isinstance(df.columns, pd.MultiIndex):
        df.columns = df.columns.get_level_values(0)

    print(f"\n=== {ticker} ===")
    print("Rows:", len(df))
    print("Date range:", df.index.min().date(), "->", df.index.max().date())
    print("Missing values (NaN) per column:",
          df.isna().sum().to_string())
    print("Days with zero/negative price:",
          int((df[["Open", "High", "Low", "Close"]] <= 0).any(axis=1).sum()))
    print("Duplicate dates:", int(df.index.duplicated().sum()))

    daily_ret = df["Close"].pct_change()
    print("5 worst days:",
          daily_ret.nsmallest(5).to_string())
    print("5 best days:",
          daily_ret.nlargest(5).to_string())

    path = f"data/{ticker.lower()}_raw.csv"
    df.to_csv(path)
    print("Saved to", path)
