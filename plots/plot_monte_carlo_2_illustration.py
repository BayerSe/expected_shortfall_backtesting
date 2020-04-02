import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

from common import mkdir
from mapping import rc_dict

plt.ioff()


def plot_illustration(data):
    r = data[(data["type"] == "r") & (data["set"] == 1) & (data["alpha1"] == 0.1)]["value"].reset_index(drop=True)
    color = ["#466c9a", "#000000", "#b7d0ee"]

    for version in [1, 2, 3, 4, 5]:
        type = "e"
        df = data[(data["type"] == type) & (data["set"] == version)]

        if version == 1:
            df = df.pivot(index="variable", columns="alpha1", values="value")
            df = df.iloc[:, [np.abs((df.columns - x)).argmin() for x in [0.2, 0.1, 0.03]]]
            legend_title = "ARCH parameter"
        elif version == 2:
            df = df.pivot(index="variable", columns="unc_var", values="value")
            df = df.iloc[:, [np.abs((df.columns - x)).argmin() for x in [0.001, 0.2, 0.5]]]
            legend_title = "Unconditional Variance"
        if version == 3:
            df = df.pivot(index="variable", columns="persistence", values="value")
            df = df.iloc[:, [np.abs((df.columns - x)).argmin() for x in [0.9, 0.95, 0.9999]]]
            legend_title = "Persistence"
        if version == 4:
            df = df.pivot(index="variable", columns="shape", values="value")
            df = df.iloc[:, [np.abs((df.columns - x)).argmin() for x in [3, 5, 1000000]]]
            legend_title = "Degrees of freedom of the Student-$t$"
        if version == 5:
            df = df.pivot(index="variable", columns="tau", values="value")
            df = df.iloc[:, [np.abs((df.columns - x)).argmin() for x in [0.5, 2.5, 5]]]
            legend_title = "Probability Level (in %)"

        df.columns = [str(x) + (" (true) " if i == 1 else "") for i, x in enumerate(df.columns)]

        figsize = 3, 1.5
        fig, ax = plt.subplots(figsize=figsize)
        df.plot(ax=ax, legend=False, linewidth=1.2, style=["-", "--", "-"], color=color)
        r.plot(ax=ax, legend=False, style=".k", label='_nolegend_')

        legend = ax.legend(loc="upper left", ncol=4, frameon=True, labelspacing=0.3, borderpad=0.2, framealpha=1,
                           title=legend_title)
        legend.get_title().set_fontsize('7')

        if version == 4:
            ax.get_legend().texts[-1].set_text("$\\infty$")

        if type == "q":
            ax.set_ylabel("VaR")
        else:
            ax.set_ylabel("Return and ES")
        ax.set_xlabel("Observation Number")
        ax.yaxis.grid()
        ax.set_ylim((-4, 4))
        plt.tight_layout(pad=0.1)
        sns.despine()
        path = 'out/monte_carlo_2/example_series/'
        mkdir(path)
        plt.savefig(path + str(version) + "_" + type + ".pdf")
        plt.close('all')


def load_data():
    data = pd.read_csv('in/monte_carlo_2/illustration_series')
    data = data[data.variable <= 250]
    data["shape"] = data["shape"].astype(int)
    data["a/b"] = data["alpha1"].astype(str) + " | " + data["beta1"].astype(str)
    data["tau"] *= 100
    return data


if __name__ == '__main__':
    sns.set(style='white', rc=rc_dict)

    data = load_data()
    plot_illustration(data)
