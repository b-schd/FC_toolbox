function test_ranking(rates,soz,nb)

npts = length(soz);

%% Get true median ranking
all_rankings = nan(npts,1);
for ip = 1:npts
    
    % assign nan rates to be zero
    curr_rates = rates{ip};
    curr_rates(isnan(cur_rates)) = 0;
    
    % sort the rates in descending order
    [curr_rates,I] = sort(curr_rates,'descend');
    ranks = 1:length(curr_rates);
    ranks(I) = ranks;
    
    % get the ranks of the soz elecs
    curr_soz = soz{ip};
    soz_ranks = median(ranks(curr_soz));
    all_rankings(ip) = soz_ranks;
end

median_ranking_true = median(all_rankings);

%% Get MC median rankings
median_ranking_mc = nan(nb,1);
for ib = 1:nb
    temp_all_rankings = nan(npts,1);
    
    for ip = 1:npts
    
        % assign nan rates to be zero
        curr_rates = rates{ip};
        curr_rates(isnan(cur_rates)) = 0;

        % sort the rates in descending order
        [curr_rates,I] = sort(curr_rates,'descend');
        ranks = 1:length(curr_rates);
        ranks(I) = ranks;

        % get the number of soz electrodes
        curr_soz = soz{ip};
        nsoz = length(curr_soz);
        nelecs = length(curr_rates);
        
        % choose a random sample (without replacement) of electrodes equal
        % in number to nsoz
        fake_soz = randsample(nelecs,nsoz);
        
        soz_ranks = median(ranks(fake_soz));
        temp_all_rankings(ip) = soz_ranks;
    end
    
    median_ranking_mc(ib) = median(temp_all_rankings);
    
end


end