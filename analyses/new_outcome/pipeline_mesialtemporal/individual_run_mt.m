function out = individual_run_mt(file_path)

%% Parameters
show_data = 0;
test_flag = 0;
tw = 2;

%% Load the edf file
C = strsplit(file_path,'/');
name = C{end-1};
info = edfinfo(file_path);

%% Get basic info
samples_per_time = info.NumSamples(1,1);
num_samples = samples_per_time*info.NumDataRecords;
fs = round(info.NumSamples(1,1)/seconds(info.DataRecordDuration));
labels = cellstr(info.SignalLabels);

%% get allowable electrodes
potentially_allowable_labels = get_allowable_elecs;

%% Find labels that match allowable electrodes and have symmetric coverage
allowed_labels = find_mt_symmetric_coverage(labels,potentially_allowable_labels);
if isempty(allowed_labels)
    out = [];
    return
end
nallowed = length(allowed_labels);
%{
allowed = ismember(labels,allowable_labels);
allowed_labels = labels(allowed);
nallowed = sum(allowed);

%% Skip if not left and right
if sum(contains(allowed_labels,'L'))==0 || sum(contains(allowed_labels,'R'))==0
    out = [];
    %return
end
%}

%% Initialize values
values = nan(num_samples,nallowed);

% Separately call edfread for each signal
for is = 1:nallowed
    curr_signal = allowed_labels{is};
    
    % Get timetable for that signal
    T = edfread(file_path,'SelectedSignals',curr_signal);
      
    % Get variable name (may be changed once put into table)
    Var1 = T.Properties.VariableNames{1};
    
    %% Convert the time table to an array
    temp_values = nan(num_samples,1);

    % Loop over segments
    for s = 1:size(T,1)
        seg = T.(Var1){s};

        % Where are we in the temp values
        start_idx = (s-1)*samples_per_time+1;
        end_idx = s*samples_per_time;

        % Fill up values
        temp_values(start_idx:end_idx) = seg;
    end
    
    %% Fill up values
    values(:,is) = temp_values;
    
end

%% Get times
nsamples = size(T,1)*samples_per_time;
times = linspace(0,num_samples/fs,nsamples);

%% Take a random one minute segment
max_start = length(times) - fs*60-1; % must start 60 seconds before the end
rand_start = randi(round(max_start));
rand_end = rand_start + round(fs*60);

%% Narrow values down to this
curr_times = times(rand_start:rand_end);
curr_values = values(rand_start:rand_end,:);

%% Reject bad channels
which_chs = 1:nallowed;
[bad,details] = identify_bad_chs(curr_values,which_chs,allowed_labels,fs);
which_chs(ismember(which_chs,bad)) = []; % reduce channels to do analysis on

%% CAR reference
[car_values,car_labels] = car_montage(curr_values,which_chs,allowed_labels);
is_run_car = ismember((1:length(car_labels))',which_chs);

%% Machine reference
machine_values = curr_values;
machine_labels = cellfun(@(x) sprintf('%s-Ref',x),allowed_labels,'uniformoutput',false);
is_run_machine = ismember((1:length(car_labels))',which_chs);

%% Bipolar reference
[bipolar_values,~,bipolar_labels,chs_in_bipolar] = ...
    bipolar_montage_fc(curr_values,allowed_labels,[],[],name);
bad_bipolar = any(ismember(chs_in_bipolar,bad),2);
empty = cellfun(@(x) strcmp(x,'-'),bipolar_labels);
which_chs_bipolar = 1:size(chs_in_bipolar,1);
which_chs_bipolar(bad_bipolar|empty) = [];
is_run_bipolar = ismember((1:length(allowed_labels))',which_chs_bipolar);

%% Get inter-electrode distance matrix
dm = pseudo_distance_mt(allowed_labels);

%% prep freqs
freqs = get_frequencies;

%% Calculate network
% Loop over montages
for im = 1:3 
   
    if im == 1
        montage = 'machine';
        values = machine_values;
        curr_labels = machine_labels;
        is_run = is_run_machine;
    elseif im == 2
        montage = 'car';
        values = car_values;
        is_run = is_run_car;
        curr_labels = car_labels;
    elseif im == 3
        montage = 'bipolar';
        values = bipolar_values;
        is_run = is_run_bipolar;
        curr_labels = bipolar_labels;
    end

    % notch filter
    values = notch_filter(values,fs);

    % bandpass filter 0.5-80
    broadband = freqs(1,:);
    values = bandpass_any(values,fs,broadband,4);
    
    % make non run channels nans
    run_values = values;
    run_values(:,~is_run) = nan;
    skip = find(~is_run);

    % Turn nans within channel into mean of channel
    for ich = 1:size(run_values,2)
        run_values(isnan(run_values(:,ich)),ich) = nanmean(run_values(:,ich));
    end

    % cross correlation
    [xcor,lags] = cross_correlation(run_values,fs);
    if test_flag
        figure; set(gcf,'position',[10 10 900 400])
        t = tiledlayout(1,2);
        nexttile; turn_nans_gray(xcor); yticks(1:size(xcor,1)); yticklabels(curr_labels); xticks(1:size(xcor,1)); xticklabels(curr_labels);
        nexttile; turn_nans_gray(lags); yticks(1:size(xcor,1)); yticklabels(curr_labels); xticks(1:size(xcor,1)); xticklabels(curr_labels);
        title(t,'Cross correlation (max and lags)')
    end

    % Spectral entropy
    se = spectral_entropy(values,fs);
    if test_flag
        figure
        plot(se,'o')
        xticks(1:length(se))
        xticklabels(curr_labels)
        title('Spectral entropy')
    end

    % Relative entropy
    re = relative_entropy(run_values,fs);
    if test_flag
        figure; set(gcf,'position',[10 10 1400 400])
        t = tiledlayout(1,size(re,3));
        for i = 1:size(re,3)
        nexttile; turn_nans_gray(re(:,:,i)); yticks(1:size(xcor,1)); yticklabels(curr_labels); xticks(1:size(xcor,1)); xticklabels(curr_labels);
        end
        title(t,'Relative entropy')
    end
    
    % PC
    pc =  wrap_or_unwrap_adjacency_fc_toolbox(pc_vector_calc(run_values,fs,tw));
    if test_flag
        figure
        turn_nans_gray(pc(:,:)); yticks(1:size(xcor,1)); yticklabels(curr_labels); xticks(1:size(xcor,1)); xticklabels(curr_labels);
        title('Pearson correlation')
    end
    
    % Spikes
    gdf = detector_new_timing(run_values,fs);
    
    % Get alpha delta ratio
    ad_rat = calc_ad(run_values,fs);
    
    % Get bandpower
    [bp,rel_bp] = bp_calc(run_values,fs,[]);
    if test_flag
        figure; set(gcf,'position',[10 10 900 400])
        t = tiledlayout(1,2);
        nexttile
        turn_nans_gray(bp)
        yticks(1:size(xcor,1)); yticklabels(curr_labels);
        nexttile
        turn_nans_gray(rel_bp)
        yticks(1:size(xcor,1)); yticklabels(curr_labels);
        title(t,'Bandpower (absolute and relative)')
    end
    
    % Get coherence    
    coh = faster_coherence_calc(run_values,fs);
    if test_flag
        figure; set(gcf,'position',[10 10 1400 400])
        t = tiledlayout(1,size(coh,3));
        for i = 1:size(coh,3)
        nexttile; turn_nans_gray(coh(:,:,i)); yticks(1:size(xcor,1)); yticklabels(curr_labels); xticks(1:size(xcor,1)); xticklabels(curr_labels);
        end
        title(t,'Coherence')
    end

    % PLV
    plv = plv_calc(run_values,fs);
    if test_flag
        figure; set(gcf,'position',[10 10 1400 400])
        t = tiledlayout(1,size(plv,3));
        for i = 1:size(plv,3)
        nexttile; turn_nans_gray(plv(:,:,i)); yticks(1:size(xcor,1)); yticklabels(curr_labels); xticks(1:size(xcor,1)); xticklabels(curr_labels);
        end
        title(t,'PLV')
    end

    
    out.montage(im).name = montage;
    out.montage(im).bp = bp;
    out.montage(im).rel_bp = rel_bp;
    out.montage(im).pc = pc;
    out.montage(im).plv = plv;
    out.montage(im).coh = coh;
    out.montage(im).gdf = gdf;
    out.montage(im).ad = ad_rat;
    out.montage(im).skip = skip;
    out.montage(im).is_run = is_run;
    out.montage(im).labels = curr_labels;
    out.montage(im).xcor = xcor;
    out.montage(im).lags = lags;
    out.montage(im).re = re;
    out.montage(im).se = se;
    out.clean_labels = allowed_labels;
    out.fs = fs;
    out.times = [curr_times(1) curr_times(end)];
    out.idx = [rand_start rand_end];
    out.file_path = file_path;
    out.name = name;
    out.freqs = freqs;
    out.dm = dm;

    if show_data
        tout.montage(im).values = values;
        tout.montage(im).name = montage;
    end

end


 if show_data
    ex_chs = [];
    only_run = 0;
    show_montage = 3;
    simple_plot(tout,out,ex_chs,show_montage,out.montage(show_montage).gdf,...
        only_run,skip)
    %pause
    %close(gcf)
    clear tout

    figure; tiledlayout(1,3);
    for i = 1:3
        nexttile
        turn_nans_gray(out.montage(i).pc)
        title(out.montage(i).name)
        xticks(1:length(out.montage(i).labels))
        xticklabels(out.montage(i).labels)
        yticks(1:length(out.montage(i).labels))
        yticklabels(out.montage(i).labels)
    end

    figure
    tiledlayout(1,3)
    for i = 1:3
        nexttile
        turn_nans_gray(out.montage(i).plv(:,:,4))
        title(out.montage(i).name)
        xticks(1:length(out.montage(i).labels))
        xticklabels(out.montage(i).labels)
        yticks(1:length(out.montage(i).labels))
        yticklabels(out.montage(i).labels)
    end
 end


end