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


if [ "$numROI" == "96" ]
then
cp $SUBJECTS_DIR/calc_images/GM_roied.nii.gz ./
Aparc=GM_roied.nii.gz
else
mri_convert --in_type mgz --out_type nii ${SUBJECTS_DIR}/recon_all/mri/aparc+aseg.mgz aparc+aseg.nii.gz
Aparc=aparc+aseg.nii.gz
fi

####segment on T1 subject
fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -g --nopve -o $subID brainmask.nii.gz

# Register example-func to freesurfer brainmask
mkdir featDir.feat/reg
mkdir featDir.feat/reg/freesurfer
flirt -in featDir.feat/mean_func.nii.gz -ref brainmask.nii.gz -out exfunc2anat_6DOF.nii.gz \
-omat exfunc2anat_6DOF.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 \
-searchrz -90 90 -dof 6 -interp trilinear

# Invert transformation
convert_xfm -omat anat2exfunc.mat -inverse exfunc2anat_6DOF.mat

# Transform roimask(using GM_roied instead of aparc+aseg) CSF (_seg_0) and WM (_seg_2)  to functional space using FLIRT (using Nearest Neighbor Interpolation for roimask)


flirt -in $Aparc -applyxfm -init anat2exfunc.mat -out featDir.feat/reg/freesurfer/aparc+aseg.nii.gz \
-paddingsize 0.0 -interp nearestneighbour -ref featDir.feat/mean_func.nii.gz


flirt -in ${subID}_seg_0 -applyxfm -init anat2exfunc.mat -out featDir.feat/reg/freesurfer/CSF2exfunc.nii.gz \
-paddingsize 0.0 -interp nearestneighbour -ref featDir.feat/mean_func.nii.gz

flirt -in ${subID}_seg_2 -applyxfm -init anat2exfunc.mat -out featDir.feat/reg/freesurfer/WM2exfunc.nii.gz \
-paddingsize 0.0 -interp nearestneighbour -ref featDir.feat/mean_func.nii.gz

###use fslmeants to get average timeseries for each of CSF and WM
fslmeants -i featDir.feat/filtered_func_data.nii.gz -o CSF.txt -m featDir.feat/reg/freesurfer/CSF2exfunc.nii.gz
fslmeants -i featDir.feat/filtered_func_data.nii.gz -o WM.txt -m featDir.feat/reg/freesurfer/WM2exfunc.nii.gz

###using paste to merger txt files in column
paste CSF.txt WM.txt featDir.feat/mc/prefiltered_func_data_mcf.par | column -s $'\t' -t > nuisance


###regress out CSF and WM
fsl_glm -i featDir.feat/filtered_func_data.nii.gz -d nuisance --out_res=featDir.feat/filtered_func_data.nii.gz

# Export average region time-series
mri_segstats --seg featDir.feat/reg/freesurfer/aparc+aseg.nii.gz --sum ${fmri_results}/aparc_stats.txt --i featDir.feat/filtered_func_data.nii.gz --avgwf ${subID}_ROIts.dat

# Remove all comment lines from the files (important for later MATLAB/OCTAVE import!)
sed '/^\#/d' ${fmri_results}/aparc_stats.txt > ${fmri_results}/aparc_stats_tmp.txt
# Remove the strings
sed 's/Seg/0/g' ${fmri_results}/aparc_stats_tmp.txt > ${fmri_results}/aparc_stats_cleared.txt
rm ${fmri_results}/aparc_stats_tmp.txt

# Create FC matrix
cp ${rootPath}/matlab_scripts/compFC.m ./compFC.m
octave --eval "compFC('${numROI}','${fmri_results}','${subID}')"

