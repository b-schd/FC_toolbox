function [h,out] = boxplot_with_points(x,categories,show_stats,groupOrder,specialMarker)

%{
cols = [0 0.4470 0.7410;...
    0.8500 0.3250 0.0980;...
    0.9290 0.6940 0.1250];
%}
cols = colormap(gca,lines(length(unique(categories))));

h = boxplot(x,categories,'colors',cols,'symbol','','GroupOrder',groupOrder);
set(h,{'linew'},{2})
hold on
unique_lats = xticklabels;
nlats = length(unique_lats);
for il = 1:nlats
    curr_lats = strcmp(categories,unique_lats{il}); 
    if ~exist('specialMarker','var') || isempty(specialMarker)
        plot(il + randn(sum(curr_lats),1)*0.05,x(curr_lats),'o','color',cols(il,:),'linewidth',2)
    else

        plot(il -0.1,x(curr_lats&~specialMarker),'o','color',cols(il,:),'linewidth',2)
        if sum(curr_lats&specialMarker) ~=0
            plot(il +0.1,x(curr_lats&specialMarker),'*','color',cols(il,:),'linewidth',2)
        end
    end
end
plot(xlim,[0 0],'k--')

% Make unique lats pretty
unique_lats_upper = cellfun(@(x) [upper(x(1)) x(2:end)],unique_lats,'UniformOutput',false);
xticklabels(unique_lats_upper )

if show_stats
    yl = ylim;
    new_y = [yl(1) yl(1) + 1.3*(yl(2)-yl(1))];
    ylim(new_y)

    [p,tbl,stats] = kruskalwallis(x,categories,'off');
    out.p = p;
    out.tbl = tbl;
    out.stats = stats;
    out.eta2 = tbl{2,2}/(tbl{2,2}+tbl{3,2});
    bon_p = 0.05/3;
    if p < 0.05
            % do post hoc
            lrp = ranksum(x(strcmp(categories,'left')),x(strcmp(categories,'right')));
            rbp = ranksum(x(strcmp(categories,'right')),x(strcmp(categories,'bilateral')));
            lbp = ranksum(x(strcmp(categories,'left')),x(strcmp(categories,'bilateral')));
            out.lrp = lrp;
            out.rbp = rbp;
            out.lbp = lbp;
            ybar1 = yl(1) + 1.06*(yl(2)-yl(1));
            ytext1 = yl(1) + 1.09*(yl(2)-yl(1));
            ybar2 = yl(1) + 1.18*(yl(2)-yl(1));
            ytext2 = yl(1) + 1.21*(yl(2)-yl(1));
            downtick = 0.03*(yl(2)-yl(1));

            if lrp < bon_p
                plot([1 2],[ybar1 ybar1],'k-','linewidth',2)
                plot([1 1],[ybar1-downtick ybar1],'k-','linewidth',2)
                plot([2 2],[ybar1-downtick ybar1],'k-','linewidth',2)
                text(1.5,ytext1,get_asterisks_bonferroni(lrp,3),'horizontalalignment','center','fontsize',20)
            end
            if rbp < bon_p
                plot([2 3],[ybar1 ybar1],'k-','linewidth',2)
                plot([2 2],[ybar1-downtick ybar1],'k-','linewidth',2)
                plot([3 3],[ybar1-downtick ybar1],'k-','linewidth',2)
                text(2.5,ytext1,get_asterisks_bonferroni(rbp,3),'horizontalalignment','center','fontsize',20)
            end
            if lbp < bon_p
                plot([1 3],[ybar2 ybar2],'k-','linewidth',2)
                plot([1 1],[ybar2-downtick ybar2],'k-','linewidth',2)
                plot([3 3],[ybar2-downtick ybar2],'k-','linewidth',2)
                text(2,ytext2,get_asterisks_bonferroni(lbp,3),'horizontalalignment','center','fontsize',20)
            end
    else
        ybar1 = yl(1) + 1.06*(yl(2)-yl(1));
        ytext1 = yl(1) + 1.09*(yl(2)-yl(1));
        plot([1 3],[ybar1 ybar1],'k-','linewidth',1)
        text(2,ytext1,'ns','horizontalalignment','center','fontsize',15)
        out.lrp = nan;
        out.rbp = nan;
        out.lbp = nan;

    end

end


end