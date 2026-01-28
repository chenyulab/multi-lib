% find the difference between the hand trials and the trials calculated
% from roi coding 
function get_base_roi_trial_diff(subID)
    % load curr trials and info file     
    handTrials = get_variable(subID, 'cevent_trials');
    trialInfo = get_info_file_path(subID);
    trialInfo = load(trialInfo).trialInfo;
    
    % cal trials by roi coding
    compTrials = cal_trials_by_child_roi_vyu(subID, trialInfo);
    if isnan(compTrials)
        return 
    end
    compTrialsF = [time2frame_num(compTrials(:,1:2),trialInfo) compTrials(:,3)];
    
    emptyChunks = event_XOR(handTrials(:,1:2), compTrials(:,1:2)); % get chunks in 1 not in 2
    
    % display new trials
    varNames = ["onset(t)","offset(t)","onset(f)","offset(f)",'trial_num'];
    summaryTable = table(compTrials(:,1), compTrials(:,2), compTrialsF(:,1), compTrialsF(:,2), compTrials(:,3),'VariableNames',varNames);
    fprintf('New trials:\n')
    disp(summaryTable)
    % display chunks in 1 not in 2
    fprintf('\nTime removed from original trials:\n')
    emptyChunkstb = table(emptyChunks(:,1),emptyChunks(:,2),'VariableNames',["onset(t)", "offset(t)"]);
    disp(emptyChunkstb)
    % make vis
    start_time = min([handTrials(1,1), compTrials(1,1)]);
    end_time = max([handTrials(end,2), compTrials(end,2)]);
    time_window = get_time_window_for_vis(start_time-5, end_time + 5);
    h = vis_streams_data({handTrials, compTrials}, time_window, {'old','new'});

end