# Regression Based Expected Shortfall Backtesting

[![DOI](https://zenodo.org/badge/DOI/DOI.svg)](https://doi.org/DOI)

This repository contains all codes required to replicate the 
paper "Regression Based Expected Shortfall Backtesting"
published in the Journal of Financial Econometrics (JFEC).

It contains R code that generates the results ("analysis") 
and Python code that creates the plots ("plots").


### Monte Carlo Study 1 (p. x)


| File  | Description |
|---|---|
| [analysis/monte_carlo_1_01_save_risk_models.R](analysis/monte_carlo_1_01_save_risk_models.R) | Generates all required risk models and saves them to the disk |
| [analysis/monte_carlo_1_02_simulation.R](analysis/monte_carlo_1_02_simulation.R) | Uses the risk models to simulate data and performs backtests on the simulated series |
| [analysis/monte_carlo_1_03_evaluation.R](analysis/monte_carlo_1_03_evaluation.R) | Aggreagtes the simulation results |
| [plots/plot_monte_carlo_1.py](plots/plot_monte_carlo_1.py) | Generates tables and plots |
