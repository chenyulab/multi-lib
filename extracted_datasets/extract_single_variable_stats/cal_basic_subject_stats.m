%%%
% This function reads the results from extract basic stats and generate a
% overall object & face timing and frequency in subject level
%
% Author: Jingwen Pang
% Last Edited: 9/30/2024
% input parameters:
%   - exp_ids: list of experiments
%   - var_list(optional): list of variables default variables are:
%           - eye roi child/parent
%           - speech naming
%           - JA both
%           - JA child/parent-lead
%           - child/parent inhand
% output file:
%   - basic_subject_stats_exp-%s.csv in M:\extracted_datasets\single_variable_stats\results
%
% example call:
%   - cal_basic_subject_stats([77 78 79])
%%%
function cal_basic_subject_stats(exp_ids,var_list)
    % if variable list does not exist, use the default one
    if ~exist("var_list","var")
        var_list = {'cevent_eye_roi_child', 'cevent_eye_roi_parent','cevent_speech_naming_local-id', 'cevent_eye_joint-attend_both','cevent_eye_joint-attend_child-lead-moment_both','cevent_eye_joint-attend_parent-lead-moment_both', 'cevent_inhand_child', 'cevent_inhand_parent'};
    end
    headers = {'subID','total time'};
    co_headers = {'obj time','face time','obj freq','face freq'};
    results_path = 'M:/extracted_datasets/extract_single_variable_stats/results';
    start_col = length(headers);
    
    % create headers
    for i = 1:length(var_list)
        var = var_list{i};
        var = split(var,'_');
        var = strjoin(var(2:end));
    
        for j = 1:length(co_headers)
            name = [var, ' ', co_headers{j}];
            headers = [headers,name];
        end
    end
    
    
    rtr_data = [];
    for e = 1:length(exp_ids)
        exp_id = exp_ids(e);
        num_obj = get_num_obj(exp_id);
        sub_list = find_subjects(var_list,exp_id);
        exp_data = [];
        
        % create trial length for each subject
        trial_list = [];
        for s = 1:length(sub_list)
            sub_id = sub_list(s);
            trial = get_trial_times(sub_id);
            trial_time = sum(trial(:,2)-trial(:,1));
            trial_list = [trial_list;trial_time];
        end
    
        exp_data = horzcat(sub_list,trial_list);
    
        % get each variable timing and frequency by reading the variable
        % basic stats
        for v = 1:length(var_list)
            var = var_list{v};
            filename = [var sprintf('_exp%d.xlsx',exp_id)];
            filepath = fullfile(results_path,filename);
            
            % check if file exist
            if exist(filepath, 'file') == 2

                time_data = table2array(readtable(filepath,'Sheet', 1));
                freq_data = table2array(readtable(filepath,'Sheet', 2));

                % matched subject id
                idx = ismember(time_data(:,1),sub_list);
                time_obj = sum(time_data(idx,start_col+(num_obj+1)+1:start_col+(num_obj+1)+num_obj),2);
                time_face = time_data(idx,start_col+2*(num_obj+1));
        
                freq_obj = sum(freq_data(idx,start_col+(num_obj+1)+1:start_col+(num_obj+1)+num_obj),2);
                freq_face = freq_data(idx,start_col+2*(num_obj+1));
        
                exp_data = horzcat(exp_data,time_obj,time_face,freq_obj,freq_face);
            % if not exist, input placeholders
            else
                empty_mtr = zeros(length(sub_list),4);
                exp_data = horzcat(exp_data,empty_mtr);
            end
    
        end
        rtr_data = vertcat(rtr_data,exp_data);
    end
    
    % write into table
    rtr_table = array2table(rtr_data,'VariableNames',headers);
    exp_name = arrayfun(@num2str, exp_ids, 'UniformOutput', false);
    exp_name = strjoin(exp_name, ',');
    table_name = sprintf('basic_subject_stats_exp-%s.csv',exp_name);
    writetable(rtr_table,fullfile(results_path,table_name));
end
