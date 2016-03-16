function computeSC_cluster(numROI,tck_filestem,tck_suffix,wmborder_file,roi,outfile)
%tic
display(['Computing SC for ROI ' num2str(roi) '.']);
load(['../masks_' numROI '/affine_matrix.mat'])

wmborder.img = load(wmborder_file);
region_table = [2:42 51:53 61:64 102:142 151:153 161:164];
region_id_table=[];
for regid = [2:42 51:53 61:64 102:142 151:153 161:164],
    tmpids=find(wmborder.img.img == regid);
    region_id_table=[region_id_table; regid*ones(length(tmpids),1), tmpids];    
end
SC_cap(length(region_id_table)).e=[];
SC_dist(length(region_table),length(region_table)).dist=[];

% Count the numbers of failure tracks
off_seed=0;
too_short=0;
good_tracks=0;
wrong_seed=0;
expected_tracks=0;
wrong_target=0;
generated_tracks=0;

% Loop over regions
for region = roi,
    
    expected_tracks=expected_tracks+length(find(wmborder.img.img==region_table(region)))*200;    
    tilefiles = dir([num2str(region_table(region)) '*.tck']);
    
    for tile = 1:length(tilefiles),
        if tilefiles(tile).bytes > 2000,
            clear tck tracks
            tck = read_mrtrix_tracks(tilefiles(tile).name);

            tracks = tck2voxel_cluster(tck,affine_matrix);
            display([tilefiles(tile).name ': Tracks loaded.']);
            generated_tracks = generated_tracks + length(tracks.data);

            % Loop over tracks
            for trackind = 1:length(tracks.data),
                % Find the "actual" seed-voxel: sometimes a track starts in a seed
                % voxel then heads into the wm and crosses another voxel of the
                % seeding-region. In this case we consider the last voxel on the
                % track path belonging to the seed region as the actual seed voxel.
                % Then we check whether the remaining path length is at least 10 mm
                % long.
                
                %Generate Linear indices in the 256x256x256-Imagecube from
                %all the voxels of the current track
                pathinds=sub2ind(size(wmborder.img.img),tracks.data{1,trackind}(:,1),tracks.data{1,trackind}(:,2),tracks.data{1,trackind}(:,3));
                %Fetch the corresponding Region-IDs from the WM-Border
                pathids=wmborder.img.img(pathinds);
                %Generate linear Indices from all the Regions that are not
                %Zero-valued, EXCLUDING THE END-POINT!
                inregids=find(pathids(1:end-1)~=0);
                
                if ~isempty(inregids), %Check if the Path has Points on the Border
                    tracklen=size(tracks.data{1,trackind},1)-inregids(end); %Measure the length from the Endpoint to the last Point that exits the starting Region
                    if tracklen > 40, %Check if the track has a minimum length (step-size is 0.2mm)
                        if pathids(end) ~= 0, %Check if the Path has a valid endpoint
                            if region_table(region) == pathids(inregids(end)), %Check if the Region-ID requested matches the Seedpoint-Region
                                good_tracks=good_tracks+1; %"[...] when you have eliminated the impossible, whatever remains, however improbable, must be the truth" 

                                seed_id=find(region_id_table(:,2) == pathinds(inregids(end)));
                                target_id = find(region_id_table(:,2)==pathinds(end));

                                SC_cap(seed_id).e=[SC_cap(seed_id).e;target_id]; %Add a Connection from Seedvoxel to Targetvoxel
                                SC_cap(target_id).e=[SC_cap(target_id).e;seed_id]; %Add a Connection from Targetvoxel to Seedvoxel

                                r1=find(region_table==pathids(end)); %Transfer the Indexnr. from Desikan-Numbering (i.e. 1001-2035) to a Matrix-Numbering (i.e. 1-68)
                                r2=find(region_table==pathids(inregids(end)));

                                SC_dist(r1,r2).dist=[SC_dist(r1,r2).dist;tracklen]; %Add the distance of the current track to a pool of distances between the two ROIS
                                SC_dist(r2,r1).dist=[SC_dist(r2,r1).dist;tracklen];

                            else
                                wrong_seed=wrong_seed+1;
                                %display('Error. Region mismatch.');
                            end

                        else
                            wrong_target=wrong_target+1;
                        end
                    else
                        too_short=too_short+1;
                    end
                else
                    off_seed=off_seed+1;
                end

            end
        end
    end
end

for i = 1:length(region_id_table),
    SC_cap(i).e=unique(SC_cap(i).e); %Filter out the redundant connections i.e. just count distinct connections    
end

%time=toc;

save(outfile,'SC_cap', 'SC_dist', 'off_seed', 'too_short', 'good_tracks', 'wrong_seed', 'expected_tracks', 'wrong_target', 'generated_tracks','time')

%Increase the counter
%count = dlmread('count.txt');
%dlmwrite('count.txt',count+1)

end

