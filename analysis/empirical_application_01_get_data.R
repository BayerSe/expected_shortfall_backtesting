rm(list = ls())
library(pacman)
p_load(BatchGetSymbols, dplyr, tibble)

first.date <- '2001-01-01'
last.date <- '2019-08-31'
df.SP500 <- BatchGetSymbols::GetSP500Stocks()
tickers <- df.SP500$Tickers

future::plan(future::multisession, workers = floor(parallel::detectCores()/2))
df <- BatchGetSymbols::BatchGetSymbols(
  tickers = tickers, 
  first.date = first.date,
  last.date = last.date, 
  type.return = 'log',
  do.parallel = TRUE
)
tickers_all_available <- df$df.control$ticker[df$df.control$perc.benchmark.dates == 1]

meta_data <- quantmod::getQuote(tickers, what = c('symbol', 'shortName', 'marketCap'))

sorted_tickers <- meta_data %>% 
  dplyr::as_tibble() %>% 
  dplyr::filter(symbol %in% tickers_all_available) %>% 
  arrange(desc(marketCap)) %>% 
  dplyr::pull(symbol)

returns <- df$df.tickers %>% 
  dplyr::as_tibble() %>% 
  dplyr::filter(ticker %in% sorted_tickers) %>% 
  dplyr::select(c(ticker, ref.date, ret.adjusted.prices)) %>% 
  dplyr::rename(symbol = ticker, date = ref.date, return = ret.adjusted.prices)

saveRDS(sorted_tickers, 'data/empirical_application/sorted_tickers.rds')
saveRDS(returns, 'data/empirical_application/returns.rds')
