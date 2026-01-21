
%%%
% Author: Jane Yang
% Last modified: 2/15/2024
%
% This demo function shows different 
%
% Input:
%       option_variable - which variables to consider (JA,
%       sustained, child, parent)
%       option_exp  - which experiments' subjects to generate data for
%       option_special_case - get all cevent variables in the subject
%       folder for experiment 96
%
% Output: 
% Sheet 1 contains results1 matrix, which has the total proportion of time
% each subject spent looking/holding/naming/being in JA on each object.
%
% Sheet 2 contains results2 matrix, which has the numbers of
% looking/holding/naming/being in JA on each object for each subject.
%
% Sheet 3 contains results3 matrix, which contains the distribution of
% counts that each subject spent on each object.
%
%
% Example function call: demo_extract_basic_stats(option_variable,option_exp,option_special_case)

function demo_extract_basic_stats(option_variable,option_exp,option_special_case)

    % option_variable = 4; 
    % option_exp = 3;
    % 
    % option_special_case = 1;
    
    switch option_variable 
        case 1 % JA basic stats
            var_list = {'cevent_eye_roi_child', 'cevent_eye_roi_parent',...
                        'cevent_speech_naming_local-id','cevent_eye_joint-attend_both',... 
                        'cevent_eye_joint-attend_child-lead-moment_both','cevent_eye_joint-attend_parent-lead-moment_both'};
        case 2 % sustained basic stats
            var_list ={'cevent_eye_roi_sustained-3s_child','cevent_inhand-eye_sustained-3s_child-child',...
                       'cevent_inhand-eye_sustained-3s_parent-parent','cevent_inhand-eye_sustained-3s_child-parent',...
                       'cevent_inhand-eye_sustained-3s_parent-child'};
        case 3 % child basic stats
            var_list ={'cevent_eye_roi_child','cevent_inhand_child','cevent_inhand-eye_child-child'};
        case 4 % parent basic stats
            var_list ={'cevent_eye_roi_child','cevent_eye_roi_parent','cevent_inhand-eye_parent-child'};
    end
    
    switch option_exp
        case 1              
            exp_ids = [77 78 79 80];
            num_roi = 11;
        case 2
            exp_ids = [96];
            num_roi = 7;
        case 3 % PBJ Experiments
            exp_ids = [ 58 353 59]; 
            num_roi = 29; 
    end
    
    switch option_special_case
        case 1
            exp_ids = [96];
            num_roi = 7;
    
            % get all cevent variables in the subject folder
            var_list = list_variables(exp_ids,'cevent');
            var_list = var_list';
    end
    
    
    for i = 1: length(var_list)
        extract_basic_stats(var_list{i},exp_ids, num_roi);
    end
end



   