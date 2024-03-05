% Author: Ruchi Shah
 % Summary
    % This function outputs a visualization into each experiement's
    % corresponding folder. If a folder does not exist it creates one.
    % Arguments 
    % sub_expID
    %       -- supply an array of subject IDs or an experiment ID
    % option
    %       -- what type of visualizations (see cases below)

    function make_experiment_vis(sub_expIDs, option)
    % Variables
    for i = 1:length(sub_expIDs)
        disp(sub_expIDs(i))
        exp_dir = get_experiment_dir(sub_expIDs(i));
        switch option
            case 1 % CORE visualizations 
                vars = {'cevent_eye_roi_child', 'cevent_eye_roi_parent',...
                        'cevent_inhand_left-hand_obj-all_child', 'cevent_inhand_right-hand_obj-all_child',...
                        'cevent_inhand_left-hand_obj-all_parent','cevent_inhand_right-hand_obj-all_parent',...
                        'cevent_speech_naming_local-id'};
                
                streamlabels = {'ceye', 'peye', 'c_L_hand', 'c_R_hand', 'p_L_hand', 'p_R_hand','naming'};
                directory = fullfile(exp_dir, 'included', 'data_vis', 'CORE');
                
                if ~exist(directory, 'dir')
                   mkdir(directory)
                end
                
                vis_streams_multiwork(sub_expIDs(i), vars, streamlabels, directory);
            case 2 % JA visualizations
                vars = {'cevent_eye_roi_child', 'cevent_eye_roi_parent',...
                        'cevent_inhand_child', 'cevent_inhand_parent',...
                        'cevent_eye_joint-attend_child-lead-moment_both',...
                        'cevent_eye_joint-attend_parent-lead-moment_both'};

                streamlabels = {'ceye', 'peye', 'c_hand', 'p_hand', 'JA_c_lead', 'JA_p_lead'};
                directory = fullfile(exp_dir, 'included', 'data_vis', 'JA');
                
                if ~exist(directory, 'dir')
                   mkdir(directory)
                end
                
                vis_streams_multiwork(sub_expIDs(i), vars, streamlabels, directory);
            case 3 % inhand results
                vars = {'cevent_eye_roi_child', 'cevent_eye_roi_no-inhand_child',...
                        'cevent_inhand_left-hand_obj-all_child','cevent_inhand_right-hand_obj-all_child',...
                        'cevent_inhand-eye_type_child-child', 'cevent_inhand-eye_1hand1obj_eye-on_child-child',...
                        'cevent_inhand-eye_1hand1obj_eye-off_child-child', 'cevent_inhand-eye_2hand1obj_eye-on_child-child',...
                        'cevent_inhand-eye_2hand1obj_eye-off_child-child', 'cevent_inhand-eye_2hand2obj_eye-on_target_child-child',...
                        'cevent_inhand-eye_2hand2obj_eye-on_other_child-child', ...
                        'cevent_inhand-eye_2hand2obj_eye-off_child-child', 'cevent_inhand_no-eye_child'};
                
                var_labels = {'ceye', 'ceyew/oh', 'clh', 'crh', 'ccType', 'cc1h1oOn', 'cc1h1oOff', 'cc2h1oOn', 'cc2h1oOff',...
                              'cc2h2oOnT', 'cc2h2oOnO', 'cc2h2oOff','cNoEye'};
                directory = fullfile(exp_dir, 'included', 'data_vis', 'inhand_eye', 'inhand_eye_child_child');
                
                if ~exist(directory, 'dir')
                   mkdir(directory)
                end
                
                vis_streams_multiwork(subexpIDs(i), vars, var_labels, directory);
                
                vars = {'cevent_eye_roi_parent', 'cevent_eye_roi_no-inhand_parent',...
                        'cevent_inhand_left-hand_obj-all_parent','cevent_inhand_right-hand_obj-all_parent',...
                        'cevent_inhand-eye_type_parent-parent', 'cevent_inhand-eye_1hand1obj_eye-on_parent-parent',...
                        'cevent_inhand-eye_1hand1obj_eye-off_parent-parent', 'cevent_inhand-eye_2hand1obj_eye-on_parent-parent',...
                        'cevent_inhand-eye_2hand1obj_eye-off_parent-parent', 'cevent_inhand-eye_2hand2obj_eye-on_target_parent-parent',...
                        'cevent_inhand-eye_2hand2obj_eye-on_other_parent-parent', ...
                        'cevent_inhand-eye_2hand2obj_eye-off_parent-parent', 'cevent_inhand_no-eye_parent'};
                
                var_labels = {'peye', 'peyew/oh', 'plh', 'prh', 'ppType', 'pp1h1oOn', 'pp1h1oOff', 'pp2h1oOn', 'pp2h1oOff',...
                              'pp2h2oOnT', 'pp2h2oOnO', 'pp2h2oOff','pNoEye'};
                directory = fullfile(exp_dir, 'included', 'data_vis', 'inhand_eye', 'inhand_eye_parent_parent');
                
                if ~exist(directory, 'dir')
                   mkdir(directory)
                end
                
                vis_streams_multiwork(subexpIDs(i), vars, var_labels, directory);
                
                vars = {'cevent_eye_roi_child', ...
                        'cevent_inhand_left-hand_obj-all_parent','cevent_inhand_right-hand_obj-all_parent',...
                        'cevent_inhand-eye_type_parent-child', 'cevent_inhand-eye_1hand1obj_eye-on_parent-child',...
                        'cevent_inhand-eye_1hand1obj_eye-off_parent-child', 'cevent_inhand-eye_2hand1obj_eye-on_parent-child',...
                        'cevent_inhand-eye_2hand1obj_eye-off_parent-child', 'cevent_inhand-eye_2hand2obj_eye-on_target_parent-child',...
                        'cevent_inhand-eye_2hand2obj_eye-on_other_parent-child', ...
                        'cevent_inhand-eye_2hand2obj_eye-off_parent-child'};
                
                var_labels = {'ceye', 'plh', 'prh', 'pcType', 'pc1h1oOn', 'pc1h1oOff', 'pc2h1oOn', 'pc2h1oOff',...
                              'pc2h2oOnT', 'pc2h2oOnO', 'pc2h2oOff'};
                directory = fullfile(exp_dir, 'included', 'data_vis', 'inhand_eye', 'inhand_eye_parent_child');
                
                if ~exist(directory, 'dir')
                   mkdir(directory)
                end
                
                vis_streams_multiwork(subexpIDs(i), vars, var_labels, directory);
                
                vars = {'cevent_eye_roi_parent', ...
                        'cevent_inhand_left-hand_obj-all_child','cevent_inhand_right-hand_obj-all_child',...
                        'cevent_inhand-eye_type_child-parent', 'cevent_inhand-eye_1hand1obj_eye-on_child-parent',...
                        'cevent_inhand-eye_1hand1obj_eye-off_child-parent', 'cevent_inhand-eye_2hand1obj_eye-on_child-parent',...
                        'cevent_inhand-eye_2hand1obj_eye-off_child-parent', 'cevent_inhand-eye_2hand2obj_eye-on_target_child-parent',...
                        'cevent_inhand-eye_2hand2obj_eye-on_other_child-parent', ...
                        'cevent_inhand-eye_2hand2obj_eye-off_child-parent', 'cevent_inhand_no-eye_child'};
                
                var_labels = {'peye', 'clh', 'crh', 'cpType', 'cp1h1oOn', 'cp1h1oOff', 'cp2h1oOn', 'cp2h1oOff',...
                              'cp2h2oOnT', 'cp2h2oOnO', 'cp2h2oOff'};
                directory = fullfile(exp_dir, 'included', 'data_vis', 'inhand_eye', 'inhand_eye_child_parent');
                
                if ~exist(directory, 'dir')
                   mkdir(directory)
                end
                
                vis_streams_multiwork(subexpIDs(i), vars, var_labels, directory);

                
        end
    end
    fclose('all');
end

