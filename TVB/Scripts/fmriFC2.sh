#!/bin/bash

# =============================================================================
# Authors: Michael Schirner, Simon Rothmeier, Petra Ritter
# BrainModes Research Group (head: P. Ritter)
# Charité University Medicine Berlin & Max Planck Institute Leipzig, Germany
# Correspondence: petra.ritter@charite.de
#
# When using this code please cite as follows:
# Schirner M, Rothmeier S, Jirsa V, McIntosh AR, Ritter P (in prep)
# Constructing subject-specific Virtual Brains from multimodal neuroimaging
#
# This software is distributed under the terms of the GNU General Public License
# as published by the Free Software Foundation. Further details on the GPL
# license can be found at http://www.gnu.org/copyleft/gpl.html.
#
# Adapted to run locally by Hannelore Aerts
# Department of Data-Analysis, Faculty of Psychology and Educational Sciences,
# Ghent University, Belgium
# Correspondence: hannelore.aerts@ugent.be
# =============================================================================
# IMPORTANT: adapt subID to name of your subject folder
# =============================================================================

# Input
#subID="PAT03T1"

# Check input
rootPath=$(pwd)
subFolder=${rootPath}/subjects
SUBJECTS_DIR=${subFolder}/${subID}


fmri_results=${subFolder}/${subID}/bold

cd $fmri_results

# Run FSL FEAT using the config created above
#echo "check" $FSLDIR $SGE_ROOT "FSLSUBALREADYRUN"
feat feat.fsf

file=featDir.feat/prefiltered_func_data_tempfilt.nii.gz
while [ ! -f "$file" ]
do
sleep 1

done

sleep 2m
