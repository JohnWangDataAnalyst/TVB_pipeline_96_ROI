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

# Create results folder
cd ${subFolder}/${subID}
fmri_results=${subFolder}/${subID}/bold
mkdir -p ${fmri_results}

#############################################################

echo "*** Preparation ***"

# Convert the raw DICOM Files to a single 4D-Nifti File (BOLD)

if [ "$fmri_dtype" == "mgz" ]
then

mrconvert RAWDATA/BOLD-EPI/ ${fmri_results}/bold1.nii.gz
else
cp  RAWDATA/BOLD-EPI/bold1.nii.gz ${fmri_results}/bold1.nii.gz

fi
#### bandpass filter (0.01 - 0. Hz)
fslmaths ${fmri_results}/bold1.nii.gz -bptf 20.8 2.08 ${fmri_results}/bold.nii.gz


# Get the number of DICOMs in the RAWDATA-folder
#numVol=$(ls -1 RAWDATA/BOLD-EPI/* | wc -l)
#numVol=$(fslnvols bold.nii.gz)

# Get the number of voxels in the 4D timeseries (bold.nii.gz)
cd $fmri_results
numVol=$(fslnvols bold.nii.gz)
numVox=$(fslstats bold.nii.gz -v | cut -f 1 -d " ")

# Convert freesurfer brainmask to NIFTI
mri_convert --in_type mgz --out_type nii ${SUBJECTS_DIR}/recon_all/mri/brainmask.mgz brainmask.nii.gz

# Mask the brainmask using aparc+aseg
#mri_convert --in_type mgz --out_type nii ${SUBJECTS_DIR}/recon_all/mri/aparc+aseg.mgz aparc+aseg.nii.gz
fslmaths brainmask.nii.gz -nan brainmask.nii.gz

# Fieldmap correction: we don't have fieldmap

################################################################

echo "*** Preprocessing ***"

# Copy the generic feat Config to the subject Folder & insert the subID
cp ${rootPath}/featConfig/default.fsf ./feat.fsf
sed -i -e s/numvolGEN/$((numVol))/g feat.fsf
sed -i -e s/numvoxGEN/$((numVox))/g feat.fsf
sed -i -e s/subGEN/${subID}/g feat.fsf
sed -i -e s~pathGEN~${subFolder}~g feat.fsf

