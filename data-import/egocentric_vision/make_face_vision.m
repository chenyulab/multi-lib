function make_face_vision(sub_ids, agent)

    % exp_id = 351;
    % agent = 'child';
    
    face_size = sprintf('cont_vision_size_face_%s',agent);
    % sub_ids = find_subjects(face_size,exp_id);
    
    
    for s = 1:length(sub_ids)
    
        sub_id = sub_ids(s);
        num_obj = get_num_obj(sub_id);
    
        try
            cont_var = get_variable_by_trial_cat(sub_id,face_size);
            cevent_data = cont2cevent(cont_var, [0 1]);
            cevent_data(:,3) = num_obj  + 1;
        catch ME
            disp(ME.message)
            continue
        end
        
        var_name = sprintf('cevent_vision_face_%s',agent);
        record_additional_variable(sub_id,var_name,cevent_data);
    
    end

end