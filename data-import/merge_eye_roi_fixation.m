%%%
% Author: Jane Yang
% Last modifier: 02/29/2024
%
% This function merges the eye_roi_fixation variables to
% eye_rois by merging instances where the subject is looking at the same 
% thing less than 4 seconds apart.
%
% Input: subIDs - a list of subjects
%
% Output: cevent/cstream_eye_roi variables
%%%

function merge_eye_roi_fixation(subIDs)
    agent = {'child','parent'};
    threshold = 4;
    rate = 30;
    
    % iterate through subjects
    for s = 1:length(subIDs)
        cat_list = [1:get_num_obj(subIDs(s))+1];
        % iterate through agents
        for a = 1:length(agent)
            cevent = get_variable(subIDs(s),sprintf('cevent_eye_roi_fixation_%s',agent{a})); % load this in just in case
    
            % merge the fixations in the data
            cevent_merged = cevent_merge_segments(cevent, threshold/rate, cat_list);
            cstream_merged = cevent2cstream(cevent_merged,floor(cevent_merged(1,1)),1/rate,0); % convert to cstream
    
            % generate cevent/cstream_eye_roi_child/parent variable
            cevent_merged_varname = ['cevent_eye_roi_' agent{a}];
            cstream_merged_varname = ['cstream_eye_roi_' agent{a}];
            record_variable(subIDs(s),cevent_merged_varname,cevent_merged);
            record_variable(subIDs(s),cstream_merged_varname,cstream_merged);
        end
    end
end