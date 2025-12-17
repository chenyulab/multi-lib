% reads the raw ROI coding file to find chunks separated by 20 seconds of 
% no events
% takes raw ROI -> ignores category and merge ROI instances that are less
% than 1 second apart -> take output and merge again but, now merge if
% less than 20 seconds apart

function trials = cal_trials_by_child_roi_vyu(subID, trialInfo)
    trials = NaN;
    
    sub_dir = get_subject_dir(subID);
    support_dir = fullfile(sub_dir, 'supporting_files');

    dataVyu_code_file = fullfile(support_dir, 'Datavyu summary coding file.csv');
    mat_code_file = fullfile(support_dir, 'coding_eye_roi_child.mat');

    if isfile(mat_code_file)
        vyu_cstream = load(mat_code_file).sdata.data;
        vyu_cstream(:,1) = frame_num2time(vyu_cstream(:,1), trialInfo);
        vyu_roi = cstream2cevent(vyu_cstream);
        vyu_roi = vyu_roi(vyu_roi(:,3) > 0,:);
        vyu_roi(:,3) = 1;

    elseif isfile(dataVyu_code_file)
        vyu_df = readtable(dataVyu_code_file, Delimiter =',');

        vyu_names = vyu_df.Properties.VariableNames;
        child_roi_names = {'child_roi_onset','child_roi_offset'};
    
        [maskSum, idx] = ismember(child_roi_names, lower(vyu_names));
        if sum(maskSum) ~= 2
            fprintf('no child roi columns in datavyu summary coding file for subject %d\n', subID)
            return 
        else
            vyu_roi = vyu_df(:,idx);

            % turn into 'cevent'
            vyu_roi = vyu_roi(~isnan(vyu_roi{:,1}),:);
            vyu_roi = [vyu_roi{:,:} ones(height(vyu_roi),1)];
            % convert to system time
            [startRange, ~] = get_extract_range(subID);
            vyu_roi(:,[1,2]) = (vyu_roi(:,[1,2]) / 1000) - (startRange/30) + 30;
        end
    else
        fprintf('subject %d has no raw roi coding file\n',subID)
        return 
    end
    
    % get roi values within predefined valid session times (base trials)
    baseTrials = frame_num2time(trialInfo.trials, trialInfo);
    
    % from the base trials get the trials with most roi 
    valid_vyu_roi_chunks = event_extract_ranges(vyu_roi, baseTrials);
    chunks_out = cellfun(@(x) cevent_merge_segments(x,3,1), valid_vyu_roi_chunks, 'UniformOutput', false);
    chunks_trials = cellfun(@(x) cevent_merge_segments(x,20,1), chunks_out, 'UniformOutput', false);
    trials = vertcat(chunks_trials{:});
    
    if trials(1,1) < 30
        trials(1,1) = 30.0;
    end

    trials(:,3) = (1:height(trials))';
end