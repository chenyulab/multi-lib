%%%
% Author: Jingwen Pang
% Last modifier: 10/31/2023
%
% - The 'master_naming_onset_after3' function is designed to process naming events and measures after a 3-second interval. The function outputs a CSV file with naming onset data and a MAT file containing two variables: 'naming_event' and 'naming_measure'.
% 
% Base variables: 'cevent_speech_naming_local-id'
% Dependent variables: 'cevent_eye_roi_child', 'cevent_eye_roi_parent','cevent_inhand_child', 'cevent_inhand_parent','cevent_eye_joint-attend_child-lead-moment_both','cevent_eye_joint-attend_parent-lead-moment_both'
% 
% 
% Input Parameters
% 
% - exp_list: A list of experiment IDs. It can contain multiple experiment IDs.
% - cevent_name: the type of naming variable
%   - case 1: all naming
%   - case 2: known-unknown naming 
% - num_obj_list: A list of number of objects for exp_list
% - flag: An indicator for processing mode:
%   - '1': Target mode. Process data related to the target object.
%   - '2': Process data for all objects.
% - output filename
% 
% 
% Outputs
% - CSV File: naming onset after 3 second
% - MAT File: A MAT file containing two variables: 'naming_events' and 'naming_measure'.
%       (variable detail is in the 'generate_naming_event_measure' function's document)
%
% exp_list = [12,15,27,49,58,71,72,73,74,75,91,351,353];
% num_obj_list = [24,10,24,3,22,3,3,3,3,3,24,28,22];
%
% cevent_names = 'cevent_speech_naming_local-id';
% 'cevent_speech_unknown-words'; 'cevent_speech_known-words'
%
% example input: create_naming_dataset([12], 'cevent_speech_unknown-words', 24, 1,'../data','unknown_naming')
%%%

function create_naming_dataset(exp_list, cevent_name, num_obj_list, flag, output_dir, output_filename)
    % 1 for target, 2 or all
    if flag == 1
        type = 'target';
    else
        type = 'all';
    end
    % dependent variable list
    var_list = {'cevent_eye_roi_child', 'cevent_eye_roi_parent','cevent_gesture_child', 'cevent_gesture_parent',...
        'cevent_eye_joint-attend_child-lead-moment_both','cevent_eye_joint-attend_parent-lead-moment_both'};

    % go through each experiment
    for exp = 1 : length (exp_list)       
        exp_ID = [exp_list(exp)];
        num_obj = [num_obj_list(exp)];
        
        file_name =fullfile(output_dir, sprintf('%s_onset_after3_%s_exp%d.csv',output_filename,type, exp_ID));
        args.cevent_measures = {'individual_prop_by_cat'};
        args.cevent_name = cevent_name; 
        args.cevent_values = 1:num_obj;
        args.whence = 'start';
        args.interval = [0 3];

        % target vs. all
        if flag == 1
            args.label_matrix = ones(num_obj) * 2 + diag(-ones(num_obj,1));
            args.label_names = {'target', 'other'};
            % if ismember(exp_ID,[351 353])
            %     args.label_matrix(end+1, :) = 2; % add 1 row
            %     args.label_matrix([1 end], :) = args.label_matrix([end 1], :); % swap last row to first row
            %     args.label_matrix(:, end+1) = 3; % add new column
            %     args.label_matrix(:, [1 end]) = args.label_matrix(:, [end 1]); % swap last column to first column
            %     args.label_names = {'target', 'other', 'face'};
            % end
        else
            for i = 1 : num_obj
                args.label_matrix(i,:) = args.cevent_values;
            end
            args.label_names = arrayfun(@num2str, 1:num_obj, 'UniformOutput', 0);
        end
        
        extract_multi_measures(var_list, exp_ID, file_name, args);
        args.label_matrix = [];
        reshape_naming_event_measure(num_obj, file_name);
    end

end


