function generateMasks(numROI,subPath,pathOnCluster)
%Approx. Runtime on a MacBook Pro 13" 2011 Core i5 --> ~23min
%This script is meant to be run locally for now!

% --------- Subcortical Regions in FREESURFER -------------
% 10 Left-Thalamus-Proper
% 49 Right-Thalamus-Proper
% 11 Left-Caudate
% 50 Right-Caudate
% 12 Left-Putamen
% 13 Left-Pallidum
% 51 Right-Putamen
% 52 Right-Pallidum
% 17 Left-Hippocampus
% 18 Left-Amygdala
% 53 Right-Hippocampus
% 54 Right-Amygdala
% 26 Left-Accumbens-area
% 28 Left-Ventral-Diencephalon (contains hypothalamus, mammillary body,
% subthalamic nuclei, substantia nigra, red nucleus, lateral geniculate
% nucleus, and medial geniculate nucleus)
% 58 Right-Accumbens-area
% 60 Right-Ventral-Diencephalon
% ---------- /////////////////////////////// --------------

%tic
mask_output_folder=[subPath 'mrtrix_' numROI '/masks_' numROI '/'];
mkdir([subPath 'mrtrix_' numROI '/'],['masks_' numROI])

%Set the desired Number of Seedpoints per voxel
seedsPerVoxel = 200;
%seedsPerVoxel = 1000;
%Calculate MaskChunkSize depending on the Number of Seeds based on the
%reference we had before: 500 Voxel-Chunks with 200Seeds/Voxel = 100000
% "Information-Points"
maskChunckSize = 100000/seedsPerVoxel;

display(['Generating Masks for a Mask-Size of ' num2str(maskChunckSize) ' Voxels and ' num2str(seedsPerVoxel) ' Seeds/Voxel.']);

%Extract and Save the Affine Matrix for later use
%header = load_untouch_header_only([subPath 'wmoutline2diff_1mm.nii.gz']);
%TODO: First uncompress into tmp-file, afterwards recompress!.....
%header = niak_read_hdr_nifti([subPath 'wmoutline2diff_1mm.nii.gz']);
%affine_matrix = inv([header.hist.srow_x; header.hist.srow_y; header.hist.srow_z; 0 0 0 1]);

[wmborder.hdr,wmborder.img] = niak_read_vol([subPath 'calc_images/wmoutline2diff_1mm.nii.gz']);
affine_matrix = inv(wmborder.hdr.info.mat);
save([mask_output_folder 'affine_matrix.mat'], 'affine_matrix')

% High-res GM-WM-border
[nii.hdr,nii.img] = niak_read_vol([subPath 'calc_images/wmparc2diff_1mm.nii.gz']);
nii.hdr.file_name = [mask_output_folder 'wmparcMask_1mm.nii.gz'];
%nii=load_untouch_nii([subPath 'wmparc2diff_1mm.nii.gz']);
nii.img(nii.img <  1001) = 0;
nii.img(nii.img == 1004) = 0;
nii.img(nii.img == 2004) = 0;
nii.img(nii.img == 3004) = 0;
nii.img(nii.img == 4004) = 0;
nii.img(nii.img == 2000) = 0;
nii.img(nii.img == 3000) = 0;
nii.img(nii.img == 4000) = 0;
nii.img(nii.img >  4035) = 0;
nii.img(nii.img > 3000) = nii.img(nii.img > 3000) - 2000;
nii.img(nii.img > 2036) = 0;
nii.img(nii.img < 1001) = 0;
%save_untouch_nii(nii,[mask_output_folder 'wmparcMask_1mm.nii.gz']);
niak_write_vol(nii.hdr,nii.img);
%Gzip the Files (saves lots of storage space but may slow down the process)
%compress([mask_output_folder 'wmparcMask_1mm.nii']);

%wmborder=load_untouch_nii([subPath 'wmoutline2diff_1mm.nii.gz']);
wmborder.img(wmborder.img > 0) = nii.img(wmborder.img > 0);
wmborder.hdr.file_name = [mask_output_folder 'gmwmborder_1mm.nii.gz'];
%save_untouch_nii(wmborder,[mask_output_folder 'gmwmborder_1mm.nii.gz']);
niak_write_vol(wmborder.hdr,wmborder.img);
%Gzip the Files (saves lots of storage space but may slow down the process)
%compress([mask_output_folder 'gmwmborder_1mm.nii']);

%SUBCORT STUFF
[nii.hdr,nii.img] = niak_read_vol([subPath 'calc_images/wmparc2diff_1mm.nii.gz']);
for i = [10 49 11 50 12 13 51 52 17 18 53 54 26 28 58 60] %Define subcortical regions
    wmborder.img(nii.img == i) = i;
end


img=wmborder.img;
save([mask_output_folder 'wmborder.mat'], 'img')

% Seed & target masks
counter=0;
% for i = [1001:1003,1005:1035,2001:2003,2005:2035]
for i = [10:13 17 18 26 28 1001:1003,1005:1035,49:54 58 60 2001:2003,2005:2035]
    display(['Processing RegionID ' num2str(i)]);
    
    tmpimg=wmborder.img;
    tmpimg(tmpimg ~= i) = 0;
    tmpimg(tmpimg > 0) = 1;
    maskvoxel=find(tmpimg>0);
    nummasks=floor(length(maskvoxel)/maskChunckSize);
    for j = 1:nummasks,
        nii.img=zeros(size(tmpimg));
        nii.img(maskvoxel(1+(maskChunckSize*(j-1)):(maskChunckSize*j))) = 1;
        %save_untouch_nii(nii,[mask_output_folder 'seedmask' num2str(i) num2str(j) '_1mm.nii']);
        nii.hdr.file_name = [mask_output_folder 'seedmask' num2str(i) num2str(j) '_1mm.nii.gz'];
        niak_write_vol(nii.hdr,nii.img);
        %Gzip the Files (saves lots of storage space but may slow down the process)
        %compress([mask_output_folder 'seedmask' num2str(i) num2str(j) '_1mm.nii']);

        tmpfind=[num2str(i) num2str(j)];
        counter=counter+1;
        numseeds(counter,1)=str2num(tmpfind);
        numseeds(counter,2)=length(find(nii.img>0));
        numseeds(counter,3)=i;
    end
    nii.img=zeros(size(tmpimg));
    nii.img(maskvoxel(1+(maskChunckSize*nummasks):end)) = 1;
    %save_untouch_nii(nii,[mask_output_folder 'seedmask' num2str(i) num2str((nummasks+1)) '_1mm.nii.gz']);
    nii.hdr.file_name = [mask_output_folder 'seedmask' num2str(i) num2str((nummasks+1)) '_1mm.nii.gz'];
    niak_write_vol(nii.hdr,nii.img);
    %Gzip the Files (saves lots of storage space but may slow down the process)
    %compress([mask_output_folder 'seedmask' num2str(i) num2str((nummasks+1)) '_1mm.nii']);

    tmpfind=[num2str(i) num2str(nummasks+1)];
    counter=counter+1;
    numseeds(counter,1)=str2num(tmpfind);
    numseeds(counter,2)=length(find(nii.img>0));
    numseeds(counter,3)=i;
        
    tmpimg=wmborder.img;
    tmpimg(tmpimg == i) = 0;
    tmpimg(tmpimg > 0) = 1;
    nii.img=tmpimg;
    %save_untouch_nii(nii,[mask_output_folder 'targetmask' num2str(i) '_1mm.nii.gz']);
    nii.hdr.file_name = [mask_output_folder 'targetmask' num2str(i) '_1mm.nii.gz'];
    niak_write_vol(nii.hdr,nii.img);
    
    %Gzip the Files (saves lots of storage space but may slow down the process)
    %compress([mask_output_folder 'targetmask' num2str(i) '_1mm.nii']);
end
numseeds(:,2)=numseeds(:,2)*seedsPerVoxel;

dlmwrite([mask_output_folder 'seedcount.txt'],numseeds,'delimiter', ' ','precision',10);

%Generate Batch File
%load([mask_output_folder 'seedcount.txt'])
fileID = fopen([mask_output_folder 'batch_track.sh'],'w');
%fprintf(fileID,'#!/bin/bash\n');
%fprintf(fileID,'export jid=$1\n');

%slashes = strfind(subPath,'/'); %Find all occurences of the slash in the subPath
for roiid=1:size(numseeds,1),
    %fprintf(fileID, ['oarsub -n trk_' subPath(slashes(end-1)+1:slashes(end)-1) ' -l walltime=06:00:00 -p "host > ''n10''" "./tracking_cluster_68.sh ' pathOnCluster ' ' num2str(seedcount(roiid,1)) '"\n']);
      fprintf(fileID, [pathOnCluster ' ' num2str(numseeds(roiid,1)) ' ' num2str(numseeds(roiid,2)) ' ' num2str(numseeds(roiid,3)) '\n']);


end
fclose(fileID);

%toc
end

function compress(fileName)
    %Gzip the Files (saves lots of storage space but may slow down the process)
    gzip({fileName})
    delete(fileName)
end

function uncompress(fileName)
    gunzip({fileName})
end




