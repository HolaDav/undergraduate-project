#!/usr/bin/env python3
"""
Generate Figures 4.5-4.7 for Chapter 4: runtime and resource
utilisation summary figures, from actual logged data.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import re

# --- Load runtime data ---
runtime = pd.read_csv('logs/runtime_tracking.csv')
runtime = runtime[runtime['status'].str.contains('Pass', na=False)].copy()
runtime['runtime_minutes'] = pd.to_numeric(runtime['runtime_minutes'], errors='coerce')
runtime = runtime.dropna(subset=['runtime_minutes'])
runtime['group'] = runtime['participant_id'].apply(lambda x: 'AD' if 'AD' in x else 'YC')

print(f"Runtime records (valid, numeric): n={len(runtime)}")
print(runtime['runtime_minutes'].describe())
print()

# --- Figure 4.5: Distribution of processing times across subjects ---
fig, ax = plt.subplots(figsize=(8, 5))
ax.hist(runtime['runtime_minutes'], bins=20, color='#7ba7e0', edgecolor='black', alpha=0.8)
ax.axvline(runtime['runtime_minutes'].mean(), color='red', linestyle='--', linewidth=1.2,
           label=f"Mean = {runtime['runtime_minutes'].mean():.1f} min")
ax.axvline(runtime['runtime_minutes'].median(), color='black', linestyle=':', linewidth=1.2,
           label=f"Median = {runtime['runtime_minutes'].median():.1f} min")
ax.set_xlabel('Total processing time per subject (minutes)')
ax.set_ylabel('Number of subjects')
ax.set_title(f'Distribution of Processing Times Across All Subjects (n={len(runtime)})')
ax.legend()
plt.tight_layout()
plt.savefig('results/figures/fig4_5_runtime_distribution.png', dpi=200)
print("Figure 4.5 saved: fig4_5_runtime_distribution.png")

# --- Figure 4.6: Mean processing time by group (AD vs YC), NOT by module ---
# NOTE: per-module (Coregister/Segment/Normalise/Smooth) breakdown was not
# systematically logged per subject across the full dataset - only total
# runtime was recorded in runtime_tracking.csv. This figure therefore shows
# mean total runtime by subject group, not by processing stage, to avoid
# fabricating a per-stage breakdown that was not actually captured.
group_means = runtime.groupby('group')['runtime_minutes'].agg(['mean', 'std', 'count'])
print("\nGroup runtime summary:")
print(group_means)

fig, ax = plt.subplots(figsize=(6, 5))
groups = group_means.index.tolist()
means = group_means['mean'].values
stds = group_means['std'].values
colors = ['#e07b7b' if g == 'AD' else '#7ba7e0' for g in groups]
bars = ax.bar(groups, means, yerr=stds, capsize=6, color=colors, alpha=0.8, edgecolor='black')
for bar, m, n in zip(bars, means, group_means['count'].values):
    ax.text(bar.get_x() + bar.get_width()/2, m + 0.3, f"{m:.1f} min\n(n={n})",
            ha='center', fontsize=9)
ax.set_ylabel('Mean total processing time (minutes)')
ax.set_title('Mean Total Processing Time by Subject Group')
plt.tight_layout()
plt.savefig('results/figures/fig4_6_runtime_by_group.png', dpi=200)
print("Figure 4.6 saved: fig4_6_runtime_by_group.png")

# --- Figure 4.7: Resource utilisation (RAM) across the dataset ---
resource = pd.read_csv('logs/resource_tracking.csv')

def parse_ram(val):
    if pd.isna(val) or 'not_recorded' in str(val) or val == 'N/A':
        return np.nan
    match = re.match(r'^\s*([\d.]+)', str(val))
    return float(match.group(1)) if match else np.nan

resource['max_ram_numeric'] = resource['max_ram_gb'].apply(parse_ram)
resource_valid = resource.dropna(subset=['max_ram_numeric']).copy()
resource_valid['group'] = resource_valid['participant_id'].apply(lambda x: 'AD' if 'AD' in x else 'YC')

print(f"\nResource records (valid, numeric): n={len(resource_valid)} of {len(resource)} total logged")
print(resource_valid['max_ram_numeric'].describe())

fig, ax = plt.subplots(figsize=(8, 5))
ax.hist(resource_valid['max_ram_numeric'], bins=15, color='#8fbc8f', edgecolor='black', alpha=0.8)
ax.axvline(resource_valid['max_ram_numeric'].mean(), color='red', linestyle='--', linewidth=1.2,
           label=f"Mean = {resource_valid['max_ram_numeric'].mean():.2f} GB")
ax.set_xlabel('Peak RAM usage per subject (GB)')
ax.set_ylabel('Number of subjects')
ax.set_title(f'Memory (RAM) Utilisation During Processing (n={len(resource_valid)} measured)')
ax.legend()
plt.tight_layout()
plt.savefig('results/figures/fig4_7_resource_utilisation.png', dpi=200)
print("Figure 4.7 saved: fig4_7_resource_utilisation.png")

print(f"\nNOTE: {len(resource) - len(resource_valid)} of {len(resource)} subjects had")
print("no resource measurement recorded (not_recorded/N/A) - excluded from Figure 4.7,")
print("consistent with the documented resource-tracking limitation (see")
print("docs/methodology_decisions.md).")
