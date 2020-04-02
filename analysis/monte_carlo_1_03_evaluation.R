rm(list = ls())

library(pacman)
p_load(dplyr, tibble)

fun <- function(p) {
  sig <- c(seq(0, 0.1, 0.001), seq(0.11, 1, 0.01))
  rr <- sapply(sig, function(sig) mean(p <= sig, na.rm = TRUE))
  data.frame(sig_lev = sig, rej_rate = rr)
}

path <- 'data/monte_carlo_1_results/'

file_list <- list.files(path, full.names = TRUE)
file_list <- file_list[file.size(file_list) > 0]
df_list <- lapply(file_list, readRDS)
df_list <- df_list[sapply(df_list, tibble::is_tibble)]
df <- do.call('rbind', df_list)
df <- df %>% mutate(one_sided = grepl('onesided', backtest))

rejection_rates <- df %>% 
  group_by(design, null_model, sample_size, model, backtest, one_sided) %>% 
  do(fun(.$pvalue)) %>% 
  ungroup()

path <- '../plots/in/monte_carlo_1/'
write.csv(rejection_rates, paste0(path, 'rejection_rates.csv'), row.names = FALSE)

