function mat = confusion_matrix(predicted,actual,do_plot)


classes = unique([predicted;actual]);
nclasses = length(classes);

mat = zeros(nclasses,nclasses);


%% Build confusion matrix

for i = 1:length(predicted)
    pred = predicted(i);
    ac = actual(i);
    
    mat(ac+1,pred+1) = mat(ac+1,pred+1) + 1;
    
end

if nclasses > 2, error('need to think about how to incorporate multiple classes'); end

%% Calculate true positives, etc.
tp = mat(2,2); % pred true and actual true
tn = mat(1,1); % predicted false and actual false
fn = mat(2,1); % predicted false and actual true
fp = mat(1,2); % predicted true and actual false

%% Calculate accuracy, sensitivity, specificity, PPV, NPV
accuracy = (tp+tn)/(tp+tn+fp+fn);
sensitivity = tp/(tp+fn);
specificity = tn/(tn+fp);
ppv = tp/(fp+tp);
npv = tn/(tn+fn);


if do_plot
    figure
    turn_nans_gray(mat)
    xticks(1:nclasses)
    xticklabels(num2str(classes))
    yticks(1:nclasses)
    yticklabels(num2str(classes))
    xlabel('Predicted')
    ylabel('True')
    hold on
    for i = 1:nclasses
        for j = 1:nclasses
            text(i,j,sprintf('%d',mat(j,i)),'horizontalalignment','center','fontsize',15)
        end
    end
    title(sprintf('Accuracy: %1.2f, PPV: %1.2f, NPV: %1.2f',accuracy,ppv,npv))
end

end