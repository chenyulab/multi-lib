function master_derived_datavyu(subexpIDs)
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
        
        % fprintf('\nProcessing roi for %d\n', sub);
        make_joint_attention_smart_room(sub);
        % make_synched_attention(sub);
        
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
    end
end
