function prep_data_mt

%% Get file locs
locations = fc_toolbox_locs;
results_folder = [locations.main_folder,'results/'];
edf_path = [results_folder,'edf_summ_out/'];
sleep_stage_path = [results_folder,'edf_out/'];
out_folder = [results_folder,'analysis/new_outcome/data/'];
if ~exist(out_folder,'dir')
    mkdir(out_folder)
end

% add script folder to path
scripts_folder = locations.script_folder;
addpath(genpath(scripts_folder));

%% Load the current output file
data = load([out_folder,'main_out.mat']);
data = data.out;
all_names = data.all_names;
npts = length(all_names);

% Goal is to build in same structure
% Structure is which montage, then all vs wake vs sleep
all_coh = cell(npts,3,3);
all_bp = cell(npts,3,3);
all_spikes = cell(npts,3,3);
all_rl = cell(npts,3,3);
all_pearson = cell(npts,3,3);
all_plv = cell(npts,3,3);
all_labels = cell(npts,3);
all_se = cell(npts,3,3);
all_re = cell(npts,3,3);
all_xcor = cell(npts,3,3);
all_lags = cell(npts,3,3);
all_ll = cell(npts,3,3);
all_rel_bp = cell(npts,3,3);
all_coh_iqr = cell(npts,3,3);
all_bp_iqr = cell(npts,3,3);
all_spikes_iqr = cell(npts,3,3);
all_rl_iqr = cell(npts,3,3);
all_pearson_iqr = cell(npts,3,3);
all_plv_iqr = cell(npts,3,3);
all_se_iqr = cell(npts,3,3);
all_re_iqr = cell(npts,3,3);
all_xcor_iqr = cell(npts,3,3);
all_lags_iqr = cell(npts,3,3);
all_rel_bp_iqr = cell(npts,3,3);
all_ll_iqr = cell(npts,3,3);


%% Loop over patients
for p = 1:npts

    name = all_names{p};

    % Load the edf summary file
    if exist([edf_path,name,'/summ.mat'],'file') == 0, continue; end
    info = load([edf_path,name,'/summ.mat']);
    info = info.out;

    % get the time varying measurements
    spike_counts = info.all_spike_counts;
    rl = info.all_rl;
    bp = info.all_bp;
    rel_bp = info.all_rel_bp;
    coh = info.all_coh;
    re = info.all_re;
    pc = info.all_pc;
    xcor = info.all_xcor;
    lags = info.all_lags;
    se = info.all_se;
    times = info.all_times;
    labels = info.montage_labels;
    ll = info.all_ll;
    
    fs = info.fs;
    plv = info.all_plv;

    rl  = rl/fs;

    % fill labels
    all_labels{p,1} = labels{1,1};
    all_labels{p,2} = labels{2,1};
    all_labels{p,3} = labels{3,1};

    % also load the sleep stages
    stage = load([sleep_stage_path,name,'/sleep_stage.mat']);
    sout = stage.sout;

    % Get times of sleep transitions
    st_dates= sout.Summary(2:end,2);
    st_times = sout.Summary(2:end,3);
    stage = sout.Summary(2:end,4);

    % convert to seconds in ieeg
    seeg_secs = convert_transitions_to_ieeg_secs(st_dates,st_times);

    % get the sleep stages for appropriate times
    [~,seeg_stage] = match_seeg_times(times(:,1),ones(size(times,1),1),seeg_secs,stage);

    sleep = strcmp(seeg_stage,'N3') | strcmp(seeg_stage,'N2');% | ...
        %strcmp(seeg_stage,'N1') | strcmp(seeg_stage,'R');
    wake = strcmp(seeg_stage,'W');

    % Save all, wake, and sleep
    for im = 1:3
        all_coh{p,im,1} = squeeze(nanmean(coh(:,im,:,:,:),1));
        all_coh{p,im,2} = squeeze(nanmean(coh(wake,im,:,:,:),1));
        all_coh{p,im,3} = squeeze(nanmean(coh(sleep,im,:,:,:),1));

        all_plv{p,im,1} = squeeze(nanmean(plv(:,im,:,:,:),1));
        all_plv{p,im,2} = squeeze(nanmean(plv(wake,im,:,:,:),1));
        all_plv{p,im,3} = squeeze(nanmean(plv(sleep,im,:,:,:),1));

        all_re{p,im,1} = squeeze(nanmean(re(:,im,:,:,:),1));
        all_re{p,im,2} = squeeze(nanmean(re(wake,im,:,:,:),1));
        all_re{p,im,3} = squeeze(nanmean(re(sleep,im,:,:,:),1));
    
        all_spikes{p,im,1} = squeeze(nanmean(spike_counts(:,im,:),1));
        all_spikes{p,im,2} = squeeze(nanmean(spike_counts(wake,im,:),1));
        all_spikes{p,im,3} = squeeze(nanmean(spike_counts(sleep,im,:),1));
    
        all_pearson{p,im,1} = squeeze(nanmean(pc(:,im,:,:),1));
        all_pearson{p,im,2} = squeeze(nanmean(pc(wake,im,:,:),1));
        all_pearson{p,im,3} = squeeze(nanmean(pc(sleep,im,:,:),1));

        all_xcor{p,im,1} = squeeze(nanmean(xcor(:,im,:,:),1));
        all_xcor{p,im,2} = squeeze(nanmean(xcor(wake,im,:,:),1));
        all_xcor{p,im,3} = squeeze(nanmean(xcor(sleep,im,:,:),1));
    
        all_lags{p,im,1} = squeeze(nanmean(lags(:,im,:,:),1));
        all_lags{p,im,2} = squeeze(nanmean(lags(wake,im,:,:),1));
        all_lags{p,im,3} = squeeze(nanmean(lags(sleep,im,:,:),1));

        all_rl{p,im,1} = squeeze(nanmean(rl(:,im,:),1));
        all_rl{p,im,2} = squeeze(nanmean(rl(wake,im,:),1));
        all_rl{p,im,3} = squeeze(nanmean(rl(sleep,im,:),1));

        all_se{p,im,1} = squeeze(nanmean(se(:,im,:),1));
        all_se{p,im,2} = squeeze(nanmean(se(wake,im,:),1));
        all_se{p,im,3} = squeeze(nanmean(se(sleep,im,:),1));
    
        all_bp{p,im,1} = squeeze(nanmean(bp(:,im,:,:),1));
        all_bp{p,im,2} = squeeze(nanmean(bp(wake,im,:,:),1));
        all_bp{p,im,3} = squeeze(nanmean(bp(sleep,im,:,:),1));

        all_rel_bp{p,im,1} = squeeze(nanmean(rel_bp(:,im,:,:),1));
        all_rel_bp{p,im,2} = squeeze(nanmean(rel_bp(wake,im,:,:),1));
        all_rel_bp{p,im,3} = squeeze(nanmean(rel_bp(sleep,im,:,:),1));

        all_ll{p,im,1} = squeeze(nanmean(ll(:,im,:,:),1));
        all_ll{p,im,2} = squeeze(nanmean(ll(wake,im,:,:),1));
        all_ll{p,im,3} = squeeze(nanmean(ll(sleep,im,:,:),1));

        %% Also measure STD

        all_coh_iqr{p,im,1} = squeeze(nanstd(coh(:,im,:,:,:),[],1));
        all_coh_iqr{p,im,2} = squeeze(nanstd(coh(wake,im,:,:,:),[],1));
        all_coh_iqr{p,im,3} = squeeze(nanstd(coh(sleep,im,:,:,:),[],1));

        all_plv_iqr{p,im,1} = squeeze(nanstd(plv(:,im,:,:,:),[],1));
        all_plv_iqr{p,im,2} = squeeze(nanstd(plv(wake,im,:,:,:),[],1));
        all_plv_iqr{p,im,3} = squeeze(nanstd(plv(sleep,im,:,:,:),[],1));

        all_re_iqr{p,im,1} = squeeze(nanstd(re(:,im,:,:,:),[],1));
        all_re_iqr{p,im,2} = squeeze(nanstd(re(wake,im,:,:,:),[],1));
        all_re_iqr{p,im,3} = squeeze(nanstd(re(sleep,im,:,:,:),[],1));
    
        all_spikes_iqr{p,im,1} = squeeze(nanstd(spike_counts(:,im,:),[],1));
        all_spikes_iqr{p,im,2} = squeeze(nanstd(spike_counts(wake,im,:),[],1));
        all_spikes_iqr{p,im,3} = squeeze(nanstd(spike_counts(sleep,im,:),[],1));
    
        all_pearson_iqr{p,im,1} = squeeze(nanstd(pc(:,im,:,:),[],1));
        all_pearson_iqr{p,im,2} = squeeze(nanstd(pc(wake,im,:,:),[],1));
        all_pearson_iqr{p,im,3} = squeeze(nanstd(pc(sleep,im,:,:),[],1));

        all_xcor_iqr{p,im,1} = squeeze(nanstd(xcor(:,im,:,:),[],1));
        all_xcor_iqr{p,im,2} = squeeze(nanstd(xcor(wake,im,:,:),[],1));
        all_xcor_iqr{p,im,3} = squeeze(nanstd(xcor(sleep,im,:,:),[],1));
    
        all_lags_iqr{p,im,1} = squeeze(nanstd(lags(:,im,:,:),[],1));
        all_lags_iqr{p,im,2} = squeeze(nanstd(lags(wake,im,:,:),[],1));
        all_lags_iqr{p,im,3} = squeeze(nanstd(lags(sleep,im,:,:),[],1));

        all_rl_iqr{p,im,1} = squeeze(nanstd(rl(:,im,:),[],1));
        all_rl_iqr{p,im,2} = squeeze(nanstd(rl(wake,im,:),[],1));
        all_rl_iqr{p,im,3} = squeeze(nanstd(rl(sleep,im,:),[],1));

        all_se_iqr{p,im,1} = squeeze(nanstd(se(:,im,:),[],1));
        all_se_iqr{p,im,2} = squeeze(nanstd(se(wake,im,:),[],1));
        all_se_iqr{p,im,3} = squeeze(nanstd(se(sleep,im,:),[],1));
    
        all_bp_iqr{p,im,1} = squeeze(nanstd(bp(:,im,:,:),[],1));
        all_bp_iqr{p,im,2} = squeeze(nanstd(bp(wake,im,:,:),[],1));
        all_bp_iqr{p,im,3} = squeeze(nanstd(bp(sleep,im,:,:),[],1));

        all_rel_bp_iqr{p,im,1} = squeeze(nanstd(rel_bp(:,im,:,:),[],1));
        all_rel_bp_iqr{p,im,2} = squeeze(nanstd(rel_bp(wake,im,:,:),[],1));
        all_rel_bp_iqr{p,im,3} = squeeze(nanstd(rel_bp(sleep,im,:,:),[],1));

        all_ll_iqr{p,im,1} = squeeze(nanstd(ll(:,im,:,:),[],1));
        all_ll_iqr{p,im,2} = squeeze(nanstd(ll(wake,im,:,:),[],1));
        all_ll_iqr{p,im,3} = squeeze(nanstd(ll(sleep,im,:,:),[],1));
    end

end

%% Save
out.all_names = all_names;
out.all_labels = all_labels;
out.all_coh = all_coh;
out.all_spikes = all_spikes;
out.all_rl = all_rl;
out.all_pearson = all_pearson;
out.all_bp = all_bp;
out.all_plv = all_plv;
out.all_re = all_re;
out.all_se = all_se;
out.all_rel_bp = all_rel_bp;
out.all_xcor = all_xcor;
out.all_lags = all_lags;
out.all_ll = all_ll;
out.all_coh_iqr = all_coh_iqr;
out.all_spikes_iqr = all_spikes_iqr;
out.all_rl_iqr = all_rl_iqr;
out.all_pearson_iqr = all_pearson_iqr;
out.all_bp_iqr = all_bp_iqr;
out.all_plv_iqr = all_plv_iqr;
out.all_re_iqr = all_re_iqr;
out.all_se_iqr = all_se_iqr;
out.all_rel_bp_iqr = all_rel_bp_iqr;
out.all_xcor_iqr = all_xcor_iqr;
out.all_lags_iqr = all_lags_iqr;
out.all_ll_iqr = all_ll_iqr;

save([out_folder,'mt_out.mat'],'out')

end