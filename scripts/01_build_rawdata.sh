#!/bin/bash

PROJECT=~/Desktop/workspace/undergraduate_project

# AD subjects
for mr in $PROJECT/sourcedata/AD-100_MR/nifti/*_MR.nii
do
    sub=$(basename "$mr" _MR.nii)

    mkdir -p $PROJECT/rawdata/sub-${sub}/anat
    mkdir -p $PROJECT/rawdata/sub-${sub}/pet

    cp "$mr" \
       $PROJECT/rawdata/sub-${sub}/anat/

    cp $PROJECT/sourcedata/AD-100_PET_5070/nifti/${sub}_PiB_5070.nii \
       $PROJECT/rawdata/sub-${sub}/pet/
done

# YC subjects
for mr in $PROJECT/sourcedata/YC-0_MR/nifti/*_MR.nii
do
    sub=$(basename "$mr" _MR.nii)

    mkdir -p $PROJECT/rawdata/sub-${sub}/anat
    mkdir -p $PROJECT/rawdata/sub-${sub}/pet

    cp "$mr" \
       $PROJECT/rawdata/sub-${sub}/anat/

    cp $PROJECT/sourcedata/YC-0_PET_5070/nifti/${sub}_PiB_5070.nii \
       $PROJECT/rawdata/sub-${sub}/pet/
done

echo "Rawdata structure created."
