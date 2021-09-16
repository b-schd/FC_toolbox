function all_pt_psd(summ)

%% Parameters
m = 2; % do not change
main_locs = {'mesial temporal','temporal neocortical','other cortex','white matter'};
main_lats = {'Left','Right'};
main{1} = main_locs;
main{2} = main_lats;

%% Get file locs
locations = fc_toolbox_locs;
results_folder = [locations.main_folder,'results/'];
out_folder = [results_folder,'analysis/sleep/'];
if ~exist(out_folder,'dir')
    mkdir(out_folder)
end

% add script folder to path
scripts_folder = locations.script_folder;
addpath(genpath(scripts_folder));


%% Get the longest run (will pad the others with zeros)
longest_run = 0;
npts = length(summ);
for p = 1:npts
    run_length = length(summ(p).times);
    if run_length > longest_run
        longest_run = run_length;
    end
end

% Initialize psd
all_psd = nan(npts,ceil(longest_run/2));
all_freqs = nan(npts,ceil(longest_run/2));

%% Loop over patients and get psd per pt
for p = 1:npts
    spikes = summ(p).spikes;
    times = summ(p).times;
    run_length = length(times);
    fs = 1/median(diff(times));
    assert(fs == 0.0017);
    
    % pad spikes
    spikes = [spikes,zeros(size(spikes,1),longest_run-run_length)];
    
    % average across electrodes
    spikes = nanmean(spikes,1);
    
    % get psd
    [P,freqs] = power_by_freq(spikes,fs);
    
    all_psd(p,:) = P;
    all_freqs(p,:) = freqs;
end

% confirm freqs same across patients
sum_diff_freqs = sum(abs(sum(abs(diff(all_freqs,1,1)))));

end