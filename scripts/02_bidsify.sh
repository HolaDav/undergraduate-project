#!/bin/bash

PROJECT=~/Desktop/workspace/undergraduate_project

echo "Renaming MRI files..."

find $PROJECT/rawdata -type f -name "*_MR.nii" | while read file
do
    sub=$(basename "$(dirname "$(dirname "$file")")")

    mv "$file" \
       "$(dirname "$file")/${sub}_T1w.nii"
done

echo "Renaming PET files..."

find $PROJECT/rawdata -type f -name "*_PiB_5070.nii" | while read file
do
    sub=$(basename "$(dirname "$(dirname "$file")")")

    mv "$file" \
       "$(dirname "$file")/${sub}_trc-pib_pet.nii"
done

echo "BIDS-style renaming complete."
