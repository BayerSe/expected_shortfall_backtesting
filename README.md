# Regression Based Expected Shortfall Backtesting

[![DOI](https://zenodo.org/badge/DOI/DOI.svg)](https://doi.org/DOI)

This repository contains all codes required to replicate the 
paper "Regression Based Expected Shortfall Backtesting"
published in the Journal of Financial Econometrics (JFEC).

It contains R code that generates the results ("analysis") 
and Python code that creates the plots ("plots").


## Overview of the experiments

### Monte Carlo Study 1 (p. x)

| File  | Description |
|---|---|
| [analysis/monte_carlo_1_01_save_risk_models.R](analysis/monte_carlo_1_01_save_risk_models.R) | Generates all required risk models and saves them to the disk |
| [analysis/monte_carlo_1_02_simulation.R](analysis/monte_carlo_1_02_simulation.R) | Uses the risk models to simulate data and performs backtests on the simulated series |
| [analysis/monte_carlo_1_03_evaluation.R](analysis/monte_carlo_1_03_evaluation.R) | Aggreagtes the simulation results |
| [plots/plot_monte_carlo_1.py](plots/plot_monte_carlo_1.py) | Generates tables and plots |


### Monte Carlo Study 2 (p. x)

| File  | Description |
|---|---|
| [analysis/monte_carlo_2_01_simulation.R](analysis/monte_carlo_2_01_simulation.R) | TBA |
| [analysis/monte_carlo_2_02_evaluation.R](analysis/monte_carlo_2_02_evaluation.R) | TBA |
| [analysis/monte_carlo_2_03_example_series.R](analysis/monte_carlo_2_03_example_series.R) | TBA |
| [plots/plot_monte_carlo_2.py](plots/plot_monte_carlo_2.py) | TBA |
| [plots/plot_monte_carlo_2_illustration.py](plots/plot_monte_carlo_2_illustration.py) | TBA |


### Check approximations (p. x)

| File  | Description |
|---|---|
| [analysis/monte_carlo_check_approximations.R](analysis/monte_carlo_check_approximations.R) | TBA |
| [plots/plot_monte_carlo_check_approximations.py](plot_monte_carlo_check_approximations.py) | TBA |


### Empirical Application (p. x)

| File  | Description |
|---|---|
| [analysis/empirical_application_01_get_data.R](analysis/empirical_application_01_get_data.R) | TBA |
| [analysis/empirical_application_02_estimation_window_comparison.R](analysis/empirical_application_02_estimation_window_comparison.R) | TBA |
| [analysis/empirical_application_03_compute_backtest_results.R](analysis/empirical_application_03_compute_backtest_results.R) | TBA |
| [analysis/empirical_application_04_evaluation.R](analysis/empirical_application_04_evaluation.R) | TBA |
