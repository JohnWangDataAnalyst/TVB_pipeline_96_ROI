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
subFolder=$(pwd)/subjects

#cp ${rootPath}/matlab_scripts/*.m ${subFolder}/${subID}/mrtrix_${numROI}/tracks_${numROI}
cd ${subFolder}/${subID}/mrtrix_${numROI}/tracks_${numROI}

filesDIR=${subFolder}/${subID}/mrtrix_${numROI}/masks_${numROI}

#wmborderfile=${subFolder}/${subID}/mrtrix_${numROI}/masks_${numROI}/wmborder.mat

# Generate a set of commands for the SC-jobs...
#if [ ! -f "compSCcommand.txt" ]; then
	for i in {33..48}
	do
	 #if [ "${numROI}" = "96" ]
	 #then
	# echo "computeSC_cluster_96(${i},'SC_row_${i}${subID}.mat')" >> compSCcommand.txt
	  octave --eval "computeSC_cluster_96('$filesDIR',${i},'SC_row_${i}${subID}.mat')" 

         #else
	 #echo "computeSC_clusterDK('./','_tracks${subID}.tck','../masks_${numROI}/wmborder.mat','${i}','SC_row_${i}${subID}.mat')" >> compSCcommand.txt
	 #fi
	done
#fi

# Compute SC matrices
#octaveCommand=$(<compSCcommand.txt)
#octave --eval "${octaveCommand}"
#matlab -nosplash -nodesktop -r "${octaveCommand};exit;"
