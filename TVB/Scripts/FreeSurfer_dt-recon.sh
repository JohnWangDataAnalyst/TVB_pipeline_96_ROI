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
# IMPORTANT: adapt subID to name of your subject folder + set path to MRtrix2
# (commands from MRtrix3 should run from terminal, by placing path to MRtrix3
# in your bashrc file)
# =============================================================================

# Input
#subID="PAT03T1" subID and numROI are defined as Env Variables
MRTrixDIR=/opt/mrtrix2/bin

# Check input
rootPath=$(pwd)
subFolder=$(pwd)/subjects
T1=${subFolder}/${subID}/recon_all/mri/T1.mgz


#############################################################

#echo "comment"
#: <<'END'
echo "*** Load data & dt_recon ***"
#Extract the diffusion vectors and the pulse intensity (bvec & bval)
dt_recon=${subFolder}/${subID}/dt_recon
mkdir $dt_recon
${MRTrixDIR}/mrinfo ${subFolder}/${subID}/RAWDATA/DTI/ -grad ${dt_recon}/btable.b
cut -f 1,2,3 ${dt_recon}/btable.b > ${dt_recon}/bvec
cut -f 4 ${dt_recon}/btable.b > ${dt_recon}/bval

#Get the Name of the First file in the Dicom-Folder
firstFile=$(ls ${subFolder}/${subID}/RAWDATA/DTI/ | sort -n | head -1)

dt_recon --i ${subFolder}/${subID}/RAWDATA/DTI/${firstFile} --b ${dt_recon}/bval ${dt_recon}/bvec --sd ${subFolder}/${subID} --s recon_all --no-ec --o ${subFolder}/${subID}/dt_recon
#uses FSL eddy_correct: don't do with high b-values!
#END
#echo "comment end"

echo "*** WM surface ***"
mkdir -p ${subFolder}/${subID}/calc_images
cd ${subFolder}/${subID}/calc_images
mri_surf2vol --hemi lh --mkmask --template $T1 --o lh_white.nii --sd ${subFolder}/${subID} --identity recon_all
mri_surf2vol --hemi rh --mkmask --merge lh_white.nii --o wm_outline_${numROI}.nii --sd ${subFolder}/${subID} --identity recon_all
#(commented out by authors)

#mri_convert --in_orientation LIA --out_orientation RAS wm_outline_${numROI}.nii wm_outline_${numROI}.nii
gzip <wm_outline_${numROI}.nii> wm_outline_${numROI}.nii.gz

#END
#echo "comment"
###### GLEB Block

#Define the Path of the Gleb-Roimask
if [ "$numROI" == "96" ]
then
roimask=/home/jwang/data/ROI96/RM_inMNI.nii.gz
#MNI=${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz
#MNIMask=${FSLDIR}/data/standard/MNI152_T1_1mm_brain_mask.nii.gz
#Convert from .mgz to .nii.gz to make images readable for FSL
mri_convert --in_type mgz --out_type nii --out_orientation RAS ${subFolder}/${subID}/recon_all/mri/brainmask.mgz ${subFolder}/${subID}/recon_all/mri/brainmask.nii.gz
T1_brain=${subFolder}/${subID}/recon_all/mri/brainmask.nii.gz
mri_convert --in_type mgz --out_type nii --out_orientation RAS ${subFolder}/${subID}/recon_all/mri/T1.mgz ${subFolder}/${subID}/recon_all/mri/T1.nii.gz
T1=${subFolder}/${subID}/recon_all/mri/T1.nii.gz
#Create a Transformation-Rule from MNI to T1 Space
flirt -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain -in $T1_brain -omat t1_2_mni_transf.mat
fnirt --in=$T1 --aff=t1_2_mni_transf.mat --cout=t1_2_mni_nonlinear_transf --config=T1_2_MNI152_2mm
#MNI to T1 (INVERSE from above)
convert_xfm -omat t1_2_mni_transf_inverse.mat -inverse t1_2_mni_transf.mat
invwarp --ref=$T1 --warp=t1_2_mni_nonlinear_transf.nii.gz --out=t1_2_mni_nonlinear_transf_inverse
#Bring the ROI-Mask to T1-Space
applywarp --ref=$T1 --in=$roimask --warp=t1_2_mni_nonlinear_transf_inverse --out=warped_rmask_2_t1 --interp=nn
gunzip warped_rmask_2_t1.nii.gz 

#END
#echo "comment end"

# uncomment out later
cd ${subFolder}/${subID}/calc_images
gunzip warped_rmask_2_t1.nii.gz


##DOWNLOAD the Files wm_outline.nii.gz, aparc+aseg.nii.gz & warped_rmask_2_t1.nii.gz
##Then start the MATLAB Script refineGlebs.m
#Once this is finished upload the resulting File wm_outline_roied.nii.gz to the cluster, place it under:

cp ${rootPath}/matlab_scripts/*.m $(pwd) 
cp ${subFolder}/${subID}/recon_all/mri/aparc+aseg.nii $(pwd)
gzip <aparc+aseg.nii> aparc+aseg.nii.gz
octave --eval "refineGlebs('$numROI','$(pwd)')"
gzip wm_outline_roied.nii
fi


echo "*** Rotations/Translations ***"
lowb=${subFolder}/${subID}/dt_recon/lowb.nii
wm_outline=${subFolder}/${subID}/calc_images/wm_outline_roied.nii.gz
rule=${subFolder}/${subID}/dt_recon/register.dat

#Rotate high-res (1mm) WM-border to match dwi data w/o resampling
mri_vol2vol --mov $lowb --targ $wm_outline --inv --interp nearest --o wmoutline2diff_1mm.nii --reg $rule --no-save-reg --no-resample
#Rotate high-res (1mm) WM-border to match dwi data with resampling
mri_vol2vol --mov $lowb --targ $wm_outline --inv --o wmoutline2diff.nii.gz --reg $rule --no-save-reg
#Filter out low voxels produced by trilin. interp.
fslmaths wmoutline2diff.nii.gz -thr 0.1 wmoutline2diff.nii.gz
#Binarize
#fslmaths wmoutline2diff.nii.gz -bin wmoutline2diff.nii.gz && gunzip wmoutline2diff.nii.gz
fslmaths wmoutline2diff.nii.gz -bin wmoutline2diff.nii.gz 

#Rotate high-res (1mm) wmparc to match dwi data w/o resampling
mri_vol2vol --mov $lowb --targ ${subFolder}/${subID}/recon_all/mri/wmparc.mgz --inv --interp nearest --o wmparc2diff_1mm.nii --reg $rule --no-save-reg --no-resample
#Rotate high-res (1mm) aparc+aseg to match dwi data w/o resampling
mri_vol2vol --mov $lowb --targ ${subFolder}/${subID}/recon_all/mri/aparc+aseg.mgz --inv --interp nearest --o aparc+aseg2diff_1mm.nii --reg $rule --no-save-reg --no-resample
#Rotate high-res (1mm) aparc+aseg to match dwi data with resampling
mri_vol2vol --mov $lowb --targ ${subFolder}/${subID}/recon_all/mri/aparc+aseg.mgz --inv --interp nearest --o aparc+aseg2diff.nii --reg $rule --no-save-reg

#GZip the Files
gzip wmoutline2diff_1mm.nii
gzip wmparc2diff_1mm.nii
#gzip wmoutline2diff.nii

echo "*** Create brainmasks ***"

#Lowres Mask
aparc=${subFolder}/${subID}/calc_images/aparc+aseg2diff.nii
#Remove the GM (in aparc+aseg, the WM has the Voxelvalues 2 and 41 plus 251-255 for the CC)
fslmaths $aparc -uthr 41 -thr 41 wmmask_${numROI}.nii.gz
fslmaths $aparc -uthr 2 -thr 2 -add wmmask_${numROI}.nii.gz wmmask_${numROI}.nii.gz
fslmaths $aparc -uthr 255 -thr 251 -add wmmask_${numROI}.nii.gz wmmask_${numROI}.nii.gz
#Combine & Binarize
fslmaths wmmask_${numROI}.nii.gz -add wmoutline2diff.nii.gz -bin wmmask_${numROI}.nii.gz

#Highres Mask
aparc=${subFolder}/${subID}/calc_images/aparc+aseg2diff_1mm.nii
#Remove the GM (in aparc+aseg, the WM has the Voxelvalues 2 and 41 plus 251-255 for the CC)
fslmaths $aparc -uthr 41 -thr 41 wmmask_1mm_${numROI}.nii.gz
fslmaths $aparc -uthr 2 -thr 2 -add wmmask_1mm_${numROI}.nii.gz wmmask_1mm_${numROI}.nii.gz
fslmaths $aparc -uthr 255 -thr 251 -add wmmask_1mm_${numROI}.nii.gz wmmask_1mm_${numROI}.nii.gz
#Combine & Binarize
fslmaths wmmask_1mm_${numROI}.nii.gz -add $wm_outline -bin wmmask_1mm_${numROI}.nii.gz
