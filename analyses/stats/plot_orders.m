function plot_orders(things,sozs,rates,which,min_rate)

myColours = [0, 0.4470, 0.7410;...
    0.8500, 0.3250, 0.0980;...
    0.4660, 0.6740, 0.1880;...
    0.4940, 0.1840, 0.5560;...
    0.6350, 0.0780, 0.1840];
grayColor = 0.75*[1 1 1];
markersize = 2;
npts = length(things);
nchance = nan(npts,1);
all = nan(npts,1);
successes = nan(npts,1);

for i = 1:npts
    curr_things = things{i};
    curr_soz = sozs{i};
    curr_rates = rates{i};
    
    % remove nans
    nan_things = isnan(curr_things) | isnan(curr_rates);
    curr_things(nan_things) = [];
    curr_soz(nan_things) = [];
    curr_soz = logical(curr_soz);
    
    curr_rates(nan_things) = [];
    
    % get rank of soz
    if strcmp(which,'rate')

        % sort the rates in descending order
        [curr_things,I] = sort(curr_things,'descend');
    elseif strcmp(which,'rl')

        % also remove those with few spikes. I do this because I think
        % the RL for electrodes with few spikes is unreliable
        spikey = curr_rates > min_rate;
        curr_things = curr_things(spikey);
        curr_soz = curr_soz(spikey);

        % sort the RL in ascending order
        [curr_things,I] = sort(curr_things,'ascend');
    end
    ranks = 1:length(curr_things);
    ranks(I) = ranks;
    soz_ranks = ranks(curr_soz);
    not_soz_ranks = ranks(~curr_soz);
    nchance(i) = length(ranks)/2;
    all(i) = nanmedian(soz_ranks);
    
    successes(i) = ranking_binomial_test(ranks,curr_soz);
    
    %{
    plot(i+0*randn(length(not_soz_ranks),1),not_soz_ranks,'o',...
        'color',grayColor,'markersize',markersize);
    hold on
    plot(i+0*randn(length(soz_ranks),1),soz_ranks,'o',...
        'color',myColours(1,:),'linewidth',2,'markersize',markersize);
    %}
    plot(i,ranks,'o','color',grayColor,'markersize',markersize);
    hold on
    plot(i,nanmedian(soz_ranks),'*','color',myColours(1,:),'linewidth',2,'markersize',markersize+2);
    
end

chance = median(nchance);
all = nanmedian(all);
pval_binom = 2*binocdf(sum(successes==0),length(successes),0.5);
ap = plot(xlim,[all all],'-','linewidth',2,'color',myColours(1,:));
cp = plot(xlim,[chance chance],'--','linewidth',2,'color',myColours(2,:));
xl = xlim;
xbar = xl(1) + 1.01*(xl(2)-xl(1));
xtext = xl(1) + 1.035*(xl(2)-xl(1));
newxl = [xl(1) xl(1) + 1.07*(xl(2)-xl(1))];
plot([xbar xbar],[all chance],'k-','linewidth',2)
if pval_binom >= 0.05
text(xtext-1,(all+chance)/2,get_asterisks(pval_binom,1),'rotation',90,...
        'horizontalalignment','center','fontsize',16)

else
    text(xtext,(all+chance)/2,get_asterisks(pval_binom,1),'rotation',90,...
        'horizontalalignment','center','fontsize',20)
end
xlim(newxl)
legend([ap,cp],{'Median SOZ rank','Median chance rank'},'fontsize',15,'location','northeast')

end