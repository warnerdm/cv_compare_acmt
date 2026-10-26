"""Figures for method 1 (matplotlib versions of R steps 04-06): worked example, shares by stratum, lake-wide density."""
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from .estimate import acoustic_units, trawl_cells
from .trawl import tow_props, tow_props_all, LAYERS
from .paths import YEAR, ACOUSTIC_DESC, TRAWL_YEARS

GROUP_ORDER = ["alewife", "smelt", "bloater"]
UNIT_ORDER = ["nn", "no", "wn", "sn", "so", "Lake-wide"]
SOURCE_COLOURS = {"acoustic": "steelblue", "trawl": "darkorange", "product": "grey"}
PLATFORM_STYLE = {"ships": ("#1f4e9c", "o"), "saildrone": ("#2ca25f", "^")}
_rng = np.random.default_rng(1)


def _jitter(n, width):
    return _rng.uniform(-width, width, n)


def worked_example(stratum: str = "sn", group: str = "bloater", path=None) -> dict:
    """Method 1 step by step for one stratum and species (R step 04). Returns the numbers drawn."""
    au = acoustic_units()
    au = au[au["stratum"] == stratum]
    tp, tp_all = tow_props(), tow_props_all()
    tr = trawl_cells(tp, tp_all)
    tr = tr[(tr["stratum"] == stratum) & (tr["group"] == group)].set_index("layer").reindex(LAYERS)
    x = {lv: i for i, lv in enumerate(LAYERS)}

    fig, axs = plt.subplots(2, 2, figsize=(14, 9))
    (aA, aB), (aC, aD) = axs

    # A: acoustic units
    rho = au.groupby("layer")["fish_ha"].agg(rho="mean", sd=lambda v: v.std(ddof=1), n="size").reindex(LAYERS)
    rho["se"] = rho["sd"] / np.sqrt(rho["n"])
    for pf, (col, mk) in PLATFORM_STYLE.items():
        s = au[au["platform"] == pf]
        aA.scatter(s["layer"].map(x) + _jitter(len(s), 0.1), s["fish_ha"], c=col, marker=mk, alpha=0.8, s=20, label=pf)
    for lv, r in rho.iterrows():
        aA.errorbar(x[lv] + 0.28, r["rho"], yerr=r["se"], fmt="o", color="black", capsize=0)
        aA.text(x[lv] + 0.45, r["rho"], f"rho = {r['rho']:.0f}\nSE {r['se']:.0f} (n = {int(r['n'])})", va="center", fontsize=8)
    aA.set_xticks(range(len(LAYERS)), LAYERS)
    aA.set_xlim(-0.5, len(LAYERS) + 0.3)
    aA.set(xlabel="Depth layer", ylabel="Fish/ha (all species)")
    aA.set_title("A. Acoustics: each point is one transect or drone-night\n"
                 f"rho = mean of units ({ACOUSTIC_DESC}); SE = SD / sqrt(units)", loc="left", fontsize=10)
    aA.legend(frameon=False, loc="upper right")

    # B: tows (the stratum's tows this year above 40 m; all pooled years' deep tows lake-wide)
    B = pd.concat([tp[(tp["layer"] == LAYERS[0]) & (tp["stratum"] == stratum)], tp_all[tp_all["layer"] == LAYERS[1]]])
    aB.scatter(B["layer"].map(x) + _jitter(len(B), 0.1), B["p_" + group], c="darkorange", alpha=0.8, s=20)
    for lv, r in tr.iterrows():
        lo, hi = max(0, r["p"] - r["se_p"]), min(1, r["p"] + r["se_p"])
        aB.errorbar(x[lv] + 0.28, r["p"], yerr=[[r["p"] - lo], [hi - r["p"]]], fmt="o", color="black", capsize=0)
        if lv == LAYERS[0]:
            lab = (f"p = {r['p']:.2f} ({int(r['tows'])} tows)\nSD = {r['sd']:.2f}: pooled within-year,\n"
                   f"  {int(r['years'])} years, df {int(r['df'])}\n"
                   f"SE = {r['sd']:.2f} / sqrt({int(r['tows'])}) = {r['se_p']:.2f}")
        else:
            lab = (f"p = {r['p']:.2f} (all years, lake-wide)\n"
                   f"SE = {r['sd']:.2f} / sqrt({int(r['tows'])}) = {r['se_p']:.2f}")
        aB.text(x[lv] + 0.45, r["p"], lab, va="center", fontsize=8)
    aB.set_xticks(range(len(LAYERS)), LAYERS)
    aB.set_xlim(-0.5, len(LAYERS) + 0.6)
    aB.set_ylim(0, 1.05)
    aB.set(xlabel="Depth layer (tow fishing depth)", ylabel=f"Proportion {group}")
    y0, y1 = min(TRAWL_YEARS), max(TRAWL_YEARS)
    aB.set_title(f"B. Trawl: each point is one tow\n< 40 m: {stratum}'s {YEAR} tows, SD pooled {y0}-{y1}; "
                 f">= 40 m: all {y0}-{y1} deep tows, lake-wide", loc="left", fontsize=10)

    # C: unit species density with p fixed
    pl = tr["p"]
    C = (au.assign(x=au["fish_ha"] * au["layer"].map(pl))
           .groupby(["platform", "Region_name"])["x"].sum().rename("d_u").reset_index())
    Dm = C["d_u"].mean()
    var_ac = C["d_u"].var(ddof=1) / len(C)
    for pf, (col, mk) in PLATFORM_STYLE.items():
        s = C[C["platform"] == pf]
        aC.scatter(_jitter(len(s), 0.08), s["d_u"], c=col, marker=mk, alpha=0.8, s=20, label=pf)
    aC.errorbar(0.2, Dm, yerr=np.sqrt(var_ac), fmt="o", color="black", capsize=0)
    aC.text(0.3, Dm, f"D = {Dm:.0f}\nacoustic SE {np.sqrt(var_ac):.0f}", va="center", fontsize=8)
    aC.set_xticks([0], ["units"])
    aC.set_xlim(-0.6, 0.8)
    aC.set_ylabel(f"{group} / ha")
    aC.set_title(f"C. Species density per unit\nD_u = rho_upper,u x {pl[LAYERS[0]]:.2f} + "
                 f"rho_lower,u x {pl[LAYERS[1]]:.2f}", loc="left", fontsize=10)
    aC.legend(frameon=False, loc="upper right")

    # D: variance contributions
    var_tr = float((rho["rho"] ** 2 * tr["se_p"] ** 2).sum())
    var_x = float((rho["se"] ** 2 * tr["se_p"] ** 2).sum())
    tot = var_ac + var_tr + var_x
    terms = [("acoustic", var_ac, "var(D_u) / units"), ("trawl", var_tr, "sum over layers of\nrho^2 x SE(p)^2"),
             ("product", var_x, "sum over layers of\nSE(rho)^2 x SE(p)^2")]
    for i, (name, val, how) in enumerate(terms):
        aD.bar(i, val, width=0.6, color=SOURCE_COLOURS[name])
        aD.text(i, val, f"{how}\n{val:.0f} ({100 * val / tot:.0f}%)", ha="center", va="bottom", fontsize=8)
    aD.set_xticks(range(3), [t[0] for t in terms])
    aD.set_ylim(0, max(t[1] for t in terms) * 1.35)
    aD.set_ylabel(f"Contribution to the variance of\nspecies density, ({group}/ha)^2")
    aD.set_title("D. Add the variance contributions (all in density units)\n"
                 f"Var = {tot:.0f}; SE = {np.sqrt(tot):.0f}; CV = {np.sqrt(tot):.0f} / {Dm:.0f} = "
                 f"{100 * np.sqrt(tot) / Dm:.0f}%", loc="left", fontsize=10)
    aD.text(0, -0.12, "Trawl bar = the proportion's variance converted to density units (x rho^2); "
            "product = both uncertainties together.", transform=aD.transAxes, fontsize=7)

    fig.suptitle(f"Method 1 step by step: {group} in stratum {stratum}, Lake Michigan {YEAR} "
                 f"({ACOUSTIC_DESC})\n"
                 "Species density D = rho_upper x p_upper + rho_lower x p_deep (layers split at 40 m)", x=0.01, ha="left")
    fig.tight_layout()
    if path is not None:
        fig.savefig(path, dpi=150)
    plt.close(fig)
    return {"D": Dm, "var_ac": var_ac, "var_tr": var_tr, "var_x": var_x, "se": np.sqrt(tot), "cv": np.sqrt(tot) / Dm}


def shares_by_stratum(stratum: pd.DataFrame, lake: pd.DataFrame, path=None):
    """Share of the variance from acoustics, trawl and product, by stratum and lake-wide (R step 05)."""
    st = stratum.rename(columns={"stratum": "unit", "cv_D": "cv"})
    d = pd.concat([st, lake.assign(unit="Lake-wide")], ignore_index=True)
    fig, axs = plt.subplots(1, len(UNIT_ORDER), figsize=(13, 4.8), sharey=True)
    for ax, u in zip(axs, UNIT_ORDER):
        s = d[d["unit"] == u].set_index("group").reindex(GROUP_ORDER)
        bottom = np.zeros(len(s))
        for src in SOURCE_COLOURS:
            ax.bar(range(len(s)), s["share_" + src], 0.7, bottom=bottom, color=SOURCE_COLOURS[src], label=src)
            bottom += s["share_" + src].to_numpy()
        for i, cv in enumerate(s["cv"]):
            ax.text(i, 1.03, f"CV\n{100 * cv:.0f}%", ha="center", fontsize=7)
        ax.set_title(u, fontsize=10, backgroundcolor="0.92")
        ax.set_xticks(range(len(s)), GROUP_ORDER, rotation=30, ha="right")
        ax.set_ylim(0, 1.15)
        ax.set_yticks([0, 0.5, 1])
    axs[0].set_ylabel("Share of the variance of species density")
    h, l = axs[0].get_legend_handles_labels()
    fig.legend(h, l, title="Source", loc="lower center", ncol=3, frameon=False, bbox_to_anchor=(0.5, 0.06))
    fig.suptitle(f"Lake Michigan {YEAR}: where the uncertainty in species density comes from, by stratum\n"
                 "Relative contribution of each gear to the variance of each species' density (bars sum to 1). "
                 "Label = CV, for context.", x=0.01, ha="left", fontsize=10)
    fig.text(0.01, 0.01, ACOUSTIC_DESC[0].upper() + ACOUSTIC_DESC[1:] + "; trawl by stratum above 40 m, lake-wide below. "
             "Large CVs = species nearly absent from that stratum.", fontsize=8)
    fig.tight_layout(rect=(0, 0.12, 1, 1))
    if path is not None:
        fig.savefig(path, dpi=150)
    plt.close(fig)


def lake_density(lake: pd.DataFrame, path=None):
    """Lake-wide mean density per species, thick bar +-1 SE, thin bar ~95% (+-1.96 SE, truncated at 0) (R step 06)."""
    lk = lake.set_index("group").reindex(GROUP_ORDER)
    cols = {"alewife": "magenta", "smelt": "grey", "bloater": "0.15"}
    fig, ax = plt.subplots(figsize=(6.5, 5))
    for i, (g, r) in enumerate(lk.iterrows()):
        lo, hi = max(0, r["density"] - 1.96 * r["se_density"]), r["density"] + 1.96 * r["se_density"]
        ax.bar(i, r["density"], 0.6, color=cols[g], alpha=0.45)
        ax.errorbar(i, r["density"], yerr=[[r["density"] - lo], [hi - r["density"]]], fmt="none", color="black",
                    capsize=6, linewidth=0.8)
        ax.errorbar(i, r["density"], yerr=r["se_density"], fmt="none", color="black", capsize=0, linewidth=3)
        ax.text(i, hi, f"{r['density']:.0f} fish/ha\nCV {100 * r['cv']:.0f}%", ha="center", va="bottom", fontsize=9)
    ax.set_xticks(range(len(lk)), GROUP_ORDER)
    ax.set_ylim(0, (lk["density"] + 1.96 * lk["se_density"]).max() * 1.15)
    ax.set_ylabel("Lake-wide mean density (fish/ha)")
    ax.set_title(f"Lake Michigan {YEAR}: lake-wide mean density by species\n"
                 "Thick bar = +-1 SE; thin bar = approximate 95% interval (+-1.96 SE).\n"
                 "Method 1: acoustic + trawl uncertainty combined.", loc="left", fontsize=10)
    fig.text(0.01, 0.01, ACOUSTIC_DESC[0].upper() + ACOUSTIC_DESC[1:] + "; area-weighted over the five strata. All sizes, by number.",
             fontsize=8)
    fig.tight_layout(rect=(0, 0.03, 1, 1))
    if path is not None:
        fig.savefig(path, dpi=150)
    plt.close(fig)


def lake_shares_years(path=None) -> pd.DataFrame:
    """Lake-wide shares of the variance across years (R step 07), from output/python/method1_lake_<year>.csv of every
    year that has one (run run_method1.py for each YEAR first)."""
    from .paths import ACOUSTIC_FILES, OUTPUT_DIR
    years = [y for y in sorted(ACOUSTIC_FILES) if (OUTPUT_DIR / f"method1_lake_{y}.csv").exists()]
    d = pd.concat([pd.read_csv(OUTPUT_DIR / f"method1_lake_{y}.csv").assign(year=y) for y in years], ignore_index=True)
    fig, axs = plt.subplots(1, len(GROUP_ORDER), figsize=(11, 5.2), sharey=True)
    for ax, g in zip(axs, GROUP_ORDER):
        s = d[d["group"] == g].set_index("year").reindex(years)
        bottom = np.zeros(len(s))
        for src in SOURCE_COLOURS:
            ax.bar(range(len(s)), s["share_" + src], 0.7, bottom=bottom, color=SOURCE_COLOURS[src], label=src)
            bottom += s["share_" + src].to_numpy()
        for i, (cv, dens) in enumerate(zip(s["cv"], s["density"])):
            ax.text(i, 1.05, f"CV {100 * cv:.0f}%\n{dens:.0f}/ha", ha="center", va="bottom", fontsize=8)
        labs = [f"{y}\n{'ship + saildrone' if len(ACOUSTIC_FILES[y]) > 1 else 'ship'}" for y in years]
        ax.set_xticks(range(len(s)), labs, fontsize=8)
        ax.set_title(g, fontsize=10, backgroundcolor="0.92")
        ax.set_ylim(0, 1.2)
        ax.set_yticks([0, 0.5, 1])
    axs[0].set_ylabel("Share of the variance of lake-wide density")
    h, l = axs[0].get_legend_handles_labels()
    fig.legend(h, l, title="Source", loc="lower center", ncol=3, frameon=False, bbox_to_anchor=(0.5, 0.08))
    fig.suptitle(f"Lake Michigan {min(years)}-{max(years)}: where the uncertainty in lake-wide species density comes from\n"
                 "Relative contribution of each gear (bars sum to 1). Label = CV and lake-wide mean density, for context.",
                 x=0.01, ha="left", fontsize=10)
    fig.text(0.01, 0.01, "Acoustic units per year: 2021 ship transects + saildrone drone-nights (103); other years ship "
             f"transects only (20-26).\nTrawl: each year's stratum proportions above 40 m with the between-tow SD pooled "
             f"over {min(TRAWL_YEARS)}-{max(TRAWL_YEARS)}; deep proportion from all years' deep tows.", fontsize=8)
    fig.tight_layout(rect=(0, 0.16, 1, 1))
    if path is not None:
        fig.savefig(path, dpi=150)
    plt.close(fig)
    return d
