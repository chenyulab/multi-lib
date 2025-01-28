function obj_labels = get_object_label(exp_id, obj_ids)
% Author: Jingwen Pang
% Date: 11/19/2024
%
% given the exp id & object id, go to dictionary file and find object label
% key_exp_list = [12, 15, 27, 58, 65, 66, 67, 68, 69, 77, 78, 79, 96, 351, 353, 361, 362, 363];
%
% example call: get_object_label(351, 16)
    obj_id_col = 3;
    obj_name_col = 1;

    % if the exp belong to one of the following experiment, change the
    % obj_id_col to 5
    special_exps = [6, 14, 17, 18, 22, 23, 29, 32, 34, 35, 36, 39, 41, 42, 43, 44, 49, 53, 54, 55, 56, 59, 62, 63, 70, 71, 72, 73, 74, 90];
    if ismember(exp_id,special_exps)
        obj_id_col = 5;
    end

    try
        dir = fullfile(get_multidir_root,sprintf('experiment_%d',exp_id));
        
        filename = sprintf('exp_%d_dictionary.xlsx',exp_id);
        
        data = readtable(fullfile(dir,filename));

        if ismatrix(obj_ids) && length(obj_ids) > 1
            obj_labels = {};
            for o = 1:length(obj_ids)
                obj_id = obj_ids(o);
                obj_label = data{data{:,obj_id_col}==obj_id,obj_name_col};
                if length(obj_label) > 1
                    combined_obj_labels = '';
                    for i = 1:length(obj_label)
                        combined_obj_labels = [combined_obj_labels,obj_label{i},'/'];
                    end
                    combined_obj_labels = combined_obj_labels(1:end-1);
                    obj_label = combined_obj_labels;
                else
                    obj_label = obj_label{1};
                end
                obj_labels = [obj_labels,obj_label];
            end
        else
            obj_label = data{data{:,obj_id_col}==obj_ids,obj_name_col};
            if length(obj_label) > 1
                combined_obj_labels = '';
                for i = 1:length(obj_label)
                    combined_obj_labels = [combined_obj_labels,obj_label{i},'/'];
                end
                combined_obj_labels = combined_obj_labels(1:end-1);
                obj_label = combined_obj_labels;
            else
                obj_label = obj_label{1};
            end
            obj_labels = obj_label;
            
        end
    
    catch ME
    
        disp(ME.message)

        obj_labels = '';
    end

end

