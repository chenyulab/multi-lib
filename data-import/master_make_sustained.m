function exceptions = master_make_sustained(IDs, option)

if numel(option) > 1
    exceptions = {};
    for o = 1:numel(option)
        exceptions{o,1} = master_make_sustained(IDs, option(o));
    end
    if isempty(exceptions)
        disp('No exceptions');
    end
    return
end

subs = cIDs(IDs);

switch option
    
    case 1 % child obj dominance 1s
        
        min_max_gap = 0.5;
        max_max_gap = 1;
        min_duration = 1;
        variable_name = 'cevent_vision_size_obj-dominant_child';
        
        output_name = 'cevent_vision_size_obj-dominant_sustained-1s_child';
        record_cstream = 1;

        
    case 2 % child obj dominance 3s
        min_max_gap = 0.5;
        max_max_gap = 1;
        min_duration = 3;
        variable_name = 'cevent_vision_size_obj-dominant_child';
        
        output_name = 'cevent_vision_size_obj-dominant_sustained-3s_child';
        record_cstream = 1;
        
    case 3 % inhand-eye 1s
        min_max_gap = 0.5;
        max_max_gap = 1;
        min_duration = 1;
        variable_name = {'cevent_inhand-eye_child-child'
            'cevent_inhand-eye_child-parent'
            'cevent_inhand-eye_parent-child'
            'cevent_inhand-eye_parent-parent'};
        
        output_name = {'cevent_inhand-eye_sustained-1s_child-child'
            'cevent_inhand-eye_sustained-1s_child-parent'
            'cevent_inhand-eye_sustained-1s_parent-child'
            'cevent_inhand-eye_sustained-1s_parent-parent'};
        record_cstream = 1;
        
 
    case 4 % inhand-eye 3s
        min_max_gap = 0.5;
        max_max_gap = 1;
        min_duration = 3;
        variable_name = {'cevent_inhand-eye_child-child'
            'cevent_inhand-eye_child-parent'
            'cevent_inhand-eye_parent-child'
            'cevent_inhand-eye_parent-parent'};
        
        output_name = {'cevent_inhand-eye_sustained-3s_child-child'
            'cevent_inhand-eye_sustained-3s_child-parent'
            'cevent_inhand-eye_sustained-3s_parent-child'
            'cevent_inhand-eye_sustained-3s_parent-parent'};
        record_cstream = 1;
        
    case 5 % child big 1s
        min_max_gap = 0.5;
        max_max_gap = 1;
        min_duration = 1;
        variable_name = 'cevent_vision_size_obj-big_child';
        
        output_name = 'cevent_vision_size_obj-big_sustained-1s_child';
        record_cstream = 1;
        
    case 6 % child big 3s
        min_max_gap = 0.5;
        max_max_gap = 1;
        min_duration = 3;
        variable_name = 'cevent_vision_size_obj-big_child';
        
        output_name = 'cevent_vision_size_obj-big_sustained-3s_child';
        record_cstream = 1;
        
    case 7 % roi sustained 3s
        min_max_gap = 0.5;
        max_max_gap = 1;
        min_duration = 3;
        variable_name = 'cevent_eye_roi_child';
        
        output_name = 'cevent_eye_roi_sustained-3s_child';
        record_cstream = 1;
        
    case 8 % roi sustained 1s
        min_max_gap = 0.25;
        max_max_gap = 1;
        min_duration = 1;
        variable_name = 'cevent_eye_roi_child';
        
        output_name = 'cevent_eye_roi_sustained-1s_child';
        record_cstream = 1;
        
    case 9
        min_max_gap = 0.5;
        max_max_gap = 1;
        min_duration = 3;
        variable_name = 'cevent_eye_roi_parent';
        
        output_name = 'cevent_eye_roi_sustained-3s_parent';
        record_cstream = 1;
        
    case 10
        min_max_gap = 0.5;
        max_max_gap = 1;
        min_duration = 1;
        variable_name = 'cevent_eye_roi_parent';
        
        output_name = 'cevent_eye_roi_sustained-1s_parent';
        record_cstream = 1;

    case 11
        min_max_gap = 0.5;
        max_max_gap = 1;
        min_duration = 3;
        variable_name = 'cevent_inhand_left-hand_obj-all_child';
        
        output_name = 'cevent_inhand_left-hand_obj-all_sustained-3s_child';
        record_cstream = 1;

    case 12
        min_max_gap = 0.5;
        max_max_gap = 1;
        min_duration = 3;
        variable_name = 'cevent_inhand_right-hand_obj-all_child';
        
        output_name = 'cevent_inhand_right-hand_obj-all_sustained-3s_child';
        record_cstream = 1;
end;

% a new version of merging, if gap < max_max_gap but > min_max_gap, each  of the two to-be-merged
% segments should be longer than max_max_gap/2;
exceptions = {};
e =1;
for s = 1:numel(subs)
    if ~iscell(variable_name)
        variable_name = {variable_name};
    end
    if ~iscell(output_name)
        output_name = {output_name};
    end
    for v = 1:numel(variable_name)
        if strcmp(variable_name{v},'cevent_eye_roi_child') || strcmp(variable_name{v},'cevent_eye_roi_parent')
            cat_list = [1:get_num_obj(subs(s))+1];
        else
            cat_list = [1:get_num_obj(subs(s))];
        end
        try
            cevent = get_variable(subs(s), variable_name{v});
            cevent = cevent_merge_segments(cevent,min_max_gap, cat_list);
            new_cev = cevent(1,:);
            for c = 2:length(cevent)
                if (cevent(c,2)-cevent(c,1) >= max_max_gap/2 && new_cev(end,2)-new_cev(end,1) >= max_max_gap/2 && cevent(c,1)-new_cev(end,2) <= max_max_gap && cevent(c,3) == new_cev(end,3))
                    new_cev(end, 2) = cevent(c,2);
                else
                    new_cev = [new_cev; cevent(c,:)];
                end
            end
            
            cevent_final = cevent_remove_small_segments(new_cev, min_duration);
            
            % record both cevent and cstream
            record_variable(subs(s), output_name{v}, cevent_final);
            if record_cstream
                timebase = make_time_base(subs(s));
                cst = cevent2cstream_v2(cevent_final, [], [], timebase);
                record_variable(subs(s), strrep(output_name{v}, 'cevent', 'cstream'), cst);
            end
        catch ME
            exceptions(e,1:3) = {subs(s), variable_name{v}, ME.message};
            e = e + 1;
        end
    end
end
if isempty(exceptions)
    exceptions = 'No exceptions';
end
end