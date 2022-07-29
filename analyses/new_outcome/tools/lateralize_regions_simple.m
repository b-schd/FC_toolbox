function atlas_lat = lateralize_regions_simple(atlas_names)

atlas_lat = cell(length(atlas_names),1);
for i = 1:length(atlas_names)
    curr = atlas_names{i};
    if strcmp(curr(end),'L')
        atlas_lat{i} = 'L';
    elseif strcmp(curr(end),'R')
        atlas_lat{i} = 'R';
    end
    
end

end