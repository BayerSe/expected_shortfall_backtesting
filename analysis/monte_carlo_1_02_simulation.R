rm(list = ls())

library(pacman)
p_load(foreach, doParallel, rugarch, GAS, xts, esback, dplyr)

source("functions.R")

# Start the pool
nodename <- Sys.info()["nodename"]
if (grepl("uc1", nodename)) {
  cores <- as.numeric(Sys.getenv("SLURM_NPROCS"))
  registerDoParallel(cores=cores)
} else {
  registerDoSEQ() 
}

path <- "data/monte_carlo_1_results/"
if (!(dir.exists(path))) {
  dir.create(path)
}

# Simulation settings
alpha <- 0.025
all_n <- c(250, 500, 1000, 2500, 5000)
n0 <- 250  # Longest rolling estimation window of the alternative models
mc <- 10000
B <- 0
save_frequency <- 100
all_chunks <- split(1:mc, ceiling(seq_along(1:mc) / save_frequency))

# List of true models
spec_list <- lapply(list.files('data/models/', full.names = TRUE), readRDS)

# Run the simulation
for (chunk in 1:length(all_chunks)) {
  for (design in 1:length(spec_list)) {
    
    model_name <- spec_list[[design]]$name
    file <- paste0(path, model_name, '-', chunk, '.rds')
    if (file.exists(file)) next  # If chunk exists, skip 
    file.create(file)  # Touch file and continue
    results <- data.frame()
    
    # Set the null model
    spec0 <- spec_list[[design]]
    
    # Loop over all sample sizes
    for (n in all_n) {
      print(paste0(Sys.time(), ", chunk = ", chunk, ", design = ", design, ", n = ", n))
      
      # Compute the current set of seeds
      out <- foreach(seed = all_chunks[[chunk]], .errorhandling = "pass", .packages = c("esback", "rugarch", "foreach")) %dopar% {        
        # Simulate from the true DGP
        sim_process <- get_simulated_series(spec = spec0$spec, n = n + n0 + 250, seed = seed)
        sim <- sim_process$sim
        r <- sim_process$sim_series
        
        # Get risk quantities for the true DGP
        df0 <- get_risk_quantities(spec = spec0$spec, r = r, sim = sim, alpha=alpha)
        df0 <- df0[(250+n0+1):nrow(df0),]
        
        # Alternative model: Historical Simulation
        q <- e <- s <- rep(NA, length(r))
        for (t in (250+1):length(r)) {
          r_tmp <- r[(t-250):(t-1)]
          q[t] <- quantile(r_tmp, probs = alpha)
          e[t] <- mean(r_tmp[r_tmp <= q[t]])
          s[t] <- sd(r_tmp)
        }
        df1 <- data.frame(r = r, mu = NA, s = s, q = q, e = e)
        df1 <- df1[(250+n0+1):nrow(df1),]
        
        # Compute the backtests
        bt0 <- all_backtests(df = df0, alpha = alpha, B = B)
        bt1 <- all_backtests(df = df1, alpha = alpha, B = B)
        
        bt <- list(Oracle = bt0, Historical_Simulation = bt1)
        
        # Return results
        ret <- do.call('rbind', lapply(names(bt), function(mod) {
          dplyr::tibble(seed = seed, design = design, null_model = model_name, sample_size = n,
                        model = mod, backtest = names(bt[[mod]]), pvalue = unlist(bt[[mod]]))
        }))
      }
      
      # Drop errors
      out_error <- sapply(out, function(x) inherits(x, "simpleError"))
      out <- do.call('rbind', out[!out_error])
      
      # Append
      results <- rbind(results, out)
    }
    # Export after each chunk
    saveRDS(results, file)
    
  }
}
