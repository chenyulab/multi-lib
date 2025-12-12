%%%
% Author: Jane Yang
% Last modified date: 02/29/2024
% This function reads a .csv file containing several variables coding data 
% from Datavyu and converts each target variable coding to .mat variable,
% saving each variable to corresponding subject folder.
% 
% 
% Example function call: convert_label(input_filename,var_list,mapping_filenames,first_col,time_offset,mapping_list)
%
% Input: Name                       Description
%        subID                      subID of target subject
%
%
%        var_list                   A list containing the order of 
%                                   variables coded in Datavyu, for example,
%                                   {'inhand_child_left','inhand_child_right',
%                                   'inhand_parent_left','inhand_parent_right'}.
%                                   The ORDER of the variables matters!
%
%        mapping_list               A list of numerical values describing
%                                   which mapping file each variable should
%                                   refer to. For example, for four
%                                   variables, a list could be {1,1,2,3}.
%                                   If there's only one universal mapping
%                                   file, mapping_list is default at 1.
%
%        first_col                  A number indicating which is the first
%                                   column of labeled data in the input
%                                   .csv file.
%
%        time_offset                A offset in seconds for converting raw
%                                   timestamps to system time.
%
% Output: Corresponding .mat variables will be created and saved under
% derived folder of corresponding subject.
% 
% Example function call: convert_datavyu_label(35112,{'eye_roi_child','eye_roi_parent','inhand_left-hand_obj-all_child','inhand_right-hand_obj-all_child','inhand_left-hand_obj-all_parent','inhand_right-hand_obj-all_parent'},1,243/30,{1,1,1,1,1,1})
%%%
function [cevent_mtr,cstream_mtr] = convert_datavyu_label(subID,var_list,first_col,time_offset,mapping_list)
    % system start time
    system_start = 30;

    % fixation merge threshold -- merge fixations that are less than 4
    % frames apart from each other
    merge_thres = 4;

    % generate info.mat file and trial variables
    read_trial_info(subID);
    make_trials_vars(subID)
    % trials based on continious roi time and manual trials
    make_trials_by_child_roi_vyu(subID) 
    % get trial time
    trial_times = get_trial_times(subID);
    begin_time = trial_times(1,1);
    end_time = trial_times(end,2);

    % get Datavyu input_filename from supporting file folder of each
    % subject
    root = get_subject_dir(subID);
    input_filename = fullfile(root,'supporting_files','Datavyu summary coding file.csv');

    % get mapping_filenames from experiment directory
    sub_info = get_subject_info(subID);
    mapping_root = fullfile(get_multidir_root(),['experiment_' num2str(sub_info(2))]);
    % check if there are multiple mapping files
    mapping_files_info = dir(fullfile(mapping_root,'mapping_file*.xlsx'));
    if size(mapping_files_info,1) > 1
        mapping_filenames = fullfile(mapping_root,cellstr(vertcat(mapping_files_info.name)));
    elseif size(mapping_files_info,1) == 1
        mapping_filenames = fullfile(mapping_root,cellstr(mapping_files_info.name));
    else
        error('No mapping files found in the experiment directory.')
    end

    % check if the size of mapping_list matches the number of variables
    if width(mapping_list) ~= width(var_list) && width(mapping_list) ~= 1
        error('Please enter the correct mapping list.')
    end

    % read summary input data file
    data = readtable(input_filename);

    % iterate through var_list and convert each variable
    for i = 1:width(var_list)
        % fetch for the correct mapping file
        if width(mapping_list) == 1
            % one universal mapping file
            curr_map_file = mapping_filenames{1};
    
            % read universal mapping file, if there's only one
            mapping = readtable(curr_map_file);
        else
            % different mapping file for different variable
            curr_map_file = mapping_filenames{mapping_list{i}};
            mapping = readtable(curr_map_file);
        end

        label_map = string(table2array(mapping(:,1)));
        ROI_map = table2array(mapping(:,2));
        ROI_num = size(mapping,1);

        % parse current variable
        var_name = var_list(i);
        onset_col_num = first_col + (i-1)*4 + 1;
        offset_col_num = first_col + (i-1)*4 + 2;
        label_col_num = first_col + (i-1)*4 + 3;
    
        % get column data
        onset = data.(onset_col_num);
        offset = data.(offset_col_num);
        label = data.(label_col_num);

        % get rid of trailing NaN values
        onset = onset(~isnan(onset));
        offset = offset(~isnan(offset));
        label = label(~cellfun('isempty',label));

        new_onset = zeros(size(onset));
        new_offset = zeros(size(offset));
        new_label = zeros(size(label));

        for j = 1:size(label,1)
            % disp(size(label,1));
            match_roi = ROI_map(strcmp(label_map,label(j)),1);
            
            % convert raw timestamps to system time
            new_onset(j) = onset(j)/1000;
            new_offset(j) = offset(j)/1000;
            new_onset(j) = new_onset(j) - time_offset + system_start;
            new_offset(j) = new_offset(j) - time_offset + system_start;

            % convert string label to numeric objID
            if size(match_roi,1) == 1
                new_label(j) = match_roi;
            else
                new_label(j) = nan;
            end
        end

        % Save variables in derived folder in Multiwork experiment folder
        % save cevent var
        cevent_mtr = [new_onset new_offset new_label];
        record_variable(subID,['cevent_' char(var_name)],cevent_mtr);
        rate = get_rate(subID);

        % save cstream var
        cstream_mtr = cevent2cstream(cevent_mtr,begin_time,1/rate,0,end_time);
        record_variable(subID,['cstream_' char(var_name)],cstream_mtr);

        % check if current variable is a fixation variable
        % If so, merge fixations and generate eye ROI variables
        if contains(var_name,'eye_roi')
            cat_list = [1:ROI_num];
            % merge two consecutive fixations less than 4 frames away
            % from each other, if two instances are on the same object
            cevent_merged = cevent_merge_segments(cevent_mtr, merge_thres/rate,cat_list);
            cstream_merged = cevent2cstream(cevent_merged,begin_time,1/rate,0,end_time); % convert to cstream
            
            % parse current varname to get the agent field
            
            parsed = strsplit(var_name{1},'_');
            agent = parsed{end};

            % generate cevent/cstream_eye_roi_child/parent variable
            cevent_merged_varname = ['cevent_eye_roi_' agent];
            cstream_merged_varname = ['cstream_eye_roi_' agent];
            record_variable(subID,cevent_merged_varname,cevent_merged);
            record_variable(subID,cstream_merged_varname,cstream_merged);
        end
    end

    % generate naming variables
    make_utterance_by_whisper(subID);

    % make system-time speech transcription file
    make_system_time_trans(subID);
end