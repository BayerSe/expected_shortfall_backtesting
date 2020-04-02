rm(list = ls())

library(pacman)
p_load(rugarch, xts, dplyr, esreg)

source("functions.R")


# Functions ---------------------------------------------------------------

get_spec <- function(phi) {
  ugarchspec(
    mean.model=list(armaOrder=c(1, 0), include.mean=TRUE),
    variance.model=list(model="sGARCH"),
    distribution.model="norm",
    fixed.pars=list(mu=0, ar1=phi,
                    omega=0.01, alpha1=0.1, beta1=0.85))
} 

get_c_factor <- function(phi, n, alpha, seed) {
  spec <- get_spec(phi)
  
  # Simulate from the true DGP
  sim_process <- get_simulated_series(spec = spec, n = n, seed = seed)
  sim <- sim_process$sim
  r <- sim_process$sim_series
  
  # Get risk quantities for the true DGP
  df <- get_risk_quantities(spec = spec, r = r, sim = sim, alpha=alpha)
  
  # Return c
  df$e / df$q
}

run_sim <- function(phi, n, alpha, seed) {
  spec <- get_spec(phi)
  
  # Simulate from the true DGP
  sim_process <- get_simulated_series(spec = spec, n = n, seed = seed)
  sim <- sim_process$sim
  r <- sim_process$sim_series
  
  # Get risk quantities for the true DGP
  df <- get_risk_quantities(spec = spec, r = r, sim = sim, alpha=alpha)
  
  # Auxiliary
  fit_aux <- esreg(df$r ~ df$q | df$e, alpha = alpha)
  cov0_aux <- vcov(fit_aux)
  s_aux <- (fit_aux$coefficients_e - c(0, 1))
  T_aux <- as.numeric(s_aux %*% solve(cov0_aux[3:4, 3:4]) %*% s_aux)
  
  # Strict
  fit_str <- esreg(df$r ~ df$e, alpha = alpha)
  cov_str <- vcov(fit_str)
  s_str <- (fit_str$coefficients_e - c(0, 1))
  T_str <- as.numeric(s_str %*% solve(cov_str[3:4, 3:4]) %*% s_str)
  
  # Return results
  parameter_estimates <- dplyr::tibble(
    seed = seed, phi = phi, sample_size = n, 
    model = rep(c('Auxiliary', 'Strict'), each = 4),
    equation = rep(c('Q', 'Q', 'ES', 'ES'), 2),
    parameter = rep(c('Intercept', 'Slope'), 4),
    value = c(fit_aux$coefficients, fit_str$coefficients)
  )
  test_statistics <- dplyr::tibble(
    seed = seed, phi = phi, sample_size = n,
    model = c('Auxiliary', 'Strict'),
    value = c(T_aux, T_str)
  )
  
  list(
    parameter_estimates = parameter_estimates, 
    test_statistics = test_statistics
  )
}


# Settings ----------------------------------------------------------------

n <- 1000
alpha <- 0.025
mc <- 1000
phis <- c(0, 0.1, 0.5)


# Simulation --------------------------------------------------------------

parameter_estimates <- tibble()
test_statistics <- tibble()

for (phi in phis) {
  results <- mclapply(
    X = seq_len(mc), 
    FUN = function(seed) run_sim(phi, n, alpha, seed), 
    mc.cores = 4
  )
  parameter_estimates <- rbind(parameter_estimates, do.call('rbind', sapply(results, '[', 1)))
  test_statistics <- rbind(test_statistics, do.call('rbind', sapply(results, '[', 2)))
}

c_factors <- sapply(phis, function(phi) get_c_factor(phi, n, alpha, seed=1))
colnames(c_factors) <- phis


path <- '../plots/in/monte_carlo_check_approximations/'

write.csv(parameter_estimates, paste0(path, 'parameter_estimates.csv'), row.names = FALSE)
write.csv(test_statistics, paste0(path, 'test_statistics.csv'), row.names = FALSE)
write.csv(c_factors, paste0(path, 'c-factor.csv'), row.names = FALSE)
