#!/usr/bin/env python3

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

from scipy.stats import mannwhitneyu

df = pd.read_csv("runtime_tracking.csv")

df["runtime_minutes"] = pd.to_numeric(
    df["runtime_minutes"],
    errors="coerce"
)

df = df.dropna(subset=["runtime_minutes"])

df["Group"] = df["participant_id"].apply(
    lambda x: "AD" if "AD" in x else "YC"
)

ad = df[df["Group"]=="AD"]["runtime_minutes"]
yc = df[df["Group"]=="YC"]["runtime_minutes"]

stat,p = mannwhitneyu(ad,yc)

plt.style.use("ggplot")

fig,ax = plt.subplots(figsize=(10,8))

palette = {
    "AD":"#D98282",
    "YC":"#86A9D4"
}

sns.violinplot(
    data=df,
    x="Group",
    y="runtime_minutes",
    palette=palette,
    inner=None,
    cut=0,
    alpha=0.35,
    ax=ax
)

sns.boxplot(
    data=df,
    x="Group",
    y="runtime_minutes",
    width=0.25,
    palette=palette,
    boxprops=dict(alpha=0.7),
    ax=ax
)

sns.stripplot(
    data=df,
    x="Group",
    y="runtime_minutes",
    palette=palette,
    size=9,
    jitter=0.15,
    edgecolor="black",
    linewidth=0.6,
    alpha=0.85,
    ax=ax
)

ad_mean = ad.mean()
yc_mean = yc.mean()

ax.scatter(
    [0,1],
    [ad_mean,yc_mean],
    marker="D",
    s=220,
    color="black",
    zorder=10
)

ax.text(
    0.03,
    ad_mean+0.3,
    f"{ad_mean:.1f} min",
    fontsize=12,
    fontweight="bold"
)

ax.text(
    1.03,
    yc_mean+0.3,
    f"{yc_mean:.1f} min",
    fontsize=12,
    fontweight="bold"
)

y_max = max(df["runtime_minutes"])

ax.plot(
    [0,0,1,1],
    [y_max+1,y_max+2,y_max+2,y_max+1],
    lw=2.5,
    c="black"
)

ax.text(
    0.5,
    y_max+2.4,
    f"p = {p:.4f}",
    ha="center",
    fontsize=16,
    fontweight="bold"
)

ax.set_title(
    "Processing Time by Subject Group",
    fontsize=22,
    fontweight="bold"
)

ax.set_xlabel("")
ax.set_ylabel(
    "Processing Time (minutes)",
    fontsize=16
)

ax.set_xticklabels([
    f"AD\n(n={len(ad)})",
    f"YC\n(n={len(yc)})"
], fontsize=16)

plt.tight_layout()
plt.savefig(
    "Figure_4_6_Runtime_Group_Comparison.png",
    dpi=600,
    bbox_inches="tight"
)

plt.show()
