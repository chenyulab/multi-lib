%%%
% Author: Jingwen Pang
% Date: 6/16/2025
% 
% This function processes a cevent variable and a list of subexpIDs. It calculates transition frequencies between categories:
% max_gap: maximum time allowed between consecutive events to count as a transition
% min_length: minimum duration required for an event to be included
% it outputs:
% An overall transition matrix sheet,
% subject-level sheets
%
% example call:
% cevent = 'cevent_eye_roi_child';
% subexpID = 351;
% output_file = 'transition_child_eye_351.xlsx';
% max_gap = inf;
% min_length = 0;
% count_cat_cat_transition_freq(subexpID, cevent, output_file, max_gap, min_length)
%%%
function count_cat_cat_transition_freq(subexpID, cevent, output_file, max_gap, min_length)
    sub_ids = cIDs(subexpID);
    
    % Initialize transition matrix
    cat_list = 1:get_num_obj(subexpID);
    labels = get_object_label(subexpID,cat_list);
    overall_matrix = zeros(length(cat_list), length(cat_list));
    
    headers = [{'cat_label'}, labels];
    
    transition_table = {};
    sheet_list = [0,sub_ids'];
    
    for s = 1:length(sub_ids)
    
        sub_id = sub_ids(s);
        transition_idx = find(sheet_list == sub_id);
        
        % Load data
        data = get_variable_by_trial_cat(sub_id, cevent);
        
        sub_matrix = zeros(length(cat_list), length(cat_list));
        
        % Filter out short instances
        instance_lengths = data(:,2) - data(:,1);
        valid_rows = instance_lengths >= min_length;
        data = data(valid_rows, :);
        
        % Recompute size after filtering
        n = size(data, 1);
        
        % Loop through pairs of consecutive valid events
        for i = 1:n-1
            onset = data(i,1);
            offset = data(i,2);
            value = data(i,3);
        
            onset_next = data(i+1,1);
            offset_next = data(i+1,2);
            value_next = data(i+1,3);
        
            % Check gap between current offset and next onset
            gap = onset_next - offset;
            if gap > max_gap
                continue
            end
        
            % Skip if same value (no transition)
            if value == value_next
                continue
            end
        
            % Update transition count
            value_idx = find(cat_list == value);
            value_idx_next = find(cat_list == value_next);
    
            sub_matrix(value_idx, value_idx_next) = sub_matrix(value_idx, value_idx_next) + 1;
            overall_matrix(value_idx, value_idx_next) = overall_matrix(value_idx, value_idx_next) + 1;
        end
        
        sub_table = cell2table(horzcat(labels', num2cell(sub_matrix)), "VariableNames", headers);
        transition_table{transition_idx} = sub_table;
    
    end
    
    overall_table = cell2table(horzcat(labels', num2cell(overall_matrix)), "VariableNames", headers);
    
    transition_table{1} = overall_table;
    
    % Delete existing file to remove default Sheet1
    if exist(output_file, 'file')
        delete(output_file);
        fprintf('Deleted existing file: %s\n', output_file);
    end
    
    for i = 1:length(transition_table)
        data = transition_table{i};
        subject_id = sheet_list(i);
    
        % Create sheet name
        if subject_id == 0
            sheetName = 'overall';
        else
            sheetName = sprintf('%d', subject_id);
        end
    
        % Debug info
        fprintf('Writing to sheet: %s\n', sheetName);
    
        % Write only if data is non-empty
        if ~isempty(data) && width(data) > 0
            writetable(data, output_file, ...
                'Sheet', sheetName);  % R2020a+
        else
            warning('Sheet %s is empty. Skipping.', sheetName);
        end
    end
end