#!/usr/bin/env python3

# --------------------------------------------------
# PUBLICATION-QUALITY AD vs YC CENTILOID FIGURE
# --------------------------------------------------

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy import stats

# -----------------------------
# Load data
# -----------------------------
df = pd.read_csv("results/tables/suvr_centiloid_summary.csv")

ad = df[df["group"] == "AD"]["centiloid"].values
yc = df[df["group"] == "YC"]["centiloid"].values

# -----------------------------
# Statistics
# -----------------------------
t_stat, p_val = stats.ttest_ind(
    ad,
    yc,
    equal_var=False
)

pooled_sd = np.sqrt(
    (
        ((len(ad)-1) * np.var(ad, ddof=1))
        +
        ((len(yc)-1) * np.var(yc, ddof=1))
    )
    /
    (len(ad) + len(yc) - 2)
)

cohens_d = (
    np.mean(ad) - np.mean(yc)
) / pooled_sd

# -----------------------------
# Figure setup
# -----------------------------
plt.style.use("default")

fig, ax = plt.subplots(
    figsize=(8, 7),
    dpi=300
)

positions = [1, 2]

# -----------------------------
# Violin plots
# -----------------------------
violins = ax.violinplot(
    [ad, yc],
    positions=positions,
    widths=0.7,
    showmeans=False,
    showmedians=False,
    showextrema=False
)

violin_colors = [
    "#d97b7b",   # AD
    "#7da7d9"    # YC
]

for body, color in zip(
    violins["bodies"],
    violin_colors
):
    body.set_facecolor(color)
    body.set_edgecolor(color)
    body.set_alpha(0.25)

# -----------------------------
# Boxplots
# -----------------------------
bp = ax.boxplot(
    [ad, yc],
    positions=positions,
    widths=0.25,
    patch_artist=True,
    showfliers=False,
    medianprops=dict(
        color="black",
        linewidth=2
    )
)

for patch, color in zip(
    bp["boxes"],
    violin_colors
):
    patch.set_facecolor(color)
    patch.set_alpha(0.6)

# -----------------------------
# Individual subjects
# -----------------------------
rng = np.random.default_rng(42)

for pos, data, color in zip(
    positions,
    [ad, yc],
    violin_colors
):

    jitter = rng.normal(
        loc=0,
        scale=0.05,
        size=len(data)
    )

    ax.scatter(
        np.full(len(data), pos) + jitter,
        data,
        s=45,
        color=color,
        edgecolor="black",
        linewidth=0.4,
        alpha=0.85,
        zorder=5
    )

# -----------------------------
# Mean markers
# -----------------------------
means = [
    np.mean(ad),
    np.mean(yc)
]

ax.scatter(
    positions,
    means,
    marker="D",
    s=90,
    color="black",
    zorder=10,
    label="Mean"
)

# -----------------------------
# Centiloid anchors
# -----------------------------
ax.axhline(
    0,
    color="gray",
    linestyle="--",
    linewidth=1
)

ax.axhline(
    100,
    color="gray",
    linestyle=":",
    linewidth=1
)

ax.text(
    2.60,
    0,
    "0 CL (YC anchor)",
    fontsize=10,
    color="gray",
    va="bottom"
)

ax.text(
    2.60,
    100,
    "100 CL (AD anchor)",
    fontsize=10,
    color="gray",
    va="bottom"
)

# -----------------------------
# Significance bracket
# -----------------------------
y_max = max(
    np.max(ad),
    np.max(yc)
)

bracket_height = y_max + 8

ax.plot(
    [1, 1, 2, 2],
    [
        bracket_height - 2,
        bracket_height,
        bracket_height,
        bracket_height - 2
    ],
    color="black",
    linewidth=1.8
)

ax.text(
    1.5,
    bracket_height + 1.2,
    "p < 0.0001",
    ha="center",
    fontsize=13,
    fontweight="bold"
)

# -----------------------------
# Effect size
# -----------------------------
ax.text(
    1.5,
    bracket_height - 6,
    f"Cohen's d = {cohens_d:.2f}",
    ha="center",
    fontsize=11,
    style="italic"
)

# -----------------------------
# Labels
# -----------------------------
ax.set_xticks(
    positions
)

ax.set_xticklabels(
    [
        f"AD\n(n={len(ad)})",
        f"YC\n(n={len(yc)})"
    ],
    fontsize=12
)

ax.set_ylabel(
    "Centiloid (CL)",
    fontsize=13
)

ax.set_title(
    f"Amyloid Burden by Group: AD vs YC (n={len(ad)+len(yc)})",
    fontsize=18,
    pad=18
)

# -----------------------------
# Appearance
# -----------------------------
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)

ax.grid(
    axis="y",
    alpha=0.20
)

ax.set_xlim(
    0.5,
    2.9
)

# Small amount of headroom
ax.set_ylim(
    min(np.min(yc), np.min(ad)) - 8,
    bracket_height + 7
)

plt.tight_layout()

# -----------------------------
# Save figure
# -----------------------------
plt.savefig(
    "results/figures/ad_vs_yc_centiloid_publication.png",
    dpi=600,
    bbox_inches="tight"
)

plt.close()

print(
    "Saved: results/figures/ad_vs_yc_centiloid_publication.png"
)
