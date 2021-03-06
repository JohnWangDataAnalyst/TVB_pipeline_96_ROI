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
subID="PAT03T1"

# Check input
rootPath=$(pwd)
subFolder=$(pwd)/subjects
SUBJECTS_DIR=${subFolder}/${subID}

# Create results folder
cd ${subFolder}/${subID}
fmri_results=${subFolder}/${subID}/bold
mkdir -p ${fmri_results}

#############################################################

echo "*** Preparation ***"

# Convert the raw DICOM Files to a single 4D-Nifti File (BOLD)
mrconvert RAWDATA/BOLD-EPI/ ${fmri_results}/bold.nii.gz

# Get the number of DICOMs in the RAWDATA-folder
numVol=$(ls -1 RAWDATA/BOLD-EPI/* | wc -l)

# Get the number of voxels in the 4D timeseries (bold.nii.gz)
cd $fmri_results
numVox=$(fslstats bold.nii.gz -v | cut -f 1 -d " ")

# Convert freesurfer brainmask to NIFTI
mri_convert --in_type mgz --out_type nii ${SUBJECTS_DIR}/recon_all/mri/brainmask.mgz brainmask.nii.gz

# Mask the brainmask using aparc+aseg
mri_convert --in_type mgz --out_type nii ${SUBJECTS_DIR}/recon_all/mri/aparc+aseg.mgz aparc+aseg.nii.gz
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

# Run FSL FEAT using the config created above
feat feat.fsf

# Register example-func to freesurfer brainmask
mkdir featDir.feat/reg/freesurfer
flirt -in featDir.feat/mean_func.nii.gz -ref brainmask.nii.gz -out exfunc2anat_6DOF.nii.gz \
-omat exfunc2anat_6DOF.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 \
-searchrz -90 90 -dof 6 -interp trilinear

# Invert transformation
convert_xfm -omat anat2exfunc.mat -inverse exfunc2anat_6DOF.mat

# Transform roimask to functional space using FLIRT (using Nearest Neighbor Interpolation for roimask)
flirt -in aparc+aseg.nii.gz -applyxfm -init anat2exfunc.mat -out featDir.feat/reg/freesurfer/aparc+aseg.nii.gz \
-paddingsize 0.0 -interp nearestneighbour -ref featDir.feat/mean_func.nii.gz

# Export average region time-series
mri_segstats --seg featDir.feat/reg/freesurfer/aparc+aseg.nii.gz --sum ${fmri_results}/aparc_stats.txt --i featDir.feat/filtered_func_data.nii.gz --avgwf ${subID}_ROIts.dat

# Remove all comment lines from the files (important for later MATLAB/OCTAVE import!)
sed '/^\#/d' ${fmri_results}/aparc_stats.txt > ${fmri_results}/aparc_stats_tmp.txt
# Remove the strings
sed 's/Seg/0/g' ${fmri_results}/aparc_stats_tmp.txt > ${fmri_results}/aparc_stats_cleared.txt
rm ${fmri_results}/aparc_stats_tmp.txt

# Create FC matrix
cp ${rootPath}/matlab_scripts/compFC.m ./compFC.m
octave --eval "compFC('${fmri_results}','${subID}')"

