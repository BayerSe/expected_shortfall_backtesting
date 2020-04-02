import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

from mapping import rc_dict

plt.ioff()


if __name__ == '__main__':
    sns.set(style='white', rc=rc_dict)

    parameter_estimates = pd.read_csv('in/monte_carlo_check_approximations/parameter_estimates.csv')
    test_statistics = pd.read_csv('in/monte_carlo_check_approximations/test_statistics.csv')
    c_factor = pd.read_csv('in/monte_carlo_check_approximations/c-factor.csv')
    c_factor = c_factor[:200]

    phis = ['0', '0.1', '0.5']

    sns.set(style='white', rc=rc_dict)

    fig, axs = plt.subplots(4, 3, sharey='row', figsize=(6, 5))

    # Time Series
    for i, phi in enumerate(phis):
        c_factor[phi].plot(ax=axs[0][i], style='k', lw=1)

    for i in range(len(phis)):
        axs[0][i].set_ylim([c_factor.min().min() * 0.98, c_factor.max().max() * 1.02])

    # Density of test statistics
    for i, phi in enumerate(phis):
        val = test_statistics.query(f'model == "Strict" & phi == {phi}')['value']
        sns.distplot(val, ax=axs[3][i], hist=False, kde_kws={"color": "black"})

        val = test_statistics.query(f'model == "Auxiliary" & phi == {phi}')['value']
        sns.distplot(val, ax=axs[3][i], hist=False, kde_kws={"linestyle": "--", "color": "green"})

    # Density of parameter estimates
    for i, phi in enumerate(phis):

        # Strict: Q
        val = parameter_estimates.query(f'equation == "Q" & model == "Strict" & parameter == "Intercept" & phi == {phi}')['value']
        sns.distplot(val, ax=axs[1][i], hist=False, kde_kws={"color": "black"})

        val = parameter_estimates.query(f'equation == "Q" & model == "Strict" & parameter == "Slope" & phi == {phi}')['value']
        sns.distplot(val, ax=axs[1][i], hist=False, kde_kws={"color": "black"})

        # Auxiliary: Q
        val = parameter_estimates.query(f'equation == "Q" & model == "Auxiliary" & parameter == "Intercept" & phi == {phi}')['value']
        sns.distplot(val, ax=axs[1][i], hist=False, kde_kws={"linestyle": "--", "color": "green"})

        val = parameter_estimates.query(f'equation == "Q" & model == "Auxiliary" & parameter == "Slope" & phi == {phi}')['value']
        sns.distplot(val, ax=axs[1][i], hist=False, kde_kws={"linestyle": "--", "color": "green"})

        # Strict: ES
        val = parameter_estimates.query(f'equation == "ES" & model == "Strict" & parameter == "Intercept" & phi == {phi}')['value']
        sns.distplot(val, ax=axs[2][i], hist=False, kde_kws={"color": "black"})

        val = parameter_estimates.query(f'equation == "ES" & model == "Strict" & parameter == "Slope" & phi == {phi}')['value']
        sns.distplot(val, ax=axs[2][i], hist=False, kde_kws={"color": "black"})

        # Auxiliary: ES
        val = parameter_estimates.query(f'equation == "ES" & model == "Auxiliary" & parameter == "Intercept" & phi == {phi}')['value']
        sns.distplot(val, ax=axs[2][i], hist=False, kde_kws={"linestyle": "--", "color": "green"})

        val = parameter_estimates.query(f'equation == "ES" & model == "Auxiliary" & parameter == "Slope" & phi == {phi}')['value']
        sns.distplot(val, ax=axs[2][i], hist=False, kde_kws={"linestyle": "--", "color": "green"})

        for j in range(1, 3):
            axs[j][i].axvline(0, color='0.5', zorder=0)
            axs[j][i].axvline(1, color='0.5', zorder=0)
            axs[j][i].text(-0.04, 3, 'Intercept', rotation=0, ha='right', fontsize=6)
            axs[j][i].text(1.04, 3, 'Slope', rotation=0, ha='left', fontsize=6)
            axs[j][i].set_ylim((0, 4))
            axs[j][i].set_xlim((-0.9, 1.9))

    for i in range(4):
        for j in range(len(phis)):
            axs[i][j].set_xlabel('')

    for i, phi in enumerate(phis):
        axs[0][i].set_title(f'$c_t = \\hat e_t / \\hat v_t$, $\phi = {phi}$')
        axs[1][i].set_title(f'Density of $\\beta$, $\phi = {phi}$')
        axs[2][i].set_title(f'Density of $\\gamma$, $\phi = {phi}$')
        axs[3][i].set_title(f'Density of $T$, $\phi = {phi}$')

    plt.tight_layout(pad=1, h_pad=2)
    sns.despine()
    plt.savefig('out/monte_carlo_check_approximations/check_approximations.pdf')
    plt.close('all')
