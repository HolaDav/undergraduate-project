#!/bin/bash

#############################################################
# 04_preprocess_subject.sh
#
# Runs preprocessing for ONE subject.
#
# Usage:
#
# bash scripts/04_preprocess_subject.sh sub-AD01
#
#############################################################

set -e

PROJECT=$(cd "$(dirname "$0")/.." && pwd)

SUBJECT=$1

if [ -z "$SUBJECT" ]; then
    echo "Usage:"
    echo "bash scripts/04_preprocess_subject.sh sub-AD01"
    exit 1
fi

MRI="$PROJECT/rawdata/$SUBJECT/anat/${SUBJECT}_T1w.nii"
PET="$PROJECT/rawdata/$SUBJECT/pet/${SUBJECT}_trc-pib_pet.nii"

echo "=========================================="
echo "Subject : $SUBJECT"
echo "=========================================="

if [ ! -f "$MRI" ]; then
    echo "ERROR: MRI not found"
    exit 1
fi

if [ ! -f "$PET" ]; then
    echo "ERROR: PET not found"
    exit 1
fi

echo "✓ Input files found."

echo ""
echo "Running SPM preprocessing..."
echo ""

# We will replace this with the generated batch later.
# For now this is only a placeholder.

echo "SPM preprocessing placeholder."

echo ""
echo "Preprocessing finished."
