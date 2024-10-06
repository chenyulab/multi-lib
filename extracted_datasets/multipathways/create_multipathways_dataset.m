%%%
% Author: Jane Yang
% Last Modifier: 10/05/2023
% Each experiment would have four data representation files. 
% {child-led/parent-led} x {moment/before}
%
% Sample function call: create_multipathways_dataset([351 353],[27 22],'..\data')
%%%

function create_multipathways_dataset(expIDs,num_obj_list)
    output_dir = 'M:\extracted_datasets\multipathways\data';
    % check if there's one number of object for each input experiment
    if numel(num_obj_list) ~= numel(expIDs)
        error('Please specify the number of objects in each experiment!');
    end

    for i = 1:numel(expIDs)
        % get current experiment and its corresponding number of objects
        expID = expIDs(i);
        num_obj = num_obj_list(i);

        % create a list of extract_multi_measures filenames
        filename_list = {fullfile(output_dir,sprintf('JA_child-lead_moment_exp%d.csv',expID)), ...
                         fullfile(output_dir,sprintf('JA_child-lead_before_exp%d.csv',expID)), ...
                         fullfile(output_dir,sprintf('JA_parent-lead_moment_exp%d.csv',expID)), ...
                         fullfile(output_dir,sprintf('JA_parent-lead_before_exp%d.csv',expID))};
        cevent_name_list = {'cevent_eye_joint-attend_child-lead-moment_both',...
                            'cevent_eye_joint-attend_child-lead_both',...
                            'cevent_eye_joint-attend_parent-lead-moment_both',...
                            'cevent_eye_joint-attend_parent-lead_both'};
        
        % create corresponding dependent variable list for extract multi
        % measure call
        if ~ismember(expID,65:69)
            var_list = {'cevent_eye_roi_child',...
                        'cevent_eye_roi_parent',...
                        'cevent_inhand_child',...
                        'cevent_inhand_parent'};
        else
            var_list = {'cevent_eye_roi_child',...
                        'cevent_eye_roi_parent',...
                        'cevent_gesture_child',...
                        'cevent_gesture_parent'};
        end
    
        
        for j = 1:width(filename_list)
            % call extract_multi_measure()
            filename = filename_list{j};
            args.cevent_name = cevent_name_list{j};
            %if ~ismember(expID,[351 353])
            args.cevent_values = 1:num_obj;
            label_matrix = ones(num_obj) * 2 + diag(-ones(num_obj,1));
            label_matrix(:,end+1) = 3;
            % elseif ismember(expID,58)
            %     args.cevent_values = 1:num_obj;
            %     label_matrix = ones(num_obj) * 2 + diag(-ones(num_obj,1));
            %     label_matrix(:,end+1) = 3;
            %elseif ismember(expID,[351 353])
            %    args.cevent_values = 2:num_obj;
            %    label_matrix = ones(num_obj) * 2 + diag(-ones(num_obj,1));
            %    label_matrix = vertcat(repmat(2,1,num_obj),label_matrix);
            %    label_matrix = horzcat(repmat(3,num_obj+1,1),label_matrix);
            %end

            args.label_matrix = label_matrix;
            args.cevent_measures = 'individual_prop';
            args.label_names = {'target', 'other','face'};
            extract_multi_measures(var_list, expID, filename, args);
        
            % generate data representation
            reformat_multipathways(expID, var_list, filename);
        end
    end
end