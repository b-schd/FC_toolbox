function all_plv = plv_calc(values,fs)

%% Get filtered signal
out = filter_canonical_freqs(values,fs);
nfreqs = size(out,3);
nchs = size(values,2);


%% initialize output vector
all_plv = nan(nchs,nchs,nfreqs);


%% Remove nan rows, keeping track of which I am removing
%{
nan_rows = any(isnan(values),1); % find channels with nans for any time points
values_no_nans = values(:,~nan_rows);
nchs_no_nans = size(values_no_nans,2);
temp_plv = nan(nchs_no_nans,nchs_no_nans,nfreqs);
A = values_no_nans;
nchs = size(A,2);
%}

% Do plv for each freq
for f = 1:nfreqs
    
    filteredData = out(:,:,f);

    % Get phase of each signal
    phase = nan(size(filteredData));
    for ich = 1:nchs
        phase(:,ich)= angle(hilbert(filteredData(:,ich)));
    end

    % Get PLV
    plv = nan(nchs,nchs);
    for ich = 1:nchs
        for jch = ich+1:nchs
            e = exp(1i*(phase(:,ich) - phase(:,jch)));
            plv(ich,jch) = abs(sum(e,1))/size(phase,1);
            plv(jch,ich) = abs(sum(e,1))/size(phase,1);
        end
    end
    %temp_plv(:,:,f) = plv;
    all_plv(:,:,f) = plv;

    if 0
        figure
        nexttile
        plot(filteredData(:,2))
        hold on
        plot(filteredData(:,3))
        nexttile
        plot((hilbert(filteredData(:,2))))
        hold on
        plot(hilbert(filteredData(:,3)))

        nexttile
        plot(phase(:,2))
        hold on
        plot(phase(:,3))
    end
end

%% Put the non-nans back
%{
all_plv(~nan_rows,~nan_rows,:) = temp_plv;
all_plv(logical(repmat(eye(nchs,nchs),1,1,nfreqs))) = nan;
%}

if 0
    figure; tiledlayout(1,6)
    for i = 1:6
        nexttile
        turn_nans_gray(all_plv(:,:,i))
        colorbar
    end
end

end