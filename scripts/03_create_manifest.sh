#!/bin/bash

PROJECT=~/Desktop/workspace/undergraduate_project

OUTFILE=$PROJECT/docs/subject_manifest.csv

echo "participant_id,group,mri_file,pet_file,status" > $OUTFILE

for subdir in $PROJECT/rawdata/sub-*
do

    subject=$(basename "$subdir")

    if [[ $subject == sub-AD* ]]; then
        group="AD"
    else
        group="YC"
    fi

    mri=$(basename $subdir/anat/*.nii)
    pet=$(basename $subdir/pet/*.nii)

    echo "${subject},${group},${mri},${pet},pending" >> $OUTFILE

done

echo "Manifest created:"
echo "$OUTFILE"
