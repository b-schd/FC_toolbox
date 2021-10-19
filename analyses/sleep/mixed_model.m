function mixed_model

%% Parameters
main_locs = {'mesial temporal','temporal neocortical','other cortex','white matter'};
main_lats = {'Left','Right'};

%% Get file locs
locations = fc_toolbox_locs;
results_folder = [locations.main_folder,'results/'];
out_folder = [results_folder,'analysis/sleep/'];
int_folder = [results_folder,'analysis/intermediate/'];
if ~exist(out_folder,'dir')
    mkdir(out_folder)
end

% add script folder to path
scripts_folder = locations.script_folder;
addpath(genpath(scripts_folder));

%% Listing of available files
listing = dir([int_folder,'*.mat']);
npts = length(listing);

%% Alpha delta ratio validation
fprintf('\nDoing alpha delta ratio validation\n');

swdes = sw_ad_erin_designations;
npts_val = length(swdes);
ad_norm = nan(npts_val,2); %1 = sleep, 2 = wake
all_wake = [];
all_sleep = [];
all_rate_rl_corr = [];
for j = 1:npts_val
    if isempty(swdes(j).sw), continue; end
    sleep_ad = swdes(j).sw.sleep;
    wake_ad = swdes(j).sw.wake;
    ad_val = swdes(j).ad;

    sleep_norm = (sleep_ad-nanmedian(ad_val))./iqr(ad_val);
    wake_norm = (wake_ad-nanmedian(ad_val))./iqr(ad_val);
    ad_norm(j,:) = [nanmean(sleep_norm),nanmean(wake_norm)];
    all_wake = [all_wake;wake_norm];
    all_sleep = [all_sleep;sleep_norm];
end

% Calculate roc
[roc,auc,disc] = calculate_roc(all_sleep,all_wake,1e3);


fprintf('\nGot alpha delta ratio validation\n');


big_array = [];
missing_loc = [];
all_rates = [];
sleep_des = [];
loc_des = [];
lat_des = [];
soz_des = [];
p_des = [];
for p = 1:npts
    fprintf('\nDoing patient %d of %d\n',p,npts);
    
     %% Load
    summ = load([int_folder,listing(p).name]);
    summ = summ.summ;
    
    %% Get main things
    loc = summ.ana_loc;
    spikes = summ.spikes;
    ad = summ.ad;
    labels = summ.labels;
    lat = summ.ana_lat;
    ntimes = size(spikes,2);
    anatomy = summ.anatomy;
    
     % Fix lat thing
    for i = 1:length(lat)
        if isempty(lat{i}), lat{i} = 'unspecified'; end
    end
    
    %% Get features for soz vs not
    soz = summ.soz.chs;
    chnums = 1:length(labels);
    is_soz = ismember(chnums,soz);
    
    %% Find and remove non-intracranial
    %{
    MUST REMEMBER TO ADD THIS FOR COA
    %}
    ekg = find_non_intracranial(labels);
    
    ad = ad(~ekg,:);
    ad = nanmean(ad,1);
    anatomy = anatomy(~ekg);
    lat = lat(~ekg);
    loc = loc(~ekg,:);
    spikes = spikes(~ekg,:);
    labels = labels(~ekg);
    
    is_soz = is_soz(~ekg);
    
    %% Determine "wake" and "sleep" times
    % normalized ad
    ad_norm = (ad - nanmedian(ad))./iqr(ad);
    wake = ad_norm > disc;
    sleep = ad_norm <= disc;
    
    %% Skip if missing anatomy
    if sum(cellfun(@(x) isempty(x),loc)) == length(loc) 
        missing_loc = [missing_loc;p];
        continue
    end
    
    
    %% 
    soz_anatomy = (anatomy(is_soz));
    [soz_loc,soz_lat] = cluster_anatomical_location(soz_anatomy);
    
    %% For eight main anatomical groups (4 localization x 2 laterlizations)
    % Get spike rate, loc designation, lat designation, soz designation
    
    for i = 1:length(main_locs)
        for j = 1:length(main_lats)
            ic = ismember(loc,main_locs{i}) & ismember(lat,main_lats{j});
            for k = 1:2 % wake, sleep
                if k == 1
                    all_rates = [all_rates;nanmean(spikes(ic,wake),'all')];
                    sleep_des = [sleep_des;0];
                elseif k == 2
                    all_rates = [all_rates;nanmean(spikes(ic,sleep),'all')];
                    sleep_des = [sleep_des;1];
                end
                
                loc_des = [loc_des;i];
                lat_des = [lat_des;j];
                p_des = [p_des;p];
                
                if ismember(main_locs{i},soz_loc) && ismember(main_lats{j},soz_lat)
                    soz_des = [soz_des;1];
                else
                    soz_des = [soz_des;0];
                end
            end
        end
    end
    

    
end

T = table(all_rates,p_des,loc_des,lat_des,soz_des,sleep_des);
T.p_des = nominal(T.p_des);
T.loc_des = nominal(T.loc_des);
T.lat_des = nominal(T.lat_des);
T.soz_des = nominal(T.soz_des);
T.sleep_des = nominal(T.sleep_des);

lme = fitlme(T,'all_rates~loc_des+lat_des+soz_des+sleep_des+(1|p_des)');
lme

end