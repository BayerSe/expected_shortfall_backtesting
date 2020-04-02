rm(list = ls())
library(pacman)
p_load(reshape2, dplyr)

# Load the results
path <- 'data/monte_carlo_2_results/'
file_list <- list.files(path, full.names = TRUE)
file_list <- file_list[file.size(file_list) > 0]
df_list <- lapply(file_list, readRDS)
df_list <- df_list[sapply(df_list, function(x) all(is.numeric(x[,1])))]

df <- tibble::as_tibble(do.call('rbind', df_list))
df <- df[,!apply(is.na(df), 2, all)]

mc <- length(unique(df$seed))

idx_true <- 10

roc <- function(p0, p1, a=NULL) {
  sig <- c(seq(0, 0.1, 0.001), seq(0.11, 1, 0.01))
  r0 <- sapply(sig, function(sig) mean(p0 <= sig))
  r1 <- sapply(sig, function(sig) mean(p1 <= sig))
  
  if (is.null(a)) {
    approxfun(x=r0, y=r1, ylef=0, yright=1)
  } else {
    approx(x=r0, y=r1, ylef=0, yright=1, xout=a)$y
  }
}

row_names <- sort(unique(df$model_index))
col_names <- colnames(df)[9:ncol(df)]
rr <- matrix(NA, length(row_names), length(col_names), dimnames=list(row_names, col_names))
rr_raw <- matrix(NA, length(row_names), length(col_names), dimnames=list(row_names, col_names))

for (col in col_names) {
  for (row in row_names) {
    print(paste0(col, " - ", row))
    p0 <- df[df$model_index == idx_true, col] %>% pull()
    p1 <- df[df$model_index == row, col] %>% pull()
    full_idx <- !(is.na(p0) | is.na(p1))
    p0 <- p0[full_idx]
    p1 <- p1[full_idx]
    rr[row, col] <- roc(p0, p1, 0.05) 
    rr_raw[row, col] <- mean(p1 <= 0.05)
  }
}

# Adjusted
out <- cbind(df[df$seed == 1, 2:8], rr)
out["unc_var"] <- out$omega / (1 - out$alpha1 - out$beta1)
out["persistence"] <- out$alpha1 + out$beta1
out["tau"] <- out["tau"] * 100
out <- melt(out, c("model_index", "set", "tau", "omega", "alpha1", "beta1",
                   "shape", "unc_var", "persistence"), variable.name='backtest')
out <- out %>% mutate(one_sided = grepl('onesided', backtest))


path <- '../plots/in/monte_carlo_2/'
write.csv(out, paste0(path, 'rejection_rates.csv'), row.names = FALSE)

# Raw
out <- cbind(df[df$seed == 1, 2:8], rr_raw)
out["unc_var"] <- out$omega / (1 - out$alpha1 - out$beta1)
out["persistence"] <- out$alpha1 + out$beta1
out["tau"] <- out["tau"] * 100
out <- melt(out, c("model_index", "set", "tau", "omega", "alpha1", "beta1",
                   "shape", "unc_var", "persistence"), variable.name='backtest')
out <- out %>% mutate(one_sided = grepl('onesided', backtest))

write.csv(out, paste0(path, 'raw_rejection_rates.csv'), row.names = FALSE)
