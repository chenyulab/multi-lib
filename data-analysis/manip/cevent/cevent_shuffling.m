function cevents_shuffled = cevent_shuffling(cevents, ranges, is_trial)
% This function shuffles the cevents within certain ranges while reserving
% their duration

ROI_EMPTY = 0;

if isempty(cevents)
    cevents_shuffled = zeros(0, 3);
    return;
end

if nargin < 3
    is_trial = false;
end

%%%%%%%%%%%
% check if there is overlaps within the cevents
cevents = cevent_sort_by_time(unique(cevents, 'rows'), 1);
cevent_gaps = cevents(2:end, 1) - cevents(1:end-1, 2);
if sum(cevent_gaps < -0.0001) >0
    [cevents [nan; cevent_gaps]]
    error('There are overlapping cevents in the data. This function won''t perform correctly.');
end

% only get cevents within ranges
cevents = extract_ranges(cevents, 'cevent', ranges);
num_ranges = size(ranges, 1);
cevents_shuffled = cell(1, num_ranges);

for ridx = 1:size(ranges, 1)
    cevents_one = cevents{ridx};
    range_one = ranges(ridx, :);
    
    if isempty(cevents_one)
        continue
    end
    
    % get the gap events
    events_empty = event_NOT(cevents_one(:,1:2), range_one);
    num_events = size(events_empty, 1);
    cevents_empty = [events_empty repmat(ROI_EMPTY, num_events, 1)];
    
    % turn the time series into cevents with ROI and cevents with empty ROI
    % 0 with correct time ordering
    cevents_all = cevent_sort_by_time([cevents_one; cevents_empty], 1);
    num_cevents = size(cevents_all, 1);
    
    % randomize the ordering
    shuffle_indices = randperm(num_cevents);
    
    % constructing the randomized cevents based on the new ordering
    start_time = range_one(1, 1);
    cevents_new = [];
    for cidx = 1:num_cevents
        index_one = shuffle_indices(cidx);
        cevent_one = cevents_all(index_one, :);
        end_time = start_time + cevent_one(1,2) - cevent_one(1, 1);
        cevents_new = [cevents_new; [start_time end_time cevent_one(1,3)]];
        
        start_time = end_time;
    end
    cevents_new = cevents_new(cevents_new(:, 3) > ROI_EMPTY, :);
    cevents_shuffled{1, ridx} = cevents_new;
end

if ~is_trial
    cevents_shuffled = vertcat(cevents_shuffled{:});
end


