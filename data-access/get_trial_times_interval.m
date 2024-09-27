function interval = get_trial_times_interval(subject_id)
% Author: Jingwen Pang
% last modified: 9/27/2024
% Get the time interval between each trial
% if only one trial, then return []
    times = get_trial_times(subject_id);

    if size(times,1) > 1
        for i = 1:size(times,1)-1
            interval(i,1) = times(i,2);
            interval(i,2) = times(i+1,1);
        end
    else
        interval = [];
    end

end