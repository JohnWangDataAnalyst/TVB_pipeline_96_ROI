function refineGlebs(numROI,subDir)
% This Script is used to allocate the ROIs from the 96-Region-Roimask
% (warped from MNI to T1-Space) to the WM/GM-Border extracted by
% Freesurfers recon-all.
% It also Maps these regions onto the WM/GM-Interface extracted by
% Freesurfers recon-all.
% Runtime on a MacBook Pro 13" 2011 (Intel i5 2.3Ghz): ~33min  
% 
% Simon Rothmeier, srothmei@mailbox.tu-berlin.de
% Last changed: 14.03.2014

tic

%Needs:
%   + wm_outline.nii - The WM/GM-Border
%   + warped_rmask_2_t1.nii - ROI-Mask warped from MNI-Space to T1
%   + aparc+aseg.nii - Mask of the brain regions created by Freesurfer. This
%                  file holds the following values:
%                       0: No Brain-Voxel
%                       2: Left-Hemisphere-White-Matter
%                       3: Left-Hemisphere-Grey-Matter
%                       10: Left-Thalamus-Proper
%                       11: Left-Caudate
%                       12: Left-Putamen
%                       13: Left-Pallidum
%                       17: Left-Hippocampus
%                       18: Right-Amygdala
%                       26: Left-Accumbens
%                       41: Right-Hemisphere-White-Matter
%                       42: Right-Hemisphere-Grey-Matter
%                       49: Right-Thalamus-Proper
%                       50: Right-Caudate
%                       51: Right-Putamen
%                       52: Right-Pallidum
%                       53: Right-Hippocampus
%                       54: Right-Amygdala
%                       58: Right-Accumbens
subcort_array = [10 11 12 13 17 18 26 49 50 51 52 53 54 58];

aseg = load_nii([subDir '/aparc+aseg.nii']);
roimask = load_nii([subDir '/warped_rmask_2_t1.nii']);
wm_outline = load_nii([subDir '/wm_outline_' numROI '.nii']); %Load with applying the transf. matrix to keep consistent when adding subcort. outline


nii = aseg;
% High-res GM-WM-border
nii.img(nii.img <  1001) = 0;
nii.img(nii.img == 1004) = 0;
nii.img(nii.img == 2004) = 0;
nii.img(nii.img == 2000) = 0;
nii.img(nii.img > 2036) = 0;
nii.img(aseg.img == 2) = 1; %Insert WM
nii.img(aseg.img == 41) = 1; %Insert WM

%Build a whitermatter mask by removing every entry from aparc+aseg but the
%following: 2; 41; 251-255
wmmask = zeros(size(aseg.img));
wmmask(aseg.img == 2) = 1;
wmmask(aseg.img == 41) = 1;
wmmask(aseg.img == 251) = 1;
wmmask(aseg.img == 252) = 1;
wmmask(aseg.img == 253) = 1;
wmmask(aseg.img == 254) = 1;
wmmask(aseg.img == 255) = 1;
%Add the Brainstem as Whitematter
%wmmask(aseg.img == 16) = 1;
tmp = aseg;
tmp.img = wmmask;
save_nii(tmp,[subDir '/wmmask_matlab.nii']);
clear tmp

%Clean the Greymatter-Segmentation (i.e. remove Subcortical Structures except the Thalamus)
without_subcort = aseg.img;
without_subcort(without_subcort < 1001) = 0;
without_subcort(without_subcort == 1004) = 0;
without_subcort(without_subcort == 2004) = 0;
without_subcort(without_subcort == 2000) = 0;
without_subcort(without_subcort > 2035) = 0;
without_subcort(without_subcort ~= 0) = 1; %Binarize

with_subcort = zeros(size(aseg.img,1),size(aseg.img,2),size(aseg.img,3));
for i = 1:length(subcort_array)
    with_subcort(logical(aseg.img == subcort_array(i))) = 1;
end
clear i
%with_subcort(logical((aseg.img == 49)+(aseg.img == 10)+(aseg.img == 53)+(aseg.img == 17)+(aseg.img == 51)+(aseg.img == 12)+(aseg.img == 50)+(aseg.img == 11)+(aseg.img == 52)+(aseg.img == 13)+(aseg.img == 54)+(aseg.img == 18))) = 1;


greymatter = single(without_subcort) + single(with_subcort);

%Set all voxels in the warped Roimask that are falsely assigned to the
%White-Matter or that lie outside the cortical ribbon to Zero
%roimask.img(logical((aseg.img == 2)+(aseg.img == 41)+(aseg.img == 0))) = 0;
roimask.img(greymatter == 0) = 0;
roimask.img(roimask.img == 0) = 1; %Set all Zeros to 1 (important later)

%Build an index of GM-Voxels that haven't been assigned to a ROI yet
%greymatter = zeros(size(aseg.img,1),size(aseg.img,2),size(aseg.img,3));
%greymatter(logical((aseg.img == 3)+(aseg.img == 42)+(aseg.img == 49)+(aseg.img == 10)+(aseg.img == 53)+(aseg.img == 17)+(aseg.img == 51)+(aseg.img == 12)+(aseg.img == 50)+(aseg.img == 11))) = 1;

%Asign the warped ROI-Values to the GM

%UNCOMMENT ME!!!!! ++++++++++++++++++++++++++++++
greymatter = greymatter + (roimask.img - 1);


% % Prepare the Outline of the Subcort. Regions
% % subcort_array = [10 11 12 13 26 49 50 51 52 58];
% with_subcort = zeros(size(aseg.img,1),size(aseg.img,2),size(aseg.img,3));
% edge_subcort = zeros(size(aseg.img,1),size(aseg.img,2),size(aseg.img,3));
% for i = 1:length(subcort_array)
%     with_subcort(logical(aseg.img == subcort_array(i))) = 1;
% end
% 
% for x = 1:size(with_subcort,1)
%     Skip the rest if the whole slice is 0 anyway...
%     if(max(max(with_subcort(x,:,:))) > 0)
%         for y = 1:size(with_subcort,2)
%             for z = 1:size(with_subcort,3)
%                 Check if there is a WM-Voxel in the direct neighbourhood
%                 if(with_subcort(x,y,z) == 1 && sum(sum(sum(with_subcort(x-1:x+1,y-1:y+1,z-1:z+1)))) < 27)
%                 if(with_subcort(x,y,z) == 1 && sum(sum(sum(wmmask(x-1:x+1,y-1:y+1,z-1:z+1)))) > 0)
%                     edge_subcort(x-1:x+1,y-1:y+1,z-1:z+1) = wmmask(x-1:x+1,y-1:y+1,z-1:z+1);
%                     edge_subcort(x,y,z) = 1;
%                 end
%             end
%         end
%     end
% end
%edge_subcort = imdilate(reshape(with_subcort,size(with_subcort,1),[]),strel('disk',1));
%edge_subcort = reshape(edge_subcort,size(with_subcort)) - with_subcort;

%clear with_subcort without_subcort

%To speed things up, all Voxels with Neighborvoxels from 26 down to this value get processed (i.e. assigned) during one loop-cycle
%They only get assigned if there a no "conflicts" with neighbor-voxels
%This means that they are assigned descending ordered by the number of
%definite ROI-Values surounding them
lvl_of_uncertainty = 9; 

%The Radius of the Searchlight. If 1, the adjacent 26 Voxels are examined
%etc...
search_radius = 1;

zeros_greymatter_prev = -1;

%tic
while(nnz(greymatter == 1) > 0)  
    
    if (zeros_greymatter_prev == nnz(greymatter == 1))
        lvl_of_uncertainty = lvl_of_uncertainty - 1; %To ensure the algorithm converges lower the threshold
        if (lvl_of_uncertainty == 0)
            lvl_of_uncertainty = 14;
            search_radius = search_radius + 1;
        end
    end
    zeros_greymatter_prev = nnz(greymatter == 1);
    display(['# of Ones: ' num2str(zeros_greymatter_prev)])
    display(['Lvl of Uncertainty: ' num2str(lvl_of_uncertainty)])
%For each Voxel, the adjacent 26 Neighborvoxels are checked for their ROI
%affiliation. The Neighborhood is stored as a Matrix in the following manner:
% X Y Z ModeValue FrequencyOfModeValue
    nb_store = zeros(nnz(greymatter == 1),5);
    indx = 1;

    %Loop over all Nonzero-Voxels in the GM
    %for z = 3:size(greymatter,3)-2
    for z = 3:(size(greymatter,3)-2)
        [x_vec, y_vec] = find(greymatter(:,:,z) == 1);
        if (max(max(greymatter(:,:,z))) > 0 && ~isempty(x_vec)) %If the whole slice is Zero or already evaluated we can skip it!
            for i=1:size(x_vec,1)
                x = x_vec(i);
                y = y_vec(i);
                %if (x > 2 && x< size(greymatter,1)-1 && y > 2 && y < size(greymatter, 2)-1)
                neighborhood = greymatter(x-search_radius:x+search_radius,y-search_radius:y+search_radius,z-search_radius:z+search_radius);
                %neighborhood = neighborhood(neighborhood > 0); %Cut out the Zeros and Ones
                
                [m,f,c] = mode(neighborhood(:));
                %end

                if(size(c{1},1) == 1) %If there are two mode-values (or more) we skip this point and hopefully the situation gets cleared during a further cycle
                    nb_store(indx,:) = [x y z m f];
                    indx = indx + 1;
                end
            end
        end
%         %display(['Progress: ',num2str(x),' / ',num2str(size(greymatter,1)-2),' Slices'])
    end
    
    
    %Select the Voxels with the most frequent mode-values and set them to
    %their ROI-Values. Afterwards start again...
    result = sortrows(nb_store(nb_store(:,5) >= lvl_of_uncertainty,:),-5);
    freqs = sortrows(unique(result(:,5)),-1);
    
    for f = 1:length(freqs)
        temp1 = result(result(:,5) == freqs(f),:);
        
        %Check fo conflicts with the Voxels already assigned this cycle
        %i.e. if there's a Voxel within the searchlight which was already
        %assigend this cycle skip the current Voxel
        if (f > 1)
            [ind,dist] = knnsearch(result((result(:,5) > freqs(f)),:),temp1);
           temp1(ind(floor(dist) == search_radius),:) = [];
        end
        
        for x = 1:size(temp1,1)
            greymatter(temp1(x,1),temp1(x,2),temp1(x,3)) = temp1(x,4);
        end
    end
end

clear x y z m f result freqs dist

aseg.img = greymatter;
save_nii(aseg,[subDir '/GM_roied.nii'])
%Gzip the Files (saves lots of storage space but may slow down the process)
%compress([subDir '/GM_roied.nii']);

%DELETEME
% greymatter = load_nii([subDir '/GM_roied.nii.gz']);
% greymatter = greymatter.img;
%DELETEME

%Project the Regions onto the Whitematter-Outline
%wm_outline.img = wm_outline.img + edge_subcort;
%Binarize again
wm_outline.img(wm_outline.img > 1) = 1;
%Clear wm_outline from Voxels that don't belong to GM or WM (i.e. CC or
%Subcort etc.)
wm_outline.img(nii.img == 0) = 0;

haystack = zeros(nnz(greymatter),3);
nnz(greymatter)
needle = zeros(nnz(wm_outline.img),3);
nnz(greymatter)

%wm_outline and greymatter must have the same img_size!
%Go through the Greymatter/wm_outline to build the index
%This part could be included to the MAINLOOP for the sake of faster
%computation!
hay_count = 1;
needle_count = 1;
size(greymatter)
size(wm_outline.img)

if size(greymatter,1) > size(wm_outline.img,1)
  len_x = size(wm_outline.img,1)
else
  len_x = size(wm_outline.img,1)
end

if size(greymatter,2) > size(wm_outline.img,2)
  len_y = size(wm_outline.img,2)
else
  len_y = size(wm_outline.img,2)
end

if size(greymatter,3) > size(wm_outline.img,3)
  len_z = size(wm_outline.img,3)
else
  len_z = size(wm_outline.img,1)
end


for x = 3:(len_x-3)
   if (max(max(greymatter(x,:,:))) > 0 && max(max(wm_outline.img(x,:,:))) > 0) %Skip the next loops if the whole slice is zero anyway
       for y = 3:(len_y-3)
          for z = 3:(len_z-3)
             if (greymatter(x,y,z) > 0)
                 haystack(hay_count,:) = [x y z];
                 hay_count = hay_count + 1;
             end
             if (wm_outline.img(x,y,z) > 0)
                 needle(needle_count,:) = [x y z];
                 needle_count = needle_count + 1;
             end
          end
       end
   end
end


%we need substract one from counter
[IDX,D] = knnsearch(needle(1:(needle_count-1),:),haystack(1:(hay_count-1),:));
hay_count
needle_count
size(IDX)
size(D)
%Set all Values in the wm_outline that have no match within X Voxel
%Distance to Zero (i.e. the Subcortical border...)
VoxelDist = 1.5;

I = find(D > VoxelDist);
if ~isempty(I)
max(I)
min(I)
size(I) 
for x = 1:size(I,1)
    wm_outline.img(needle(I(x),1),needle(I(x),2),needle(I(x),3)) = 0;
end
end

%Assign each remaing value it's nearest Neighbour from the GM-Parcellation
I = find(D <= VoxelDist);
if ~isempty(I) 
for x = 1:size(I,1)
    wm_outline.img(needle(I(x),1),needle(I(x),2),needle(I(x),3)) = greymatter(haystack(IDX(I(x)),1),haystack(IDX(I(x)),2),haystack(IDX(I(x)),3));
end
end

clear hay_count x y z needle_count IDX I D needle haystack
save_nii(wm_outline,[subDir '/wm_outline_roied.nii'])
%Gzip the Files (saves lots of storage space but may slow down the process)
%compress([subDir '/wm_outline_roied.nii']);

toc

%% Quality Check
rmask = load_untouch_nii([subDir '/rmask.nii']);
greymatter = load_untouch_nii([subDir '/GM_roied.nii']);
uncorr = load_untouch_nii([subDir '/warped_rmask_2_t1.nii']);

roi_sizes_glebs = zeros(97,2);
roi_sizes_glebs(:,1) = unique(rmask.img);
roi_sizes_glebs(1,:) = []; %Clear the Zero

roi_sizes_warp = zeros(96,2);
roi_sizes_warp(:,1) = unique(uncorr.img(uncorr.img > 0)); 

roi_sizes_alg = zeros(97,2);
roi_sizes_alg(:,1) = unique(greymatter.img);
roi_sizes_alg(1,:) = []; %Clear the Zero

for i = 1:96
    roi_sizes_glebs(i,2) = sum(sum(sum(rmask.img == roi_sizes_glebs(i,1))));
    roi_sizes_warp(i,2) = sum(sum(sum(uncorr.img == roi_sizes_warp(i,1))));
    roi_sizes_alg(i,2) = sum(sum(sum(greymatter.img == roi_sizes_alg(i,1))));
end

roi_sizes_relative = [roi_sizes_glebs(:,2)./sum(roi_sizes_glebs(:,2)) roi_sizes_warp(:,2)./sum(roi_sizes_warp(:,2)) roi_sizes_alg(:,2)./sum(roi_sizes_alg(:,2))];
sizes_glebs = zeros(96,96);
sizes_alg = zeros(96,96);
for i = 1:96
    for j = 1:96
        sizes_glebs(i,j) = roi_sizes_glebs(i,2)/roi_sizes_glebs(j,2);
        sizes_alg(i,j) = roi_sizes_alg(i,2)/roi_sizes_alg(j,2);
    end
end
%sizes_glebs = roi_sizes_glebs(:,2)*(roi_sizes_glebs(:,2).^-1)';
%sizes_alg = roi_sizes_alg(:,2)*(roi_sizes_alg(:,2).^-1)';
% subplot(2,2,1)
% imagesc(sizes_glebs)
% title('Glebs')
% colorbar;
% 
% subplot(2,2,2)
% imagesc(sizes_alg)
% title('Calculated')
% colorbar;
% 
% subplot(2,2,3)
% imagesc(abs(sizes_alg - sizes_glebs))
% title('Absolute difference')
% colorbar;
% 
% subplot(2,2,4)
width1 = 0.7;
barh(roi_sizes_relative(:,1)*100,width1,'FaceColor',[1,0.3,0],'EdgeColor','none');
axis tight
hold on
barh(roi_sizes_relative(:,2)*100,width1/2,'FaceColor',[0.3,1,0.3],'EdgeColor','none');
barh(roi_sizes_relative(:,3)*100,width1/4,'FaceColor',[0,0.7,0.7],'EdgeColor','none');
legend('Original Gleb-Parcellation (MNI space)','Warped Gleb-Parcellation (Subject anat. space)','Refined Gleb-Parcellation (Subject anat. space)')
ylabel('Ordered Regions')
xlabel('% of all parcellation-voxels')
title('Relative occupation of the single ROIs before and after the correction')

%Check how much voxels hit actual GM-Parts BEFORE correction (i.e. just
%right after warping)
gm_bin = greymatter.img;
gm_bin(gm_bin > 0) = 1;
tmp = uncorr.img.*single(gm_bin);
failureVoxels = 1 - (nnz(tmp)/nnz(uncorr.img));

end

% function compress(fileName)
%     %Gzip the Files (saves lots of storage space but may slow down the process)
%     gzip({fileName})
%     delete(fileName)
% end
