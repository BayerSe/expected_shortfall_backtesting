get_simulated_series <- function(spec, n, seed) {
  if (inherits(spec, "uGARCHspec")) {
    set.seed(seed)
    sim <- ugarchpath(spec, n, n.start = 100)
    sim_series <- as.numeric(fitted(sim))
  } else if (inherits(spec, "uGASFit")) {
    set.seed(seed)
    sim <- GAS::UniGASSim(fit = spec, T.sim = n)
    sim_series <- as.numeric(getObs(sim))
  } else {
    stop("This is a non-supported specification")
  }

  list(sim = sim, sim_series = sim_series)
}

get_risk_quantities <- function(spec, r, sim, alpha) {
  if (inherits(spec, "uGARCHspec")) {
    df <- .filter_ugarchspec(spec = spec, r = r, alpha = alpha)
  } else if (inherits(spec, "uGASFit")) {
    df <- .filter_gasfit(sim = sim, r = r, alpha = alpha)
  } else {
    stop("This is a non-supported specification")
  }

  df
}

.filter_ugarchspec <- function(spec, r, alpha) {
  # Filter the data with the provided specification
  filter <- ugarchfilter(spec, r)
  mu <- as.numeric(fitted(filter))
  s <- as.numeric(sigma(filter))

  # Quantile function of the innovations
  qf <- function(x) {
    qdist(
      distribution = spec@model$modeldesc$distribution, p = x, mu = 0, sigma = 1,
      shape = spec@model$fixed.pars$shape, skew = spec@model$fixed.pars$skew,
      lambda = spec@model$fixed.pars$ghlambda
    )
  }

  # VaR and ES of the innovations
  vq <- qf(alpha)
  ve <- integrate(qf, 0, alpha)$value / alpha

  # VaR and ES of the returns
  q <- mu + s * vq
  e <- mu + s * ve

  data.frame(r = r, mu = mu, s = s, q = q, e = e)
}

.filter_gasfit <- function(sim, r, alpha) {
  qf <- function(x, par) {
    qdist_Uni(p = x, Theta = par, Dist = sim@ModelInfo$Dist)
  }
  ef <- function(x, par) {
    integrate(function(x) sapply(x, function(z) qf(z, par)),
      lower = 0, upper = x
    )$value / x
  }

  moments <- GAS::getMoments(sim)
  pars <- GAS::getFilteredParameters(sim)

  # Fix this bug: https://github.com/LeopoldoCatania/GAS/issues/2
  moments <- moments[-nrow(moments), ]
  pars <- pars[-nrow(pars), ]

  mu <- moments[, 1]
  s <- moments[, 2]
  q <- sapply(seq_len(nrow(pars)), function(idx) qf(alpha, pars[idx, ]))
  e <- sapply(seq_len(nrow(pars)), function(idx) ef(alpha, pars[idx, ]))

  data.frame(r = r, mu = mu, s = s, q = q, e = e)
}


all_backtests <- function(df, alpha, B = 0) {
  # Extract variables
  r <- df$r
  q <- df$q
  e <- df$e
  s <- df$s

  # Existing tests
  bt_er <- er_backtest(r = r, q = q, e = e, s = s)
  bt_cc <- cc_backtest(r = r, q = q, e = e, s = s, alpha = alpha)

  names(bt_er) <- paste0("er_", names(bt_er))
  names(bt_cc) <- paste0("cc_", names(bt_cc))

  # ESR tests without misspecification
  cov_config_1 <- list(sparsity = "nid", sigma_est = "scl_sp", misspec = FALSE)

  bt_esr_1 <- esr_backtest(r = r, q = q, e = e, alpha = alpha, B = B, version = 1, cov_config = cov_config_1)
  bt_esr_2 <- esr_backtest(r = r, q = q, e = e, alpha = alpha, B = B, version = 2, cov_config = cov_config_1)
  bt_esr_3 <- esr_backtest(r = r, q = q, e = e, alpha = alpha, B = B, version = 3, cov_config = cov_config_1)

  names(bt_esr_1) <- paste0("esr1_", names(bt_esr_1))
  names(bt_esr_2) <- paste0("esr2_", names(bt_esr_2))
  names(bt_esr_3) <- paste0("esr3_", names(bt_esr_3))

  # ESR tests with misspecification
  cov_config_2 <- list(sparsity = "nid", sigma_est = "scl_sp", misspec = TRUE)

  bt_esr_1_misspec <- esr_backtest(r = r, q = q, e = e, alpha = alpha, B = B, version = 1, cov_config = cov_config_2)
  bt_esr_2_misspec <- esr_backtest(r = r, q = q, e = e, alpha = alpha, B = B, version = 2, cov_config = cov_config_2)
  bt_esr_3_misspec <- esr_backtest(r = r, q = q, e = e, alpha = alpha, B = B, version = 3, cov_config = cov_config_2)

  names(bt_esr_1_misspec) <- paste0("esr1_misspec_", names(bt_esr_1_misspec))
  names(bt_esr_2_misspec) <- paste0("esr2_misspec_", names(bt_esr_2_misspec))
  names(bt_esr_3_misspec) <- paste0("esr3_misspec_", names(bt_esr_3_misspec))

  # Return results
  ret <- c(
    bt_er, bt_cc,
    bt_esr_1, bt_esr_2, bt_esr_3,
    bt_esr_1_misspec, bt_esr_2_misspec, bt_esr_3_misspec
  )

  ret
}
