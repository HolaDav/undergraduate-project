#!/usr/bin/env python3

"""
Publication-quality performance figures
Figure 4.5 Runtime Distribution
Figure 4.6 Runtime Comparison (AD vs YC)
Figure 4.7 RAM Utilisation Distribution
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import re

# --------------------------------------------------
# Load Runtime Data
# --------------------------------------------------

runtime = pd.read_csv("logs/runtime_tracking.csv")

runtime = runtime[
    runtime["status"].str.contains("Pass", na=False)
].copy()

runtime["runtime_minutes"] = pd.to_numeric(
    runtime["runtime_minutes"],
    errors="coerce"
)

runtime = runtime.dropna(
    subset=["runtime_minutes"]
)

runtime["group"] = runtime["participant_id"].apply(
    lambda x: "AD" if "AD" in x else "YC"
)

# --------------------------------------------------
# Runtime Statistics
# --------------------------------------------------

runtime_mean = runtime["runtime_minutes"].mean()
runtime_median = runtime["runtime_minutes"].median()
runtime_p95 = np.percentile(
    runtime["runtime_minutes"],
    95
)

# ==================================================
# FIGURE 4.5
# Runtime Distribution
# ==================================================

fig, ax = plt.subplots(
    figsize=(8, 6)
)

ax.hist(
    runtime["runtime_minutes"],
    bins=18,
    color="#7da7d9",
    edgecolor="black",
    alpha=0.85
)

ax.axvline(
    runtime_mean,
    color="red",
    linestyle="--",
    linewidth=2,
    label=f"Mean = {runtime_mean:.1f} min"
)

ax.axvline(
    runtime_median,
    color="black",
    linestyle="-.",
    linewidth=2,
    label=f"Median = {runtime_median:.1f} min"
)

ax.axvline(
    runtime_p95,
    color="green",
    linestyle=":",
    linewidth=2,
    label=f"95th percentile = {runtime_p95:.1f} min"
)

ax.set_title(
    f"Distribution of Processing Times (n={len(runtime)})",
    fontsize=16,
    pad=12
)

ax.set_xlabel(
    "Processing Time per Subject (minutes)",
    fontsize=12
)

ax.set_ylabel(
    "Number of Subjects",
    fontsize=12
)

ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)

ax.grid(
    axis="y",
    alpha=0.2
)

ax.legend()

plt.tight_layout()

plt.savefig(
    "results/figures/fig4_5_runtime_distribution.png",
    dpi=600,
    bbox_inches="tight"
)

plt.close()

print("Saved Figure 4.5")

# ==================================================
# FIGURE 4.6
# Runtime by Group
# ==================================================

ad_runtime = runtime[
    runtime["group"] == "AD"
]["runtime_minutes"].values

yc_runtime = runtime[
    runtime["group"] == "YC"
]["runtime_minutes"].values

fig, ax = plt.subplots(
    figsize=(8, 7)
)

positions = [1, 2]

violins = ax.violinplot(
    [ad_runtime, yc_runtime],
    positions=positions,
    widths=0.7,
    showmeans=False,
    showmedians=False,
    showextrema=False
)

colors = [
    "#d97b7b",
    "#7da7d9"
]

for body, color in zip(
    violins["bodies"],
    colors
):
    body.set_facecolor(color)
    body.set_alpha(0.25)
    body.set_edgecolor(color)

bp = ax.boxplot(
    [ad_runtime, yc_runtime],
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
    colors
):
    patch.set_facecolor(color)
    patch.set_alpha(0.6)

rng = np.random.default_rng(42)

for pos, data, color in zip(
    positions,
    [ad_runtime, yc_runtime],
    colors
):

    jitter = rng.normal(
        0,
        0.05,
        len(data)
    )

    ax.scatter(
        np.full(len(data), pos) + jitter,
        data,
        s=40,
        color=color,
        edgecolor="black",
        linewidth=0.4,
        alpha=0.85,
        zorder=5
    )

means = [
    np.mean(ad_runtime),
    np.mean(yc_runtime)
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

ax.set_xticks(
    positions
)

ax.set_xticklabels(
    [
        f"AD\n(n={len(ad_runtime)})",
        f"YC\n(n={len(yc_runtime)})"
    ],
    fontsize=12
)

ax.set_ylabel(
    "Processing Time (minutes)",
    fontsize=12
)

ax.set_title(
    "Processing Time by Subject Group",
    fontsize=16,
    pad=12
)

ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)

ax.grid(
    axis="y",
    alpha=0.2
)

plt.tight_layout()

plt.savefig(
    "results/figures/fig4_6_runtime_by_group.png",
    dpi=600,
    bbox_inches="tight"
)

plt.close()

print("Saved Figure 4.6")

# --------------------------------------------------
# Load RAM Data
# --------------------------------------------------

resource = pd.read_csv(
    "logs/resource_tracking.csv"
)

def parse_ram(value):

    if pd.isna(value):
        return np.nan

    value = str(value)

    if (
        "not_recorded" in value
        or value == "N/A"
    ):
        return np.nan

    match = re.match(
        r"^\s*([\d.]+)",
        value
    )

    if match:
        return float(
            match.group(1)
        )

    return np.nan

resource["ram_gb"] = resource[
    "max_ram_gb"
].apply(parse_ram)

resource = resource.dropna(
    subset=["ram_gb"]
)

# --------------------------------------------------
# RAM Statistics
# --------------------------------------------------

ram_mean = resource["ram_gb"].mean()

ram_median = resource["ram_gb"].median()

q1 = resource["ram_gb"].quantile(0.25)

q3 = resource["ram_gb"].quantile(0.75)

# ==================================================
# FIGURE 4.7
# RAM Utilisation
# ==================================================

fig, ax = plt.subplots(
    figsize=(8, 6)
)

ax.hist(
    resource["ram_gb"],
    bins=12,
    color="#8fbc8f",
    edgecolor="black",
    alpha=0.85
)

ax.axvline(
    ram_mean,
    color="red",
    linestyle="--",
    linewidth=2,
    label=f"Mean = {ram_mean:.2f} GB"
)

ax.axvline(
    ram_median,
    color="black",
    linestyle="-.",
    linewidth=2,
    label=f"Median = {ram_median:.2f} GB"
)

ax.axvspan(
    q1,
    q3,
    alpha=0.2,
    color="gray",
    label="IQR"
)

ax.set_title(
    f"Memory Utilisation During Processing (n={len(resource)})",
    fontsize=16,
    pad=12
)

ax.set_xlabel(
    "Peak RAM Usage (GB)",
    fontsize=12
)

ax.set_ylabel(
    "Number of Subjects",
    fontsize=12
)

ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)

ax.grid(
    axis="y",
    alpha=0.2
)

ax.legend()

plt.tight_layout()

plt.savefig(
    "results/figures/fig4_7_resource_utilisation.png",
    dpi=600,
    bbox_inches="tight"
)

plt.close()

print("Saved Figure 4.7")

print("\nAll publication-quality performance figures generated.")
