function mt_patient_stitch(edf_path,name,overwrite)

%% Seed random number generator so that I get the same result each time I do this.
rng(0)

%% See if I've done it
if exist([edf_path,name,'/summ.mat'],'file')~=0
    if overwrite == 0
        fprintf('\nAlready did %s, skipping.\n',name);
        return
    else
        fprintf('\nOverwriting %s.\n',name);
    end
end

%% Load meta
meta = load([edf_path,name,'/meta.mat']);
meta = meta.meta;
times = meta.times;

%% Get allowable labels
allowable_labels = get_allowable_elecs;

%% Find labels that match allowable electrodes
% Load first file to get labels
info = edfinfo([edf_path,name,sprintf('/file%d.edf',1)]);
labels = cellstr(info.SignalLabels);
allowed = ismember(labels,allowable_labels);
allowed_labels = labels(allowed);
nallowed = sum(allowed);

if nallowed == 0
    fprintf('\n No allowed electrodes for %s, skipping.\n',name);
    return
end

% Loop over files
nfiles = 72;
nmontages = 3;
all_times = nan(nfiles,2);
all_bp = nan(nfiles,nmontages,nallowed,5);
all_spike_counts = nan(nfiles,nmontages,nallowed);
all_pc = nan(nfiles,nmontages,nallowed,nallowed);
all_coh = nan(nfiles,nmontages,nallowed,nallowed,6);
all_plv = nan(nfiles,nmontages,nallowed,nallowed,6);
all_ad = nan(nfiles,nmontages,nallowed);
all_rl = nan(nfiles,nmontages,nallowed);
all_spike_times = cell(nmontages,1);
montages = cell(nmontages,3);
montage_labels = cell(nmontages,3);
all_is_run = nan(nfiles,nmontages,nallowed);

for f = 18%1:nfiles
    file_path = [edf_path,name,sprintf('/file%d.edf',f)];
    tic
    fprintf('\nDoing %s file %d of %d...',name,f,nfiles);

    %% Do the individual run
    out = individual_run_mt(file_path);
    fprintf('took %1.1f s\n',toc);

    %% Figure out times
    file_times = out.times;
    abs_times = times(f,1) + file_times;
    all_times(f,:) = abs_times;

    %% Figure out labels
    assert(isequal(allowed_labels,out.clean_labels))
    
    for im = 1:nmontages
        %% Stitch together
        % Get spikes
        gdf = out.montage(im).gdf;
        
        if ~isempty(gdf)
        % re-align index to file index
            gdf(:,2) = gdf(:,2) + out.idx(1) -1; % if gdf index is 1, that means it occurs at rand_start;
        end
    
        % save spike times (for future error checking and plotting)
        all_spike_times{im} = [all_spike_times{im};gdf repmat(f,size(gdf,1),1)];
    
        % get spike counts
        if ~isempty(gdf)
            X = gdf(:,1); % get channels
            spike_counts = accumarray(X, ones(size(X)), [nallowed 1], @sum); % this gets the count of spikes for each channe;
            
            % make skipped channels nans rather than zeros
            spike_counts(out.montage(im).skip) = nan;
            all_spike_counts(f,im,:) = spike_counts;
        else
            all_spike_counts(f,im,:) = 0;
        end
    
        % get RL
        if ~isempty(gdf)
            timing = gdf(:,3);
            % take the mean timing for each channel
            rl = accumarray(X, timing, [nallowed 1], @mean,nan); % if no spikes, make this nan
            all_rl(f,im,:) = rl;
        else
            all_rl(f,im,:) = nan;
        end
    
        % get the other stuff
        all_bp(f,im,:,:) = out.montage(im).bp;
        all_pc(f,im,:,:) = out.montage(im).pc;
        all_coh(f,im,:,:,:) = out.montage(im).coh;
        all_plv(f,im,:,:,:) = out.montage(im).plv;
        all_ad(f,im,:) = out.montage(im).ad;
        all_is_run(f,im,:) = out.montage(im).is_run;

        montages{im} = out.montage(im).name;
        montage_labels{im} = out.montage(im).labels;
    end


end

%% Plot random spike detections
for im = 1:nmontages
    plot_random_spikes(all_spike_times{im},name,out.clean_labels,montages{im},edf_path)
end

%% Output the stuff
nout.all_times = all_times;
nout.all_bp = all_bp;
nout.all_spike_counts = all_spike_counts;
nout.all_pc = all_pc;
nout.all_coh = all_coh;
nout.all_ad = all_ad;
nout.all_plv = all_plv;
nout.all_rl = all_rl;
nout.all_spike_times = all_spike_times;
nout.fs = out.fs;
nout.edf_path = edf_path;
nout.name = name;
nout.labels = out.clean_labels;
nout.montage_labels = montage_labels;
nout.all_is_run = all_is_run;
nout.montages = montages;

out = nout;

%% Save the file
save([edf_path,name,'/summ.mat'],'out');

end