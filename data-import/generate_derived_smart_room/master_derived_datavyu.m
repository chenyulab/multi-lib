function master_derived_datavyu(subexpIDs,hasInhand,hasSaccadesAndEyegaze)
% postfixation
% all
%   trial
%   inhand
%   roi
%   ja
%   inhand-roi
    full_sub_list = cIDs(subexpIDs);
    agents = {'child','parent'};

    for i = 1:size(full_sub_list,1)
        sub = full_sub_list(i);
        make_trials_vars(sub);
        exp = sub2exp(sub);
        
        % fprintf('\nProcessing roi for %d\n', sub);
        make_joint_attention_smart_room(sub);
        % make_synched_attention(sub);
        
        if hasInhand
            fprintf('\nProcessing inhand for %d\n', sub);
            for a = 1:2
                agent = agents{a};
                cstlh = get_variable(sub, sprintf('cstream_inhand_left-hand_obj-all_%s', agent));
                cstrh = get_variable(sub, sprintf('cstream_inhand_right-hand_obj-all_%s', agent));
                cevlh = cstream2cevent(cstlh);
                cevrh = cstream2cevent(cstrh);
                cevlh(isnan(cevlh(:,3)),:) = [];
                cevrh(isnan(cevrh(:,3)),:) = [];
                cevboth = cat(1, cevlh, cevrh);
                cevboth = sortrows(cevboth, [1 2 3]);
            
                record_variable(sub, sprintf('cevent_inhand_%s', agent), cevboth);
            end
            make_both_inhand(sub);
            
            fprintf('\nProcessing inhand/roi for %d\n', sub);
            make_joint_eye_inhand_smart_room(sub);

            % generate new version of inhand-eye variables
            make_all_inhand_eye(sub);
        end
        
        % generate saccades & eyegaze variable
        if hasSaccadesAndEyegaze
            for a = 1:2
                agent = agents{a};
                make_saccades(sub,agent);
                record_eyegaze_datavyu(sub,agent);
            end
        end

        % generate sustained attention variables
        master_make_sustained(sub, [4,7,9])
        
        % if it is 351, update score tables and generate known variables
        if exp == 351
            
            var_list = {'cevent_eye_roi_child', 'cevent_eye_roi_parent', 'cevent_speech_naming_local-id'};
            scores = [0 1 2];
            label = 'known-words';
            sub_item_file = 'M:\experiment_351\exp351_scoretable_name.xlsx';
            if hasInhand
                var_list = [var_list, {'cevent_inhand_child', 'cevent_inhand_parent'}];
            end
            read_home_survey_toys(sub)
            make_split_vars_by_item(sub, var_list, sub_item_file, scores, label)

        end

        % make CORE variables visualization
        make_experiment_vis(sub, 1);
        % generate derived variables visualization
        make_experiment_vis(sub, 2);
        make_experiment_vis(sub, 3);
    end
end
