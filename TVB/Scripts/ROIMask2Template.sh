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
MRTrix3DIR=/opt/mrtrix3/bin

# Check input
rootPath=$(pwd)
subFolder=$(pwd)/subjects

#111111111111111111111111111111111111111111111111111111111111111111111111111
#Using Ants do registration (very powerful but sometime you need to repeat this procedure many times to get it right)
roimask=/home/jwang/data/ROI96/RM_inMNI.nii.gz
# Template of standard brain we are using brain of 70-74 year-old people
ANTS=${templateFile}/${templateFilename}
MNIMask=${FSLDIR}/data/standard/MNI152_T1_1mm_brain_mask.nii.gz


ANTSDIR=/opt/ANTs-1.9.v4-Linux/bin
${ANTSDIR}/ANTS 3 -m CC[${ANTS},${MNIMask},1,4] -i 100*100*100*20 -o ANTS_2_mni.nii.gz -t SyN[0.25]  -r Gauss[3,0]


####check the size of ANTS_2_mniWarp.nii.gz
file=ANTS_2_mniWarp.nii.gz
minimumsize=9000000
actualsize=$(stat -c%s "$file")

while (( ${actualsize} <= 9000000 )) 
do
rm ANT*
${ANTSDIR}/ANTS 3 -m CC[${ANTS},${MNIMask},1,4] -i 100*100*100*20 -o ANTS_2_mni.nii.gz -t SyN[0.25]  -r Gauss[3,0]
actualsize=$(stat -c%s "$file")
done


${ANTSDIR}/WarpImageMultiTransform 3 ${roimask} ${templatePath}/RM_in${templateFilename} -R ${MNIMask} --use-NN -i ANTS_2_mniAffine.txt ANTS_2_mniInverseWarp.nii


