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
cd ${subFolder}/${subID}/mrtrix_${numROI}/tracks_${numROI}

# Start with the aggregation
if [ "${numROI}" = "96" ]
then
octave --eval "aggregateSC_cluster('${numROI}','${subID}_SC.mat','${subFolder}/${subID}/mrtrix_${numROI}/masks_${numROI}/wmborder.mat','${subID}')"
else
octave --eval "aggregateSC_clusterDK('${subID}_SC.mat','${subFolder}/${subID}/mrtrix_${numROI}/masks_${numROI}/wmborder.mat','${subID}')"
fi
