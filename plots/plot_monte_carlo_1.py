import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

import mapping as MAP
from common import mkdir
from mapping import backtest_mapping, rc_dict, get_color, get_marker, dgp_mapping

plt.ioff()


def compute_pauc(roc, lower=0.0, upper=1.0):
    idx = (lower <= roc.index) & (roc.index <= upper)
    auc = np.trapz(y=roc[idx], x=roc.index[idx]) / (upper - lower)
    return auc


def get_subset_of_data(data, null_model, sample_size, backtest):
    df = data[
        (data['null_model'] == null_model) &
        (data['sample_size'] == sample_size) &
        (data['one_sided'] == False) &
        (data['model'] == backtest)
        ].reset_index()
    return df


def plot_roc(data, null_model, sample_size, backtests, file_name):
    df0 = get_subset_of_data(data, null_model, sample_size, 'Oracle')
    df1 = get_subset_of_data(data, null_model, sample_size, 'Historical_Simulation')

    p = []
    for backtest in backtests:
        p0 = df0.query('backtest == "%s"' % backtest).set_index('sig_lev')['rej_rate']
        p1 = df1.query('backtest == "%s"' % backtest).set_index('sig_lev')['rej_rate']
        p_ = pd.Series(p1.values, index=p0.values, name=backtest).interpolate().bfill()
        p.append(p_)

    fig, ax = plt.subplots(figsize=(3, 2))
    for i, pp in enumerate(p):
        name = pp.name
        pp = pd.concat((pp, pd.Series(index=[0.2, 0.4, 0.6]))).sort_index()
        pp = pp.interpolate()
        pp.name = name
        line = pp.plot(ax=ax, lw=1.5, color=get_color(name), marker=get_marker(name),
                       markevery=[np.abs(pp.index - s).argmin() for s in [0.2, 0.4, 0.6, 0.8]],
                       markeredgecolor="black", markeredgewidth=0.3, markersize=5.5)
    ax.plot([0, 1], color="k", lw=1)
    ax.yaxis.grid()
    ax.legend(loc="lower right", ncol=1, frameon=True, labelspacing=0.3, borderpad=0.2, framealpha=1)
    ax.set_xlabel('Empirical Size of the Test')
    ax.set_ylabel('Empirical Power of the Test')
    plt.tight_layout(pad=0.1)
    sns.despine()

    plt.savefig(file_name)
    plt.close()


def plot_pauc(data, null_model, backtests, file_name):
    sample_sizes = data.sample_size.unique()

    lst = []
    for sample_size in sample_sizes:
        df0 = get_subset_of_data(data, null_model, sample_size, 'Oracle')
        df1 = get_subset_of_data(data, null_model, sample_size, 'Historical_Simulation')

        for backtest in backtests:
            p0 = df0.query('backtest == "%s"' % backtest).set_index('sig_lev')['rej_rate']
            p1 = df1.query('backtest == "%s"' % backtest).set_index('sig_lev')['rej_rate']
            roc = pd.Series(p1.values, index=p0.values, name=backtest).interpolate().bfill()
            _pauc = compute_pauc(roc, lower=0.01, upper=0.1)

            lst.append({'backtest': backtest, 'sample_size': sample_size, 'pauc': _pauc})
    pauc = pd.DataFrame(lst)

    color = [get_color(backtest) for backtest in backtests]
    markers = [get_marker(backtest) for backtest in backtests]

    fig, ax = plt.subplots(figsize=(3, 2))

    sns.pointplot(ax=ax, x="sample_size", y='pauc', hue="backtest", data=pauc, palette=color,
                  markers=markers, scale=0.5, hue_order=backtests)

    plt.setp(ax.collections, sizes=[30], zorder=100, edgecolor=["black"], lw=[0.3])
    handles, labels = ax.get_legend_handles_labels()
    ax.legend(handles, labels, loc="best", ncol=1, frameon=True, labelspacing=0.3, borderpad=0.2, framealpha=1)
    ax.yaxis.grid()
    ax.set_xlabel("Sample Size")
    ax.set_ylabel("Partial Area Under the Curve")
    sns.despine()
    plt.tight_layout(pad=0.1)

    plt.savefig(file_name)
    plt.close()


def load_data():
    data = pd.read_csv('in/monte_carlo_1/rejection_rates.csv')
    data['backtest'].replace(backtest_mapping, inplace=True)
    return data


def print_size_table(df, path, significance_level, dgp):
    df.insert(0, "sample", df.index)
    df.insert(0, "dgp", ["", "", dgp, "", ""])
    #df.insert(0, "size", ["", "", str(int(significance_level * 100)) + "\\%", "", ""])
    df = df.fillna("--")

    first_line = '% ' + ' | '.join(df.columns) + '\n'

    string_latex = df.to_latex(float_format=lambda x: '%0.2f' % x, na_rep="--",
                               escape=False, index=False, header=False)
    string = '\n'.join(string_latex.split('\n')[2:-3])

    string = first_line + string

    file = path + 'size_%s.txt' % significance_level
    open(file, 'wb').write(bytes(string, 'UTF-8'))


def print_size_tables(data):
    all_backtests = [
        MAP.STR_ESR_M, MAP.AUX_ESR_M, MAP.INT_ESR_M,
        MAP.STR_ESR, MAP.AUX_ESR, MAP.INT_ESR,
        MAP.GENERAL_CC, MAP.SIMPLE_CC, MAP.STD_ER, MAP.ER
    ]

    for null_model in data.null_model.unique():
        for significance_level in [0.01, 0.05, 0.1]:

            size = data.query('model == "Oracle" & sig_lev == %s & null_model == "%s" & one_sided == False' %
                              (significance_level, null_model))
            size = size.pivot('sample_size', 'backtest', 'rej_rate')
            size = size[all_backtests]

            path = 'out/monte_carlo_1/%s/' % null_model
            mkdir(path)
            print_size_table(df=size, path=path, significance_level=significance_level, dgp=dgp_mapping[null_model])


def plot_power_curves(data):
    all_backtests = [
        MAP.STR_ESR_M, MAP.AUX_ESR_M, MAP.INT_ESR_M,
        MAP.GENERAL_CC, MAP.SIMPLE_CC, MAP.STD_ER, MAP.ER
    ]

    sample_sizes = [250, 500, 1000, 2500, 5000]

    for null_model in data.null_model.unique():
        path = 'out/monte_carlo_1/%s/' % null_model
        mkdir(path)

        # roc
        for sample_size in sample_sizes:
            file_name = path + 'roc_%s.pdf' % sample_size
            plot_roc(data, null_model, sample_size, all_backtests, file_name)

        # pauc
        file_name = path + 'pauc.pdf'
        plot_pauc(data, null_model, all_backtests, file_name)


if __name__ == '__main__':
    sns.set(style='white', rc=rc_dict)
    data = load_data()
    print_size_tables(data)
    plot_power_curves(data)
