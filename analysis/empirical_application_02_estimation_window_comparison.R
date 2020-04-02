rm(list = ls())
library(pacman)
p_load(rugarch, xts, dplyr, doParallel, tbl2xts)

.all_ok <- function(fit, spec) {
  tryCatch({
    valid_messages <- c( # nlminb
      'X-convergence (3)',
      'relative convergence (4)',
      'both X-convergence and relative convergence (5)',
      'singular convergence (7)',
      'false convergence (8)'
    )
    all_ok <- all(is.null(fit) == FALSE, inherits(fit, 'try-error') == FALSE)
    if (all_ok) {
      message <- fit@fit$message
      if (is.null(message)) {
        all_ok <- TRUE
      } else {
        all_ok <- (message %in% valid_messages)
      }
    }
    if (all_ok) {
      spec_fix <- spec
      setfixed(spec_fix) <- as.list(fit@fit$solver$sol$par)
      filter <- ugarchfilter(spec=spec_fix, data=fit@model$modeldata$data)
      forc <- ugarchforecast(spec_fix, fit@model$modeldata$data, n.ahead=1)
      all_ok <- all(c(is.finite(c(fitted(forc), sigma(forc), quantile(forc, 0.01))), abs(quantile(forc, 0.01)) < 1))
    }
    if (all_ok) {
      z <- (filter@model$modeldata[[2]] - fitted(filter)) / sigma(filter)
      all_ok <- all(all(is.finite(z)), all(abs(z) < 1e6))
    }
    
    all_ok
  }, error=function(cond) {FALSE})
}

get_forcecasts <- function(r, spec, alpha, win, refit) {
  n <- nrow(r)
  end_values <- seq(win + refit, n, by = refit)
  nr_windows <- length(end_values)
  out.sample <- rep(refit, nr_windows)
  if (end_values[nr_windows] < n) {
    end_values <- c(end_values, n)
    nr_windows <- nr_windows + 1
    out.sample <- c(out.sample, end_values[nr_windows] - end_values[nr_windows - 1])
  }
  
  forc <- foreach(i = 1:nr_windows, .combine = 'rbind') %do% {
    # Subset data
    r_ <- r[(end_values[i]-win-refit+1):end_values[i], ]
    
    # Fit the model
    fit <- try(ugarchfit(spec=spec, data=r_, out.sample=out.sample[i], solver='nlminb'), silent=TRUE)
    if (!.all_ok(fit, spec)) {
      fit <- try(ugarchfit(spec=spec, data=df, out.sample=out.sample[i], solver='solnp'), silent=TRUE)
    }
    
    if (.all_ok(fit, spec)) {
      last_working_fit <- fit
    } else {
      print(paste0('restored model at window = ', i))
      fit <- last_working_fit
    }
    
    # Forecasts of mean and variance
    spec_fix <- spec
    setfixed(spec_fix) <- as.list(fit@fit$solver$sol$par)
    forc <- ugarchforecast(spec_fix, r_, n.ahead = 1, n.roll = out.sample[i] - 1, out.sample = out.sample[i])
    
    m <- fitted(forc)
    s <- sigma(forc)
    
    m <- xts(as.numeric(m), order.by = tail(index(r_), out.sample[i]))
    s <- xts(as.numeric(s), order.by = tail(index(r_), out.sample[i]))
    
    # Quantile function of the innovations
    qf <- function(x, spec) qdist(distribution=spec@model$modeldesc$distribution, p=x, mu=0, sigma=1,
                                  shape=spec@model$fixed.pars$shape, skew=spec@model$fixed.pars$skew, 
                                  lambda=spec@model$fixed.pars$ghlambda)
    
    # VaR and ES of the innovations
    vq <- qf(alpha, spec_fix)
    ve <- integrate(qf, 0, alpha, spec = spec_fix)$value / alpha
    
    # VaR and ES of the returns
    q <- m + s * vq
    e <- m + s * ve
    
    df <- cbind(tail(r_, out.sample[i]), m, s, q, e)
    colnames(df) <- c('r', 'm', 's', 'q', 'e')
    df
  }
  
  forc  
}

# Start the pool
nodename <- Sys.info()['nodename']
if (grepl('uc1', nodename)) {
  cores <- as.numeric(Sys.getenv('SLURM_NPROCS'))
  registerDoParallel(cores=cores)
} else {
  registerDoSEQ() 
}

sorted_tickers <- readRDS('data/empirical_application/sorted_tickers.rds')
returns <- readRDS('data/empirical_application/returns.rds')

setup <- expand.grid(
  variance.model     = c('sGARCH', 'gjrGARCH'),
  distribution.model = c('norm', 'std'),
  last_x             = 2500,
  win                = 250 * c(1, 2, 4, 6, 8),
  refit              = round(250 / c(1, 2, 4, 12, 52)),
  alpha              = 0.025,
  symbol             = sorted_tickers[1:200],
  stringsAsFactors = FALSE
)

tmp <- foreach(row = seq_along(seq_len(nrow(setup))), .errorhandling = 'pass') %dopar% {
  st <- c(setup[row,])
  file <- paste0('data/empirical_application/results/', paste(st, collapse = '-'), '.rds')  
  if (file.exists(file)) {next()} else {file.create(file)}
  print(paste0('Processing ', st$symbol, ', win = ', st$win, ', refit = ', st$refit))
  
  r <- returns %>% 
    dplyr::filter(symbol == st$symbol) %>% 
    dplyr::slice((n() - st$last_x - st$win + 1):dplyr::n()) %>% 
    tbl2xts::tbl_xts()
  
  spec <- ugarchspec(
    mean.model = list(armaOrder = c(0, 0), include.mean = FALSE),
    variance.model = list(model = st$variance.model),
    distribution.model = st$distribution.model
  )
  
  forc <- get_forcecasts(r = r, spec = spec, alpha = st$alpha, win = st$win, refit = st$refit)
  
  saveRDS(list(forc = forc, settings = st), file)
  print(paste0('Save results to ', file))
}
