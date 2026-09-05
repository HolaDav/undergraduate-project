#!/usr/bin/env python3
"""
Group comparison analysis: AD vs YC Centiloid values.
Reads results/tables/suvr_centiloid_summary.csv, produces:
- descriptive statistics table
- normality tests
- appropriate group comparison test + effect size
- boxplot/stripplot figure
"""

import pandas as pd
import numpy as np
from scipy import stats
import matplotlib.pyplot as plt

# --- Load data ---
df = pd.read_csv('results/tables/suvr_centiloid_summary.csv')
ad = df[df['group'] == 'AD']['centiloid'].values
yc = df[df['group'] == 'YC']['centiloid'].values

print(f"AD group: n={len(ad)}")
print(f"YC group: n={len(yc)}")
print()

# --- Descriptive statistics ---
def describe(arr, label):
    return {
        'group': label,
        'n': len(arr),
        'mean': round(np.mean(arr), 2),
        'sd': round(np.std(arr, ddof=1), 2),
        'median': round(np.median(arr), 2),
        'min': round(np.min(arr), 2),
        'max': round(np.max(arr), 2),
    }

desc_ad = describe(ad, 'AD')
desc_yc = describe(yc, 'YC')
desc_df = pd.DataFrame([desc_ad, desc_yc])
print("Descriptive statistics:")
print(desc_df.to_string(index=False))
print()

# --- Normality tests (Shapiro-Wilk) ---
sw_ad = stats.shapiro(ad)
sw_yc = stats.shapiro(yc)
print(f"Shapiro-Wilk normality test:")
print(f"  AD: W={sw_ad.statistic:.4f}, p={sw_ad.pvalue:.4f} -> {'normal' if sw_ad.pvalue > 0.05 else 'NOT normal'}")
print(f"  YC: W={sw_yc.statistic:.4f}, p={sw_yc.pvalue:.4f} -> {'normal' if sw_yc.pvalue > 0.05 else 'NOT normal'}")
print()

both_normal = (sw_ad.pvalue > 0.05) and (sw_yc.pvalue > 0.05)

# --- Group comparison ---
if both_normal:
    # Levene's test for equal variance
    levene = stats.levene(ad, yc)
    equal_var = levene.pvalue > 0.05
    test_result = stats.ttest_ind(ad, yc, equal_var=equal_var)
    test_name = f"Independent-samples t-test ({'equal' if equal_var else 'unequal'} variance)"
    stat_val = test_result.statistic
    p_val = test_result.pvalue
    # Cohen's d
    pooled_sd = np.sqrt(((len(ad)-1)*np.var(ad, ddof=1) + (len(yc)-1)*np.var(yc, ddof=1)) / (len(ad)+len(yc)-2))
    effect_size = (np.mean(ad) - np.mean(yc)) / pooled_sd
    effect_name = "Cohen's d"
else:
    test_result = stats.mannwhitneyu(ad, yc, alternative='two-sided')
    test_name = "Mann-Whitney U test (non-parametric)"
    stat_val = test_result.statistic
    p_val = test_result.pvalue
    # Rank-biserial correlation as effect size
    n1, n2 = len(ad), len(yc)
    effect_size = 1 - (2*stat_val) / (n1*n2)
    effect_name = "Rank-biserial correlation"

print(f"Group comparison test: {test_name}")
print(f"  Statistic = {stat_val:.4f}")
print(f"  p-value = {p_val:.2e}")
print(f"  {effect_name} = {effect_size:.4f}")

# 95% CI for mean difference (only meaningful/reported for the t-test case)
ci_lower = ci_upper = mean_diff = None
if both_normal:
    mean_diff = np.mean(ad) - np.mean(yc)
    var1, var2 = np.var(ad, ddof=1), np.var(yc, ddof=1)
    se_diff = np.sqrt(var1/len(ad) + var2/len(yc))
    df_welch = (var1/len(ad) + var2/len(yc))**2 / (
        (var1/len(ad))**2/(len(ad)-1) + (var2/len(yc))**2/(len(yc)-1))
    t_crit = stats.t.ppf(0.975, df_welch)
    ci_lower = mean_diff - t_crit * se_diff
    ci_upper = mean_diff + t_crit * se_diff
    print(f"  Mean difference (AD - YC) = {mean_diff:.2f} CL")
    print(f"  95% CI of mean difference = [{ci_lower:.2f}, {ci_upper:.2f}]")
print()

# --- Save results to text file ---
with open('results/tables/group_comparison_results.txt', 'w') as f:
    f.write("AD vs YC Centiloid Group Comparison\n")
    f.write("=" * 40 + "\n\n")
    f.write(f"AD group: n={len(ad)}\n")
    f.write(f"YC group: n={len(yc)}\n\n")
    f.write("Descriptive statistics:\n")
    f.write(desc_df.to_string(index=False) + "\n\n")
    f.write("Shapiro-Wilk normality test:\n")
    f.write(f"  AD: W={sw_ad.statistic:.4f}, p={sw_ad.pvalue:.4f} -> {'normal' if sw_ad.pvalue > 0.05 else 'NOT normal'}\n")
    f.write(f"  YC: W={sw_yc.statistic:.4f}, p={sw_yc.pvalue:.4f} -> {'normal' if sw_yc.pvalue > 0.05 else 'NOT normal'}\n\n")
    f.write(f"Group comparison test: {test_name}\n")
    f.write(f"  Statistic = {stat_val:.4f}\n")
    f.write(f"  p-value = {p_val:.2e}\n")
    f.write(f"  {effect_name} = {effect_size:.4f}\n")
    if mean_diff is not None:
        f.write(f"  Mean difference (AD - YC) = {mean_diff:.2f} CL\n")
        f.write(f"  95% CI of mean difference = [{ci_lower:.2f}, {ci_upper:.2f}]\n")

# --- Save descriptive table as CSV ---
desc_df.to_csv('results/tables/group_descriptive_stats.csv', index=False)

# --- Figure: boxplot + individual points ---
fig, ax = plt.subplots(figsize=(7, 6))

positions = [1, 2]
box_data = [ad, yc]
labels = [f'AD\n(n={len(ad)})', f'YC\n(n={len(yc)})']

bp = ax.boxplot(box_data, positions=positions, widths=0.5, patch_artist=True,
                 showfliers=False, medianprops=dict(color='black', linewidth=1.5))
colors = ['#e07b7b', '#7ba7e0']
for patch, color in zip(bp['boxes'], colors):
    patch.set_facecolor(color)
    patch.set_alpha(0.5)

# Jittered individual points
rng = np.random.default_rng(42)
for pos, data, color in zip(positions, box_data, colors):
    jitter = rng.uniform(-0.12, 0.12, size=len(data))
    ax.scatter(np.full(len(data), pos) + jitter, data, color=color, edgecolor='black',
               linewidth=0.4, s=30, zorder=3, alpha=0.8)

ax.axhline(0, color='gray', linestyle='--', linewidth=0.8, zorder=1)
ax.axhline(100, color='gray', linestyle=':', linewidth=0.8, zorder=1)
ax.text(2.55, 1, '0 CL (YC-0 anchor)', fontsize=8, color='gray', va='bottom')
ax.text(2.55, 101, '100 CL (AD-100 anchor)', fontsize=8, color='gray', va='bottom')

ax.set_xticks(positions)
ax.set_xticklabels(labels)
ax.set_ylabel('Centiloid (CL)')
ax.set_title('Amyloid Burden by Group: AD vs YC (n=79)')

sig_text = f"p = {p_val:.2e}" if p_val >= 0.0001 else "p < 0.0001"
ax.text(1.5, ax.get_ylim()[1]*0.95, sig_text, ha='center', fontsize=10, style='italic')

plt.tight_layout()
plt.savefig('results/figures/ad_vs_yc_centiloid_comparison.png', dpi=200)
print("Figure saved: results/figures/ad_vs_yc_centiloid_comparison.png")
print("Results text saved: results/tables/group_comparison_results.txt")
print("Descriptive stats saved: results/tables/group_descriptive_stats.csv")
