function make_all_action_variable(subjectID)

% those subjects' trial time are based on unchuncked video
vip_list = [5801:5805,5807:5812];
system_start_time = 30;

expID = sub2exp(subjectID);

dictionary_path = sprintf("M:/experiment_%d/mapping_file1.xlsx",expID);
dictionaryTable = readtable(dictionary_path,'ReadVariableNames', false);
dictionary_column_name = {'letter', 'ID'};
dictionaryTable.Properties.VariableNames = dictionary_column_name;

action_dictionary_path = sprintf("M:/experiment_%d/exp_%d_action_dictionary.xlsx",expID,expID);
action_dictionaryTable = readtable(action_dictionary_path);
action_variable_names = action_dictionaryTable.variable_name;
action_matrices_target = struct();
action_matrices_next = struct();

left_action_type = 'cevent_action_left-hand_action-type_parent';
right_action_type = 'cevent_action_right-hand_action-type_parent';

left_obj_type = 'cevent_action_left-hand_obj-type_parent';
right_obj_type = 'cevent_action_right-hand_obj-type_parent';

data_path = fullfile(get_subject_dir(subjectID),'supporting_files','action.csv');
data_table = readtable(data_path);
trialInfo = load(get_info_file_path(subjectID));


% get extract range onset
extract_range_path = fullfile(get_subject_dir(subjectID),'supporting_files','extract_range.txt');
range_file = fopen(extract_range_path,'r');
extract_range_onset = fscanf(range_file,'[%f]');


% create matrix for each action
for i = 1:length(action_variable_names)
    varName = action_variable_names{i};
    action_matrices_target.(varName) = [];
end
for i = 1:length(action_variable_names)
    varName = action_variable_names{i};
    action_matrices_next.(varName) = [];
end

sdata = [];
sdata_2 = [];

% left hand
for row = 1:size(data_table,1)
    if ~isnan(data_table.action_left_ordinal(row))
        % find onset & offset
            if ismember(subjectID,vip_list)
                left_onset = (data_table.action_left_onset(row) / 1000 + trialInfo.trialInfo.camTime);
                left_offset = (data_table.action_left_offset(row) / 1000 + trialInfo.trialInfo.camTime);
            else
                left_onset = (data_table.action_left_onset(row) / 1000 + system_start_time - extract_range_onset/trialInfo.trialInfo.camRate);
                left_offset = (data_table.action_left_offset(row) / 1000 + system_start_time - extract_range_onset/trialInfo.trialInfo.camRate);
            end

        % find action name & action id
        left_action_letter = data_table.action_left_action(row);
        left_action_dictionary_row = strcmp(action_dictionaryTable.letter, left_action_letter);
        left_action_id = action_dictionaryTable.ID(left_action_dictionary_row);
        action = action_dictionaryTable.variable_name(left_action_dictionary_row);
        action = action{1};

        % find target object id and next object id
        left_target_obj = data_table.action_left_inhand_obj(row);
        left_target_obj_dictonary_row = strcmp(dictionaryTable.letter, left_target_obj);
        left_target_obj_id = dictionaryTable.ID(left_target_obj_dictonary_row);
        left_next_obj = data_table.action_left_secondary_objplace(row);
        left_next_obj_dictonary_row = strcmp(dictionaryTable.letter, left_next_obj);
        left_next_obj_id = dictionaryTable.ID(left_next_obj_dictonary_row);

        % save action type variable
        sdata = [sdata; left_onset,left_offset,left_action_id];
        sdata_2 = [sdata_2; left_onset, left_offset, left_target_obj_id];

        % save action variables for target and next
        action_matrices_target.(action) = [action_matrices_target.(action);left_onset,left_offset,left_target_obj_id];
        action_matrices_next.(action) = [action_matrices_next.(action);left_onset,left_offset,left_next_obj_id];
    end
end

% record action type variable
record_additional_variable(subjectID,left_action_type,sdata);

record_additional_variable(subjectID,left_obj_type,sdata_2)

% % record all action variables
% for i = 1:length(action_variable_names)
%     action = action_variable_names{i};
%     left_target = sprintf('cevent_action_left-hand_%s_target-obj_parent',action);
%     record_additional_variable(subjectID,left_target,action_matrices_target.(action));
%     action_matrices_target.(action) = [];
% end
% for i = 1:length(action_variable_names)
%     action = action_variable_names{i};
%     left_next = sprintf('cevent_action_left-hand_%s_next-obj_parent',action);
%     record_additional_variable(subjectID,left_next,action_matrices_next.(action));
%     action_matrices_next.(action) = [];
% end


sdata = [];
sdata_2 = [];

% right hand
for row = 1:size(data_table,1)
    if ~isnan(data_table.action_right_ordinal(row))
        % find onset & offset
            if ismember(subjectID,vip_list)
                right_onset = (data_table.action_right_onset(row) / 1000 + trialInfo.trialInfo.camTime);
                right_offset = (data_table.action_right_offset(row) / 1000 + trialInfo.trialInfo.camTime);
            else
                right_onset = (data_table.action_right_onset(row) / 1000 + system_start_time - extract_range_onset/trialInfo.trialInfo.camRate);
                right_offset = (data_table.action_right_offset(row) / 1000 + system_start_time - extract_range_onset/trialInfo.trialInfo.camRate);
            end

        % find action name & action id
        right_action_letter = data_table.action_right_action(row);
        right_action_dictionary_row = strcmp(action_dictionaryTable.letter, right_action_letter);
        right_action_id = action_dictionaryTable.ID(right_action_dictionary_row);
        action = action_dictionaryTable.variable_name(right_action_dictionary_row);
        action = action{1};

        % find target object id and next object id
        right_target_obj = data_table.action_right_inhand_obj(row);
        right_target_obj_dictonary_row = strcmp(dictionaryTable.letter, right_target_obj);
        right_target_obj_id = dictionaryTable.ID(right_target_obj_dictonary_row);
        right_next_obj = data_table.action_right_secondary_objplace(row);
        right_next_obj_dictonary_row = strcmp(dictionaryTable.letter, right_next_obj);
        right_next_obj_id = dictionaryTable.ID(right_next_obj_dictonary_row);

        % save action type variable
        sdata = [sdata; right_onset,right_offset,right_action_id];
        sdata_2 = [sdata_2; right_onset, right_offset, right_target_obj_id];

        % save action variables for target and next
        action_matrices_target.(action) = [action_matrices_target.(action);right_onset,right_offset,right_target_obj_id];
        action_matrices_next.(action) = [action_matrices_next.(action);right_onset,right_offset,right_next_obj_id];
    end
end

% record action type variable
record_additional_variable(subjectID,right_action_type,sdata);
record_additional_variable(subjectID,right_obj_type,sdata_2)

% % record all action variables
% for i = 1:length(action_variable_names)
%     action = action_variable_names{i};
%     right_target = sprintf('cevent_action_right-hand_%s_target-obj_parent',action);
%     record_additional_variable(subjectID,right_target,action_matrices_target.(action));
%     action_matrices_target.(action) = [];
% end
% for i = 1:length(action_variable_names)
%     action = action_variable_names{i};
%     right_next = sprintf('cevent_action_right-hand_%s_next-obj_parent',action);
%     record_additional_variable(subjectID,right_next,action_matrices_next.(action));
%     action_matrices_next.(action) = [];
% end

end
