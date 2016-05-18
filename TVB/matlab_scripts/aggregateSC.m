function aggregateSC(outfile,wmborder_file, subID)
%Parameters:
%   outfile - String; Filename of the resulting File, e.g. 'subDA_SC.mat'
%   wmborder - .mat-File; 3D-Array containing the Imagecube of the
%               parcellated gmwmborder
%   subID - String; The Identiefier of the Subject, e.g. 'DA'


steplength=0.2;
wmborder.img = load(wmborder_file);
region_table = [2:42 51:53 61:64 102:142 151:153 161:164];
counter=0;
%inverse_region_table = zeros(1,2035);
%region_id_table = zeros(nnz(wmborder.img.img),2);
region_id_table=[];
for regid = [2:42 51:53 61:64 102:142 151:153 161:164],
    counter=counter+1;
    inverse_region_table(regid) = counter; %Transfer table between DK-Numbering and Matrix Numbering
    tmpids=find(wmborder.img.img == regid);
    region_id_table=[region_id_table; regid*ones(length(tmpids),1), tmpids];    
end
SC_cap_agg_tmp(length(region_id_table)).e=[];
SC_dist_agg_tmp(length(region_id_table)).e=[];

SC_cap_agg_bwflav1 = zeros(size(region_table,2),size(region_table,2));
SC_cap_agg_bwflav2 = zeros(size(region_table,2),size(region_table,2));
SC_cap_agg_counts = zeros(size(region_table,2),size(region_table,2));
SC_dist_agg(size(region_table,2),size(region_table,2)).dist=[];
SC_dist_median_agg = zeros(size(region_table,2),size(region_table,2));
SC_dist_mean_agg = zeros(size(region_table,2),size(region_table,2));
SC_dist_var_agg = zeros(size(region_table,2),size(region_table,2));
SC_dist_mode_agg = zeros(size(region_table,2),size(region_table,2));

%New Dist aggregation
SC_dist_agg_new(size(region_table,2),size(region_table,2)).dist=[];
SC_dist_median_agg_new=zeros(size(region_table,2),size(region_table,2));
SC_dist_mean_agg_new=zeros(size(region_table,2),size(region_table,2));

for roi = 1:size(region_table,2),
    clear SC_cap SC_dist
    
    display(['Processing ROI: ' num2str(roi)]);
    
    load(['SC_row_' num2str(roi) subID '.mat'])
    
    for ind_ind=1:length(region_id_table),
        SC_cap_agg_tmp(ind_ind).e=[SC_cap_agg_tmp(ind_ind).e;SC_cap(ind_ind).e];
        SC_dist_agg_tmp(ind_ind).e=[SC_dist_agg_tmp(ind_ind).e;SC_dist_new(ind_ind).e]; 
    end
    
    for roi2 = 1:size(region_table,2),
        SC_dist_agg(roi,roi2).dist=[SC_dist_agg(roi,roi2).dist;SC_dist(roi,roi2).dist];
        SC_dist_agg(roi2,roi).dist=[SC_dist_agg(roi2,roi).dist;SC_dist(roi2,roi).dist];
    end
end

for ind_ind=1:length(region_id_table),
    [SC_cap_agg_tmp(ind_ind).e,ia,~]=unique(SC_cap_agg_tmp(ind_ind).e);
     SC_dist_agg_tmp(ind_ind).e=SC_dist_agg_tmp(ind_ind).e(ia);
    
    seed_id=find(region_table==region_id_table(ind_ind,1));
    target_ids=inverse_region_table(region_id_table(SC_cap_agg_tmp(ind_ind).e,1));
    for ti=1:length(target_ids),
        SC_cap_agg_bwflav1(seed_id,target_ids(ti)) = SC_cap_agg_bwflav1(seed_id,target_ids(ti)) + 1;
        SC_cap_agg_bwflav2(seed_id,target_ids(ti)) = SC_cap_agg_bwflav2(seed_id,target_ids(ti)) + (1/(length(target_ids)));
         SC_dist_agg_new(seed_id,target_ids(ti)).dist = [SC_dist_agg_new(seed_id,target_ids(ti)).dist SC_dist_agg_tmp(ind_ind).e(ti)];

    end
end
 
for roi = 1:size(region_table,2),
    for roi2 = 1:size(region_table,2),
        if ~isempty(SC_dist_agg(roi,roi2).dist),
            SC_dist_agg(roi,roi2).dist=SC_dist_agg(roi,roi2).dist*steplength;
            SC_cap_agg_counts(roi,roi2) = length(SC_dist_agg(roi,roi2).dist);
            SC_dist_median_agg(roi,roi2) = median(SC_dist_agg(roi,roi2).dist);
            SC_dist_mean_agg(roi,roi2) = mean(SC_dist_agg(roi,roi2).dist);
            SC_dist_var_agg(roi,roi2) = var(SC_dist_agg(roi,roi2).dist);
            SC_dist_mode_agg(roi,roi2) = mode(SC_dist_agg(roi,roi2).dist);
        end
        
        if ~isempty(SC_dist_agg_new(roi,roi2).dist),
            SC_dist_agg_new(roi,roi2).dist=SC_dist_agg_new(roi,roi2).dist*steplength;
            %SC_cap_agg_counts(roi,roi2) = length(SC_dist_agg(roi,roi2).dist);
            SC_dist_median_agg_new(roi,roi2) = median(SC_dist_agg_new(roi,roi2).dist);
            SC_dist_mean_agg_new(roi,roi2) = mean(SC_dist_agg_new(roi,roi2).dist);
            %SC_dist_var_agg(roi,roi2) = var(SC_dist_agg(roi,roi2).dist);
            %SC_dist_mode_agg(roi,roi2) = mode(SC_dist_agg(roi,roi2).dist);
        end

     end
end



%Normalize the Cap.Matrices
numTracks = sum(SC_cap_agg_counts(:));
avgSeedingVoxels = 1; %Average over 50 Subjects
SC_cap_agg_counts_norm = SC_cap_agg_counts / numTracks * avgSeedingVoxels;
SC_cap_agg_bwflav1_norm = SC_cap_agg_bwflav1 / numTracks * avgSeedingVoxels;
SC_cap_agg_bwflav2_norm = SC_cap_agg_bwflav2 / numTracks * avgSeedingVoxels;

%Log
SC_cap_agg_counts_log = log(SC_cap_agg_counts_norm+1);
SC_cap_agg_bwflav1_log = log(SC_cap_agg_bwflav1_norm+1);
SC_cap_agg_bwflav2_log = log(SC_cap_agg_bwflav2_norm+1);

save(outfile,'-mat7-binary','SC_dist_median_agg_new','SC_dist_mean_agg_new','SC_cap_agg_counts', 'SC_cap_agg_bwflav1','SC_cap_agg_bwflav2','SC_cap_agg_counts_norm','SC_cap_agg_bwflav1_norm', 'SC_cap_agg_bwflav2_norm','SC_cap_agg_counts_log','SC_cap_agg_bwflav1_log','SC_cap_agg_bwflav2_log','SC_dist_agg', 'SC_dist_mean_agg', 'SC_dist_mode_agg', 'SC_dist_median_agg', 'SC_dist_var_agg')


