function make_trials_vars(IDs)
%% Make trial variables
% creates event_trials, cevent_trials, and cstream_trials variables
% pulls from info file timing

if numel(num2str(IDs(1))) > 2
    subs = IDs;
else
    subs = list_subjects(IDs);
end

subjs = subs;


for s = 1:numel(subjs)
    
    sid = subjs(s);

    trials = get_trials(sid);
    log = trials(:,1) ~= -1;
    times = frame_num2time(trials, sid);
    
    %check if trial_type.txt exists
    trial_type_file_name = fullfile(get_subject_dir(sid), 'trial_coding_p', 'trial_type.txt');
    if exist(trial_type_file_name, 'file')
        trial_type_data = dlmread(trial_type_file_name);
        times(:,3) = trial_type_data;
        check = prod(times,2);
        if ~isequal(check > 0, log)
            error('%d, -1 from get_trials and trial_type.txt do not line up', sid);
        end
    else
        times(:,3) = (1:size(times,1))';
    end

    times = times(log,:);
    
    record_variable(sid, 'cevent_trials', times);
    
    rate = get_rate(sid);
    cstr_times = cevent2cstream(times, times(1), 1/rate, 0, times(end, 2));
    record_variable(sid, 'cstream_trials', cstr_times);
    
end
