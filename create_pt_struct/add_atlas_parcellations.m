function add_atlas_parcellations

%% Get file locs
locations = fc_toolbox_locs;
results_folder = [locations.main_folder,'results/'];
bids_folder = '/data/Human_Data/CNT_iEEG_BIDS/';
data_folder = [locations.main_folder,'data/'];

% add script folder to path
scripts_folder = locations.script_folder;
addpath(genpath(scripts_folder));

%% Get pt file
pt = load([data_folder,'pt.mat']);
pt = pt.pt;

%% Loop over patients and get locs
for p = 1:length(pt)
    name = pt(p).name;
    rid = pt(p).rid;

    if isempty(pt(p).elecs_native)
        fprintf('\nSkipping %s because no elecs\n',name);
        continue; 
    end
    
    elec_names = pt(p).elecs_native.elec_names;

    % Load the relevant atlas parcellation files
    if rid < 100
        rid_text = ['sub-RID',sprintf('00%d',rid)];
    else
        rid_text = ['sub-RID',sprintf('0%d',rid)];
    end
    
    pt_folder = [bids_folder,rid_text,'/'];
    

    module3_folder = [pt_folder,'derivatives/ieeg_recon/module3/'];

    a_listing = dir([module3_folder,'*atropos*.csv']);
    d_listing = dir([module3_folder,'*DKT*.csv']);

    if isempty(a_listing)
        fprintf('\nSkipping %s because cannot find atlas\n',name);
        continue; 
    end

    atropos_file = [module3_folder,a_listing(1).name];
    dkt_file = [module3_folder,d_listing(1).name];

    aT = readtable(atropos_file);
    dT = readtable(dkt_file);

    % get elec names
    a_name = aT.name;
    d_name = dT.name;

    % get xyz
    a_xyz = [aT.x aT.y aT.z];
    d_xyz = [dT.x dT.y dT.z];

    % get indices
    a_idx = aT.index;
    d_idx = dT.index;

    % get labels
    a_label = aT.label;
    d_label = dT.label;

    % Reconcile electrode names and re-order as needed
    assert(isequal(a_name,d_name))
    assert(isequal(a_xyz,d_xyz))

    [Lia,Locb] = ismember(a_name,elec_names);
    assert(isequal(a_name(Locb(Lia)),elec_names))

    a_label = a_label(Locb(Lia));
    d_label = d_label(Locb(Lia));
    a_xyz = a_xyz(Locb(Lia));
    d_xyz = d_xyz(Locb(Lia));
    a_idx = a_idx(Locb(Lia));
    d_idx = d_idx(Locb(Lia));
    
    % fill up
    pt(p).elecs_native.atropos.names = elec_names;
    pt(p).elecs_native.atropos.xyz = a_xyz;
    pt(p).elecs_native.atropos.idx = a_idx;
    pt(p).elecs_native.atropos.label = a_label;

    pt(p).elecs_native.dkt.names = elec_names;
    pt(p).elecs_native.dkt.xyz = d_xyz;
    pt(p).elecs_native.dkt.idx = d_idx;
    pt(p).elecs_native.dkt.label = d_label;
    
    save([data_folder,'pt.mat'],'pt');

end

end