rm(list = ls())

library(pacman)
p_load(rugarch, quantmod)


# Load data ---------------------------------------------------------------

file <- "data/sp500_returns.rds"

if (file.exists(file)) {
  r <- readRDS(file)
} else {
  p <- quantmod::getSymbols("^GSPC", auto.assign = FALSE, 
                            from = "2000-01-01", to = "2018-12-31")
  p <- p[,6]
  r <- xts::diff.xts(p, log=TRUE, na.pad=FALSE) * 100
  saveRDS(r, file)
}

all_models <- list()



# AR(1)-GARCH(1,1)-Normal Ar 0.0 ------------------------------------------

model <- list(
  comment = "AR(1)-GARCH(1,1)-Normal AR 0.0",
  name = 'ar1_garch11_normal_ar0.0',
  spec = ugarchspec(
    mean.model=list(armaOrder=c(1,0), include.mean=TRUE),
    variance.model=list(model="sGARCH"),
    distribution.model="norm",
    fixed.pars=list(mu=0, ar1=0,
                    omega=0.01, alpha1=0.1, beta1=0.85))
)
all_models <- c(all_models, list(model))


# AR(1)-GARCH(1,1)-Normal Ar 0.1 ------------------------------------------

model <- list(
  comment = "AR(1)-GARCH(1,1)-Normal AR 0.1",
  name = 'ar1_garch11_normal_ar0.1',
  spec = ugarchspec(
    mean.model=list(armaOrder=c(1,0), include.mean=TRUE),
    variance.model=list(model="sGARCH"),
    distribution.model="norm",
    fixed.pars=list(mu=0, ar1=0.1,
                    omega=0.01, alpha1=0.1, beta1=0.85))
)
all_models <- c(all_models, list(model))


# AR(1)-GARCH(1,1)-Normal Ar 0.3 ------------------------------------------

model <- list(
  comment = "AR(1)-GARCH(1,1)-Normal AR 0.3",
  name = 'ar1_garch11_normal_ar0.3',
  spec = ugarchspec(
    mean.model=list(armaOrder=c(1,0), include.mean=TRUE),
    variance.model=list(model="sGARCH"),
    distribution.model="norm",
    fixed.pars=list(mu=0, ar1=0.3,
                    omega=0.01, alpha1=0.1, beta1=0.85))
)
all_models <- c(all_models, list(model))


# AR(1)-GARCH(1,1)-Normal Ar 0.5 ------------------------------------------

model <- list(
  comment = "AR(1)-GARCH(1,1)-Normal AR 0.5",
  name = 'ar1_garch11_normal_ar0.5',
  spec = ugarchspec(
    mean.model=list(armaOrder=c(1,0), include.mean=TRUE),
    variance.model=list(model="sGARCH"),
    distribution.model="norm",
    fixed.pars=list(mu=0, ar1=0.5,
                    omega=0.01, alpha1=0.1, beta1=0.85))
)
all_models <- c(all_models, list(model))


# EGARCH-t, calibrated ----------------------------------------------------

spec <- ugarchspec(mean.model=list(armaOrder=c(0,0), include.mean=FALSE),
                   variance.model=list(model="eGARCH"),
                   distribution.model="std")
fit <- ugarchfit(spec = spec, data = r)
setfixed(spec) <- as.list(coef(fit))
model <-list(
  comment = "EGARCH-t, calibrated to S&P500 from 2000-01-01 to 2018-12-28",
  name = 'egarch_t_calibrated',
  spec = spec
)
all_models <- c(all_models, list(model))


# GAS Student-t -----------------------------------------------------------

spec <- GAS::UniGASSpec(Dist = "std", ScalingType = "Identity",
                        GASPar = list(scale = TRUE, shape=TRUE))
fit <- GAS::UniGASFit(spec, r)
model <-list(
  comment = "GAS-Student-t, calibrated to S&P500 from 2000-01-01 to 2018-12-28",
  name = 'gas_std_calibrated',
  spec = fit
)
all_models <- c(all_models, list(model))


# GAS skewed Student-t ----------------------------------------------------

spec <- GAS::UniGASSpec(Dist = "sstd", ScalingType = "Identity",
                        GASPar = list(location=TRUE, scale = TRUE, shape=TRUE, skewness=TRUE))
fit <- GAS::UniGASFit(spec, r)
model <-list(
  comment = "GAS-skew-Student-t, calibrated to S&P500 from 2000-01-01 to 2018-12-28",
  name = 'gas_sstd_calibrated',
  spec = fit
)
all_models <- c(all_models, list(model))


# Save models -------------------------------------------------------------

for (model in all_models) {
  saveRDS(model, paste0('data/models/', model$name, '.rds'))
}
