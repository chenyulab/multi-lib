function make_trials_vars_at_test(subexpIDs)
%% Make test trial variables

test_varname = 'cevent_test-trial_word'; % cevent variable which define test trial length

subjs = cIDs(subexpIDs);


for s = 1:numel(subjs)
    
    sid = subjs(s);
    
    data = get_variable(sid,test_varname);

    times = [data(1,1),data(end,2),1]; % first onset, last offset

    
    record_additional_variable(sid, 'cevent_trials_at_test', times);
    
    rate = get_rate(sid);
    cstr_times = cevent2cstream(times, times(1), 1/rate, 0, times(end, 2));
    record_additional_variable(sid, 'cstream_trials_at_test', cstr_times);
    
end
