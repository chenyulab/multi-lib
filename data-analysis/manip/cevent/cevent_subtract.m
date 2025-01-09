function [cevent] = cevent_subtract(cevent1, cevent2)
% cevent_subtract  takes two cevents and subtract the shared segments between
% two from cevent1 to generate a new version of cevent1  
%
% Warning: this is accomplished using a transformation to a cstream, so a cevent
% that has overlapping events will lose this overlapping data!  Also, the start
% and end times of the events may change by a small amount.
%
% cevent_subtract(cevent1, cevent2)
% Input: two cevents
% Output: a new event of cevent1 without shared moments of these two events
%


% first find the shared cevent3 
cevent3 = cevent_shared(cevent1, cevent2); 

% convert cevent1 and cevent 3 into two streams 
timeInterval = 1/30; 
startTime = 0; % default;
defaultValue = 0; 
cstream1 = cevent2cstream(cevent1, startTime, timeInterval, defaultValue);
cstream3 = cevent2cstream(cevent3, startTime, timeInterval, defaultValue);
[cstream1 cstream3] = cstream_equal_length(cstream1, cstream3);

% assigne all non-zero shared items to be zero
index1 = find(cstream1(:,2) == cstream3(:,2));
size(index1)
index2 = find(cstream1(:,2) == 0); 
index = setdiff(index1, index2);
size(index2)
cstream1(index,2)  = 0; 

% convert it back to cevent
cevent = cstream2cevent(cstream1, 0); 

