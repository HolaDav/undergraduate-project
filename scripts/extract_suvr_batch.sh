#!/bin/bash
subjects="AD19 AD20 AD21 AD22 AD24 AD25"
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
