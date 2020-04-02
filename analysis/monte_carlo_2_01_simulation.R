rm(list = ls())

library(pacman)
p_load(esreg, esback, rugarch, foreach, doParallel)
source('functions.R')

# Start the pool
nodename <- Sys.info()["nodename"]
if (grepl("uc1", nodename)) {
  registerDoParallel(cores=as.numeric(Sys.getenv("SLURM_NPROCS"))) 
} else {
  registerDoSEQ() 
}

path <- "data/monte_carlo_2_results/"
if (!(dir.exists(path))) {
  dir.create(path)
}

# Simulation settings
n <- 2500
tau0 <- 0.025
mc <- 10000
save_frequency <- 10
B <- 0

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

# Set the chunks
all_chunks <- split(1:mc, ceiling(seq_along(1:mc) / save_frequency))

# Run the simulation: loop over all chunks
for (chunk in 1:length(all_chunks)) {
  file <- paste0(path, "chunk_", chunk, ".rds")
  if (file.exists(file)) next  # If chunk exists, skip 
  file.create(file)  # Touch file and continue
  print(paste0(Sys.time(), ", chunk = ", chunk))
  
  # Compute the current set of seeds
  results <- foreach(seed = all_chunks[[chunk]], .errorhandling = "pass", .combine="rbind", .packages = c("esreg", "esback", "rugarch", "foreach")) %do% {
    
    # Simulate from the true model
    r <- as.numeric(fitted(ugarchpath(spec0, n + 250, n.start=100, rseed=seed)))
    
    # Evaluate the alternatives
    out <- foreach(i = 1:nrow(par_grid), .combine="rbind") %dopar% {
      par <- par_grid[i,] 
      spec <- spec0
      setfixed(spec) <- as.list(par[-c(1,2)]) # remove the set variable and tau
      
      df <- get_risk_quantities(spec = spec, r = r, alpha = par$tau)
      bt <- all_backtests(df = df, alpha = tau0, B = B)
      
      c(seed=seed, model_index=i, do.call("c", par), unlist(bt))
    }
    out
  }
  
  # Save after each chunk
  rownames(results) <- NULL
  saveRDS(results, file)
}
