function get_exp_variables_stats(expIDs,var_list,output_dir,output_filename)
% Author: Jingwen Pang
% last modified date: 2024/8/13
% function that tallies the number of subjects with a given variable
% example call:
      % expIDs = [12 15 27 49 58 71 72 73 74 75 77 78 79 96 351 353];
      % expIDs = unique(sub2exp(cIDs(list_experiments())))';
      % var_list = {'cevent_eye_roi_child','cevent_eye_roi_parent', 'cevent_inhand_left-hand_obj-all_child','cevent_inhand_right-hand_obj-all_child','cevent_inhand_left-hand_obj-all_parent', 'cevent_inhand_right-hand_obj-all_parent', 'cevent_eye_joint-attend_both', 'cevent_speech_naming_local-id', 'cevent_speech_utterance', 'cont_vision_size_obj1_child','cont_vision_size_obj1_parent','cont_motion_h_head_child','cont_motion_h_head_parent'};
      % output_dir = '.\';
      % output_filename = 'exp_variables_stats';
      % get_exp_variables_stats(expIDs,var_list,output_dir,output_filename)

headers = {'expID','total number of subjects'};
headers = [headers,var_list];
n_of_subjs = arrayfun(@(x) length(cIDs(x)), expIDs);

data = horzcat(expIDs',n_of_subjs');

for v = 1:length(var_list)
    var = var_list{v};
    n_of_subjs = arrayfun(@(x) tryCatchFindSubjects(var,x), expIDs);
    data = horzcat(data,n_of_subjs');
end

table = array2table(data, 'VariableNames', headers);
filename = sprintf('%s.csv',output_filename);
filepath = fullfile(output_dir,filename);
writetable(table,filepath)
end

function n = tryCatchFindSubjects(var, x)
    try
        n = length(find_subjects(var, x));
    catch
        n = -1;
    end
end