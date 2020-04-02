rm(list = ls())
source("functions.R")

library(pacman)
p_load(reshape2, rugarch, foreach)

# Simulation settings
tau0 <- 0.025

# Define the true model
spec0 <- ugarchspec(mean.model=list(armaOrder=c(0,0), include.mean=FALSE), 
                    variance.model=list(model="sGARCH"), 
                    distribution.model="std")
omega  <- 0.01
alpha1 <- 0.1
beta1  <- 0.85
shape  <- 5
setfixed(spec0) <- list(omega=omega, alpha1=alpha1, beta1=beta1, shape=shape)

# Define the alternatives
all_alpha1 <- seq(0.01, 0.2, 0.01)
all_unc_var <- c(0.01, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5)
all_pers <- seq(0.9, 1, 0.01)
all_shape <- c(3:10, 12, 15, 20, 30, 50, 10^6)
all_tau <- seq(0.005, 0.05, 0.005)

par_grid <- data.frame(rbind(
  # Dynamics misspecified: unconditional variance + persistence constant
  cbind(
    set    = 1,
    tau    = tau0,
    omega  = omega,
    alpha1 = all_alpha1,
    beta1  = persistence(spec0) - all_alpha1,
    shape  = shape
  ),
  # Dynamics misspecified: persistent constant
  cbind(
    set    = 2,
    tau    = tau0,    
    omega  = all_unc_var * (1 - persistence(spec0)),
    alpha1 = alpha1,
    beta1  = beta1,
    shape  = shape
  ),
  # Dynamics misspecified: unconditional variance constant
  cbind(
    set    = 3,
    tau    = tau0,    
    omega  = uncvariance(spec0) * (1 - all_pers),
    alpha1 = alpha1 / persistence(spec0) * all_pers,
    beta1  = beta1 / persistence(spec0) * all_pers,
    shape  = shape
  ),
  cbind(
    set    = 4,
    tau    = tau0,    
    omega  = omega,
    alpha1 = alpha1,
    beta1  = beta1,
    shape  = all_shape
  ),
  cbind(
    set    = 5,
    tau    = all_tau,    
    omega  = omega,
    alpha1 = alpha1,
    beta1  = beta1,
    shape  = shape
  )
))

# Simulate from the true model
n <- 500
r <- as.numeric(fitted(ugarchpath(spec0, n + 250, n.start=100, rseed=1)))

# Evaluate the alternatives
out <- foreach(i = 1:nrow(par_grid)) %do% {
  par <- par_grid[i,]
  spec <- spec0
  setfixed(spec) <- as.list(par[-c(1,2)])
  df <- get_risk_quantities(spec = spec, r = r, alpha=par$tau)
  df$qz <- (df$q - df$mu) / df$s
  df$ez <- (df$e - df$mu) / df$s
  
  df
}

df <- rbind(
  cbind(type="r", melt(cbind(par_grid, t(sapply(out, "[[", "r"))), colnames(par_grid))),
  cbind(type="q", melt(cbind(par_grid, t(sapply(out, "[[", "q"))), colnames(par_grid))),
  cbind(type="e", melt(cbind(par_grid, t(sapply(out, "[[", "e"))), colnames(par_grid))),
  cbind(type="s", melt(cbind(par_grid, t(sapply(out, "[[", "s"))), colnames(par_grid))),
  cbind(type="qz", melt(cbind(par_grid, t(sapply(out, "[[", "qz"))), colnames(par_grid))),
  cbind(type="ez", melt(cbind(par_grid, t(sapply(out, "[[", "ez"))), colnames(par_grid)))
)
df["unc_var"] <- df$omega / (1- df$alpha1 - df$beta1)
df["persistence"] <- df$alpha1 + df$beta1

file <- '../plots/in/monte_carlo_2/illustration_series'
write.csv(df, file, row.names = FALSE)
