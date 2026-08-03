function make_both_inhand(IDs)
% finds when both hands are touching the same object, different object, or when only one hand is touching object
    subs = cIDs(IDs);
    agents = {'child', 'parent'};
    for s = 1:numel(subs)
        exp_id = sub2exp(subs(s));
        for a = 1:2
            if all(cellfun(@(a) has_variable(subs(s), a), {sprintf('cstream_inhand_left-hand_obj-all_%s'...
                    ,agents{a}), sprintf('cstream_inhand_right-hand_obj-all_%s',agents{a})}))
                gt = get_variable(subs(s), 'cstream_trials');
                left = get_variable(subs(s), sprintf('cstream_inhand_left-hand_obj-all_%s', agents{a}));
                right = get_variable(subs(s), sprintf('cstream_inhand_right-hand_obj-all_%s', agents{a}));
                [gt,left,right] = align_cstreams(gt,left,right);

                %% bimanual-same variables
                both = [left(:,2) right(:,2)];
                log = both(:,1) ~= both(:,2);
                both(log,:) = 0;
                both_hands = [left(:,1) both(:,1)];
                record_additional_variable(subs(s), sprintf('cstream_inhand_bimanuel-same_%s', agents{a}), both_hands);
                cev_both_hands = cstream2cevent(both_hands);
                record_additional_variable(subs(s),sprintf('cevent_inhand_bimanual-same_%s',agents{a}), cev_both_hands);

                %% bimanual-diff variable
                bimanual_diff = (right(:,2) ~= 0 & left(:,2) ~= 0) & (right(:,2) ~= left(:,2));
                right_bimanual_diff = right;
                left_bimanual_diff = left;
                right_bimanual_diff(~bimanual_diff,2) = 0;
                left_bimanual_diff(~bimanual_diff,2) = 0;
                cev_right_bidiff = cstream2cevent(right_bimanual_diff);
                cev_left_bidiff = cstream2cevent(left_bimanual_diff);
                record_additional_variable(subs(s),sprintf('cevent_inhand_right-hand_bimanual-diff_%s',agents{a}), cev_right_bidiff);
                record_additional_variable(subs(s),sprintf('cevent_inhand_left-hand_bimanual-diff_%s',agents{a}), cev_left_bidiff);

                %% hand-only variable
                r_only = left(:,2) == 0;
                l_only = right(:,2) == 0;
                right_only = right;
                left_only = left;
                right_only(~r_only,2) = 0;
                left_only(~l_only,2) = 0;
                cev_right_only = cstream2cevent(right_only);
                cev_left_only = cstream2cevent(left_only);
                record_additional_variable(subs(s), sprintf('cevent_inhand_right-hand-only_%s', agents{a}), cev_right_only);
                record_additional_variable(subs(s), sprintf('cevent_inhand_left-hand-only_%s', agents{a}), cev_left_only);
            end

            %% merged hand variable
            num_of_obj = get_num_obj(exp_id);
            input_variable = sprintf('cevent_inhand_%s',agents{a});
            data = get_variable_by_trial_cat(subs(s),input_variable);
            if isempty(data)
                fprintf('%d %s data is empty', subs(s), agents{a});
                continue;
            end
            timing = get_trial_times(subs(s));
            start_time = timing(1,1);
            end_time = timing(end,2);
            rate = 1/30;
            new_data = [];
            for i = 1:num_of_obj
                sub_data_idx = data(:,3) == i;
                sub_data = data(sub_data_idx,:);
                % convert to cstream first
                cstsream = cevent2cstream(sub_data,start_time,rate,0,end_time);
                % convert back
                cevent = cstream2cevent(cstsream);
                new_data = [new_data;cevent];
            end
            new_data = sortrows(new_data,1);
            new_varname = sprintf('cevent_inhand_merged_%s',agents{a});
            record_additional_variable(subject_id,new_varname,new_data);
        end
    end
end