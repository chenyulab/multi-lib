function obj_label = get_object_label(exp_id, obj_id)
% Author: Jingwen Pang
% Date: 11/19/2024
%
% given the exp id & object id, go to dictionary file and find object label
% key_exp_list = [12, 15, 27, 58, 65, 66, 67, 68, 69, 77, 78, 79, 96, 351, 353, 361, 362, 363];
%
% example call: get_object_label(351, 16)
    obj_id_col = 3;
    obj_name_col = 1;

    try
        dir = fullfile(get_multidir_root,sprintf('experiment_%d',exp_id));
        
        filename = sprintf('exp_%d_dictionary.xlsx',exp_id);
        
        data = readtable(fullfile(dir,filename));
        
        obj_label = data{data{:,obj_id_col}==obj_id,obj_name_col}{1};
    
    catch ME
    
        disp(ME.message)

        obj_label = '';
    end

end

