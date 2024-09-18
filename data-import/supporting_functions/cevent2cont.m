function cont = cevent2cont(event, start_time,interval,default, end_time)
% Convert event to cont given a range of time
% cont = event2cont(event, times)
% Output is a binary in the cont form.  The input event is assumed to be
% sorted and not overlapped.
% The input TIMES should be a MATLAB range expression, for instance
% 1:0.1:35.  Or it could be any sorted list of timestamps.

if ~exist('end_time', 'var')
    end_time = event(end,2);
end

if ~exist('default', 'var')
    default = 0;
end


times = start_time:interval:end_time;

if ~exist('default', 'var')
    default = 0;
end

if size(event, 2) == 2
    event(:, 3) = 1;
end


% change to account for empty events
if size(event,1) == 0
    event_count = 0;
    start = 0;
    stop=0;
else
    event_count = 1;
    start = event(1,1);
    stop = event(1,2);
end

total = length(times);
cont = zeros(total,2);
cont(:,1) = times;
cont(:,2) = default;
total_event = size(event, 1);

% For each time
for i = 1:total
    time = times(i);
    
    % if this time is past the stop of the event, search for a new event.
    while(time >= stop && event_count < total_event)
        event_count = event_count + 1;
        start = event(event_count ,1);
        stop = event(event_count ,2);
    end

    % Check if before event
    if(time < start)
        cont(i,2) = NaN;
    elseif (time < stop) % not before.  During?
        cont(i,2) = event(event_count, 3);
    else % Not before or during.  After.
        % This should only happen when we've run out of events.
        assert(event_count == total_event);
        % The rest of the variable should be zeros, which it already is.
        % We're done!
        break
    end
end
end
