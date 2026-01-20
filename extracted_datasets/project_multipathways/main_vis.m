%%%
% Original author: Dr. Chen Yu
% Modifier: Jane Yang
% Last modified: 10/19/2023
% This function generates visualizations of child/parent eye/inhand,
% child/parent-led JA moment, and JA moment enter type, outputting
% visualizations to a specified directory.
%
% Input: subexpIDs  - subIDs or expIDs
%        output_dir - directory to output visualizations
%
% Output: one visualization per subject
% Sample function call: main_vis([12 15 27 49 58 59 71 72 73 74 75 91 351 353], 'M:\extracted_datasets\multipathways\vis')
%%%

function main_vis(subexpIDs,output_dir)
    vars = {'cevent_inhand_child','cevent_eye_joint-attend_child-lead-enter-type_both','cevent_eye_joint-attend_child-lead-moment_both','cevent_eye_roi_child','cevent_eye_roi_parent','cevent_eye_joint-attend_parent-lead-moment_both','cevent_eye_joint-attend_parent-lead-enter-type_both','cevent_inhand_parent'};
    streamlabels = {'cinhand','cJA-enter','cJA-m','ceye','peye','pJA-m','pJA-enter','pinhand'};
    vis_streams_multiwork(subexpIDs, vars, streamlabels, output_dir);
end
         