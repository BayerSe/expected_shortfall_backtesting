import seaborn as sns


GENERAL_CC = 'General CC'
SIMPLE_CC = 'Simple CC'
STD_ER = 'Std. ER'
ER = 'ER'

STR_ESR = 'Str. ESR'
STR_ESR_B = 'Str. ESR (b)'
STR_ESR_M = 'Str. ESR (m)'
STR_ESR_M_B = 'Str. ESR (mb)'

AUX_ESR = 'Aux. ESR'
AUX_ESR_B = 'Aux. ESR (b)'
AUX_ESR_M = 'Aux. ESR (m)'
AUX_ESR_M_B = 'Aux. ESR (mb)'

INT_ESR = 'Int. ESR'
INT_ESR_B = 'Int. ESR (b)'
INT_ESR_M = 'Int. ESR (m)'
INT_ESR_M_B = 'Int. ESR (mb)'


backtest_mapping = {
    'cc_pvalue_twosided_general': GENERAL_CC,
    'cc_pvalue_twosided_simple': SIMPLE_CC,
    'er_pvalue_twosided_standardized': STD_ER,
    'er_pvalue_twosided_simple': ER,

    'cc_pvalue_onesided_general': GENERAL_CC,
    'cc_pvalue_onesided_simple': SIMPLE_CC,
    'er_pvalue_onesided_standardized': STD_ER,
    'er_pvalue_onesided_simple': ER,

    'esr1_pvalue_twosided_asymptotic': STR_ESR,
    'esr1_pvalue_twosided_bootStr.ap': STR_ESR_B,
    'esr1_misspec_pvalue_twosided_asymptotic': STR_ESR_M,
    'esr1_misspec_pvalue_twosided_bootStr.ap': STR_ESR_M_B,

    'esr2_pvalue_twosided_asymptotic': AUX_ESR,
    'esr2_pvalue_twosided_bootStr.ap': AUX_ESR_B,
    'esr2_misspec_pvalue_twosided_asymptotic': AUX_ESR_M,
    'esr2_misspec_pvalue_twosided_bootStr.ap': AUX_ESR_M_B,

    'esr3_pvalue_twosided_asymptotic': INT_ESR,
    'esr3_pvalue_twosided_bootstrap': INT_ESR_B,
    'esr3_misspec_pvalue_twosided_asymptotic': INT_ESR_M,
    'esr3_misspec_pvalue_twosided_bootstrap': INT_ESR_M_B,

    'esr3_pvalue_onesided_asymptotic': INT_ESR,
    'esr3_pvalue_onesided_bootStr.ap': INT_ESR_B,
    'esr3_misspec_pvalue_onesided_asymptotic': INT_ESR_M,
    'esr3_misspec_pvalue_onesided_bootStr.ap': INT_ESR_M_B,
}


rc_dict = {
    'font.family': 'serif',
    'axes.labelsize': 7,
    'axes.titlesize': 7,
    'font.size': 7,
    'legend.fontsize': 7,
    'xtick.labelsize': 7,
    'ytick.labelsize': 7,
    'lines.markersize': 5,
    'text.usetex': True,
    'text.latex.preamble': [
        r'\PassOptionsToPackage{full}{textcomp}',
        r'\usepackage{newtxtext}',
        r'\usepackage[smallerops]{newtxmath}'
    ]
}


dgp_mapping = {
    'ar1_garch11_normal_ar0.0': 'AR-GARCH, $\\phi=0.0$',
    'ar1_garch11_normal_ar0.1': 'AR-GARCH, $\\phi=0.1$',
    'ar1_garch11_normal_ar0.3': 'AR-GARCH, $\\phi=0.3$',
    'ar1_garch11_normal_ar0.5': 'AR-GARCH, $\\phi=0.5$',
    'egarch_t_calibrated': 'EGARCH-STD',
    'gas_sstd_calibrated': 'GAS-SSTD',
    'gas_std_calibrated': 'GAS-STD'
}

colors = sns.color_palette(n_colors=7)

color_marker_mapping = {}

color_marker_mapping[STR_ESR_M] = {'color': colors[0], 'marker': 's'}
color_marker_mapping[AUX_ESR_M] = {'color': colors[1], 'marker': 'D'}
color_marker_mapping[INT_ESR_M] = {'color': colors[2], 'marker': 'P'}


color_marker_mapping[GENERAL_CC] = {'color': colors[3], 'marker': '<'}
color_marker_mapping[SIMPLE_CC] = {'color': colors[4], 'marker': '>'}

color_marker_mapping[STD_ER] = {'color': colors[5], 'marker': '^'}
color_marker_mapping[ER] = {'color': colors[6], 'marker': 'v'}


def get_color(backtest):
    return color_marker_mapping[backtest]['color']


def get_marker(backtest):
    return color_marker_mapping[backtest]['marker']