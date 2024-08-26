%%%
% Original author: Dr. Chen Yu
% Modifier: Jane Yang, Brianna Kaplan
% Last modified: 11/12/2023
% This function generates visualizations of child eye and inhand separate for each hand,
% child-led JA moment, and JA moment enter type, outputting
% visualizations to a specified directory.
%
% Input: subexpIDs  - subIDs or expIDs
%        output_dir - directory to output visualizations
%
% Output: one visualization per subject
% Sample function call: main_vis_parent_lead([12 15 27 49 58 59 71 72 73 74 75 91 351 353], 'M:\extracted_datasets\multipathways\vis')
%%%

function main_vis_parent_lead(subexpIDs,output_dir)
    vars = {'cevent_eye_roi_child', 'cevent_inhand_right-hand_obj-all_child', 'cevent_inhand_left-hand_obj-all_child','cevent_inhand_right-hand_obj-all_parent', 'cevent_inhand_left-hand_obj-all_parent','cevent_eye_joint-attend_parent-lead-enter-type_both','cevent_eye_joint-attend_parent-lead-moment_both'};
    streamlabels = {'ceye','cinhand-r','cinhand-l','pinhand-r','pinhand-l','pJA-enter','pJA-m',};
    vis_streams_multiwork(subexpIDs, vars, streamlabels, output_dir);
end
         