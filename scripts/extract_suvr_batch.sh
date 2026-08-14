#!/bin/bash
subjects="YC106 YC107 YC108 YC109 YC110 YC113 YC115 YC116 YC117 YC118 YC119 YC120 YC121 YC122 YC123 YC124 YC126 YC128 YC130 YC131 YC133 YC134"
base_dir="/home/jovyan/Desktop/workspace/undergraduate_project"
ctx_mask="$base_dir/masks/voi_ctx_2mm.nii"
cbl_mask="$base_dir/masks/voi_WhlCbl_2mm.nii"

echo "subject,cortex_mean,cerebellum_mean,suvr,centiloid"

for s in $subjects; do
  pet="$base_dir/rawdata/sub-${s}/pet/swsub-${s}_trc-pib_pet.nii"
  if [ ! -f "$pet" ]; then
    echo "sub-${s},MISSING,MISSING,MISSING,MISSING"
    continue
  fi
  ctx=$(fslstats "$pet" -k "$ctx_mask" -M)
  cbl=$(fslstats "$pet" -k "$cbl_mask" -M)
  suvr=$(python3 -c "print(round($ctx/$cbl, 4))")
  cl=$(python3 -c "print(round(100*(($ctx/$cbl)-1.009)/1.067, 2))")
  echo "sub-${s},$ctx,$cbl,$suvr,$cl"
done
