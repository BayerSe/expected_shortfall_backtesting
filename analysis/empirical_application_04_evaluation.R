rm(list = ls())
library(pacman)
p_load(dplyr, xtable)

file <- 'data/empirical_application/empirical_application_results.rds'
data <- readRDS(file)

get_matrix <- function(mod, dist, size = 0.05) {
  res <- data %>%
    filter(variance.model == mod) %>% 
    filter(distribution.model == dist) %>% 
    group_by(distribution.model, last_x, win, refit, alpha) %>% 
    summarise(pval = mean(pval <= size)) %>% 
    tidyr::spread(refit, pval) %>% 
    ungroup() %>%
    select(-c(distribution.model, last_x, alpha)) %>%  
    tibble::column_to_rownames('win')
  res
}

x1 <- get_matrix('sGARCH', 'norm')
x2 <- get_matrix('gjrGARCH', 'norm')
x3 <- get_matrix('sGARCH', 'std')
x4 <- get_matrix('gjrGARCH', 'std')

tab1 <- cbind(x1, NA, x2)
tab2 <- cbind(x3, NA, x4)

xtab1 <- xtable(tab1)
xtab2 <- xtable(tab2)

path <- '../plots/out/results_application/'
file1 <- paste0(path, 'tab1.tex')
file2 <- paste0(path, 'tab2.tex')

print(xtab1, file = file1,
      booktabs = TRUE, comment = FALSE, only.contents = TRUE, hline.after = NULL, include.colnames = FALSE)
print(xtab2, file = file2,
      booktabs = TRUE, comment = FALSE, only.contents = TRUE, hline.after = NULL, include.colnames = FALSE)

