%%%
% Author: Jane Yang
% Last modified: 05/24/2024
% 
% Description: This script takes gesture variable and eye_roi variable to
% generate gesture-eye variable.
%
% Input: subexpIDs - a list of subjects or experiments
% Output: cstream/cevent_gesture-eye_child/parent-child/parent
%%%

function make_joint_eye_gesture(subexpIDs)
    agent = {'child','parent'};
    % get a list of subjects
    subIDs = cIDs(subexpIDs);


    % iterate through the list of subjects
    for i = 1:length(subIDs)
        sub = subIDs(i);

        timebase = get_variable(sub, 'cstream_trials');

        for a = 1:length(agent)
            % load relevant vars
            gesture_varname = sprintf('cevent_gesture_%s',agent{a});
            eye_varname = 'cevent_eye_roi_child'; % hard-coded to always load child's eye only for now
            gesture = get_variable(sub,gesture_varname);
            eye = get_variable(sub,eye_varname); 

            % convert cevent vars to cstream based on trial timebase
            cst_eye = cevent2cstreamtb(eye,timebase);
            cst_gesture = cevent2cstreamtb(gesture,timebase);

            % find overlaps between gesture and eye variables
            match_idx = cst_eye(:,2) == cst_gesture(:,2);

            % create gesture-eye var
            joint_cst = timebase;
            joint_cst(:,2) = 0;
            joint_cst(match_idx,2) = cst_eye(match_idx,2);

            joint_cev = cstream2cevent(joint_cst);

            joint_cev_varname = sprintf('cevent_gesture-eye_%s-child',agent{a});
            joint_cst_varname = sprintf('cstream_gesture-eye_%s-child',agent{a});
            record_variable(sub,joint_cev_varname,joint_cev);
            record_variable(sub,joint_cst_varname,joint_cst);
        end
    end
end