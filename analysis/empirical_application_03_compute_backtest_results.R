rm(list = ls())
library(pacman)
p_load(dplyr, parallel, xts, doParallel)

path <- 'data/empirical_application/results/'
files <- list.files(path, full.names = TRUE)
files <- files[file.size(files) > 0]


get_results <- function(f) {
  x <- readRDS(f)
  from <- '2010/'
  ts <- x$forc[from]
  
  loss <- esreg::esr_loss(r = ts$r, q = ts$q, e = ts$e, alpha = x$settings$alpha)
  
  int_bt <- esback::esr_backtest(
    r = x$forc$r, q = x$forc$q, e = x$forc$e, alpha = x$settings$alpha, 
    version = 3
  )
  
  pval_int_1s <- int_bt$pvalue_onesided_asymptotic
  pval_int_2s <- int_bt$pvalue_twosided_asymptotic
  
  out <- x$settings
  out['loss'] <- loss
  out['pval'] <- pval_int_1s
  
  tibble::as_tibble(out)
}

registerDoParallel(cores = 8)
data_list <- foreach(f = files, .errorhandling = 'pass') %dopar% get_results(f)

data <- do.call('rbind', data_list[sapply(data_list, length) == 9])
saveRDS(data, 'data/empirical_application/empirical_application_results.rds')
