import os

import matplotlib
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

import mapping as MAP
from common import mkdir
from mapping import backtest_mapping, rc_dict, get_color, get_marker

plt.ioff()


def plot_power_curve(data, backtests, version, one_sided, file_name):
    df = data[(data["set"] == version) &
              (data["one_sided"] == one_sided) &
              (data.backtest.isin(backtests))].copy()

    if version == 1:
        var = "alpha1"
        xlabel = "ARCH parameter"
        true_val = 7
        label_at = [0.01, 0.1, 0.2]
    elif version == 2:
        var = "unc_var"
        xlabel = "Unconditional variance"
        true_val = 4
    elif version == 3:
        var = "persistence"
        xlabel = "Persistence"
        true_val = 5
    elif version == 4:
        var = "shape"
        xlabel = "Degrees of freedom of the Student-$t$"
        true_val = 2
    elif version == 5:
        var = "tau"
        xlabel = "Probability Level (in %)"
        true_val = 4

    color = [get_color(backtest) for backtest in backtests]
    markers = [get_marker(backtest) for backtest in backtests]

    fig, ax = plt.subplots(figsize=(3, 2))

    sns.pointplot(ax=ax, x=var, y="value", hue="backtest", row="set", data=df,
                  markers=markers, scale=0.5, palette=color, hue_order=backtests)

    plt.setp(ax.collections, sizes=[30], zorder=100, edgecolor=["black"], lw=[0.3])

    handles, labels = ax.get_legend_handles_labels()
    if one_sided:
        #    handles, labels = handles[2:], labels[2:]
        ncol = 1
    else:
        ncol = 2


    ncol = 1
    leg = ax.legend(handles, labels, loc="best", ncol=ncol, frameon=True, labelspacing=0.3, borderpad=0.2,
                    framealpha=0.9, columnspacing=0.2)
    leg.set_zorder(200)

    ax.axvline(true_val, color="0.5")
    ax.yaxis.grid()
    ax.set_xlabel(xlabel)
    ax.set_ylabel("Rejection Rate")

    if version in [2]:
        ax.invert_xaxis()

    if version == 4:
        lab = ax.get_xticklabels()
        lab[-1] = "$\\infty$"
        ax.set_xticklabels(lab)

    if version in [1, 3]:
        for label in ax.xaxis.get_ticklabels()[::2]:
            label.set_visible(False)

    ax.yaxis.set_major_locator(matplotlib.ticker.MaxNLocator(nbins=6, steps=[1, 2, 5, 10]))

    sns.despine()
    plt.tight_layout(pad=0.1)

    mkdir(os.path.dirname(file_name))

    plt.savefig(file_name)
    plt.close('all')


def load_data(raw=False):
    if raw:
        file = 'in/monte_carlo_2/raw_rejection_rates.csv'
    else:
        file = 'in/monte_carlo_2/rejection_rates.csv'

    data = pd.read_csv(file)
    data['backtest'].replace(backtest_mapping, inplace=True)
    data['shape'] = data['shape'].astype(int)
    data = data[0.03 <= data['alpha1']]
    return data


def plot_all_power_curves(data):
    # two-sided
    all_backtests = [
        MAP.STR_ESR_M, MAP.AUX_ESR_M, MAP.INT_ESR_M,
        MAP.GENERAL_CC, MAP.SIMPLE_CC, MAP.STD_ER, MAP.ER
    ]

    for version in [1, 2, 3, 4, 5]:
        file_name = 'out/monte_carlo_2/rejection_rates/%s_2s.pdf' % version
        plot_power_curve(data=data, backtests=all_backtests, version=version, one_sided=False, file_name=file_name)

    # one-sided
    all_backtests = [
        MAP.INT_ESR_M,
        MAP.GENERAL_CC, MAP.SIMPLE_CC, MAP.STD_ER, MAP.ER
    ]
    for version in [1, 2, 3, 4, 5]:
        file_name = 'out/monte_carlo_2/rejection_rates/%s_1s.pdf' % version
        plot_power_curve(data=data, backtests=all_backtests, version=version, one_sided=True, file_name=file_name)


def print_size(data):
    all_backtests = [
        MAP.STR_ESR, MAP.AUX_ESR, MAP.INT_ESR,
        MAP.STR_ESR_M, MAP.AUX_ESR_M, MAP.INT_ESR_M,
        MAP.GENERAL_CC, MAP.SIMPLE_CC, MAP.STD_ER, MAP.ER
    ]

    size = data.query('model_index == 10').pivot('one_sided', 'backtest', 'value')
    size = size[all_backtests]

    size.insert(0, 'sides', ['Two-Sided', 'One-Sided'])
    size = size.fillna('--')

    string_latex = size.to_latex(float_format=lambda x: '%0.2f' % x, na_rep="--",
                                 escape=False, index=False, header=False)

    string = '\n'.join(string_latex.split('\n')[2:-3])

    file = 'out/monte_carlo_2/size.txt'
    open(file, 'wb').write(bytes(string, 'UTF-8'))


if __name__ == '__main__':
    sns.set(style='white', rc=rc_dict)

    data = load_data()
    data_raw = load_data(raw=True)

    plot_all_power_curves(data)
    print_size(data_raw)