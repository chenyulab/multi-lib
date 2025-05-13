%%%
% Author: Jingwen Pang
% Last modified: 5/13/2025
%
% This function splits base cevent data based on conditional cevent data.
% The classification is determined as follows:
% 1. Check the onset of each instance in base cevent.
% 2. If a corresponding instance of conditional cevent occurs at the same time with the same category value, 
%    classify the base cevent instance as "cond_cevent-led."
% 3. If no such instance occurs, check whether condtional cevent appears *during* the duration of base cevent 
%    with the same category value. If it does, classify the base cevent instance as "cond_cevent-follow."
% 4. If no instance of conditional cevent occurs during base cevent, classify it as "no-cond_cevent."
%
%   case 1: cond_cevent led
%             [-----base_cevent----]
%       [----cond_cevent----]
%   case 2: cond_cevent follow
%       [----base_cevent----]
%             [-----cond_cevent----]
%   case 3: no cond_cevent
%       [----base_cevent----]
%                                    [--cond_cevent--]
% 
%   input parameters: 
%       - subexpIDs
%       - base_cevent
%       - cond_cevent
%       - cond_cevent_name
%   output:
%       [base_cevent]_[cond_cevent-led]_[agent]
%       [base_cevent]_[cond_cevent-led-lag]_[agent]
%       [base_cevent]_[cond_cevent-follow]_[agent]
%       [base_cevent]_[cond_cevent-follow]_[agent]
%       [base_cevent]_[no-cond_cevent]_[agent]
% 
% see demo_split_cevent_at_onset_by_cevent for example
%%%
function split_cevent_at_onset_by_cevent(subexpIDs,base_cevent,cond_cevent,cond_cevent_name)

    % check the base variable agent
    base_cevent_elements = split(base_cevent,'_');
    if strcmp(base_cevent_elements{end},'child')
        agent = 'child';
        base_cevent_prefix = strjoin(base_cevent_elements(1:end-1),'_');
    elseif strcmp(base_cevent_elements{end},'parent')
        agent = 'parent';
        base_cevent_prefix = strjoin(base_cevent_elements(1:end-1),'_');
    else
        agent = [];
        base_cevent_prefix = base_cevent;
    end

    sub_ids = cIDs(subexpIDs);
    
    for s = 1:length(sub_ids)
    
        sub_id = sub_ids(s);
        
        data_1 = get_variable_by_trial_cat(sub_id,base_cevent);
        data_2 = get_variable_by_trial_cat(sub_id,cond_cevent);
        
        % sort data make sure they are follow the timestamps order
        if ~isempty(data_1) && ~isempty(data_2)
            data_1 = sortrows(data_1,1);
            data_2 = sortrows(data_2,1);
            
            var2_led = [];
            var1_led = [];
            var2_led_lag = [];
            var1_led_lag = [];
            no_var2_led = [];
            
            for i = 1:size(data_1,1)
                instance_1 = data_1(i,:);
                onset_1 = instance_1(1);
                offset_1 = instance_1(2);
                value_1 = instance_1(3);
            
                check_point = 0;
            
                for j = 1:size(data_2,1)
                    instance_2 = data_2(j,:);
                    onset_2 = instance_2(1);
                    offset_2 = instance_2(2);
                    value_2 = instance_2(3);
            
                    % check if the onset of var 1 is in the var 2
                    if onset_1 >= onset_2 && onset_1 <= offset_2 && value_1 == value_2
                        % check if there is lag, if not, record lag and break
                        if onset_1 == onset_2
                            var2_led = [var2_led;instance_1];
                            check_point = 1;
                            break;
                        end
                        if ~isempty(var2_led) % check if it is the first element
                            if var2_led(end,2) > onset_2 && var2_led(end,2) < onset_1 % determine if the previous offset is within the lag 
                                var2_led_lag = [var2_led_lag;var2_led(end,2),onset_1,value_2];
                            elseif var2_led(end,2) <= onset_2
                                var2_led_lag = [var2_led_lag;onset_2,onset_1,value_2];
                            elseif var2_led(end,1) == onset_1 && var2_led(end,2) == offset_1 % for repeated case
                                prev_lag = var2_led_lag(end, :);
                                if prev_lag(2) == onset_1  % check if the previous lag is this repeated one
                                     var2_led_lag = [var2_led_lag; prev_lag];
                                end
                            end

                        else
                            var2_led_lag = [var2_led_lag;onset_2,onset_1,value_2];
                        end
                        var2_led = [var2_led;instance_1];
                        check_point = 1;
                        break;
                    % check if the onset of var 2 is in the var 1
                    elseif onset_2 >= onset_1 && onset_2 <= offset_1 && value_1 == value_2
                        var1_led_lag = [var1_led_lag;onset_1,onset_2,value_1];
                        var1_led = [var1_led;instance_1];
                        check_point = 1;
                        break;
                    end
                end
            
                % if the var 1 is not overlap with var 2, no led
                if check_point == 0
                    no_var2_led = [no_var2_led;instance_1];
                end
            
            end
            
            % Helper for constructing var_name cleanly
            build_var_name = @(prefix, tag, agent) strjoin({char(prefix), char(tag), char(agent)}, '_');
            build_var_name_no_agent = @(prefix, tag) strjoin({char(prefix), char(tag)}, '_');
            
            % cond_cevent led
            tag  = sprintf('%s-led', cond_cevent_name);
            tag_lag = sprintf('%s-lag', tag);
            data = var2_led;
            if isempty(agent)
                var_name = build_var_name_no_agent(base_cevent_prefix, tag);
            else
                var_name = build_var_name(base_cevent_prefix, tag, agent);
            end
            disp(var_name)
            record_additional_variable(sub_id, var_name, data);
            
            data = var2_led_lag;
            if isempty(agent)
                var_name = build_var_name_no_agent(base_cevent_prefix, tag_lag);
            else
                var_name = build_var_name(base_cevent_prefix, tag_lag, agent);
            end
            disp(var_name)
            record_additional_variable(sub_id, var_name, data);
            
            % cond_cevent follow
            tag  = sprintf('%s-follow', cond_cevent_name);
            tag_lag = sprintf('%s-lag', tag);
            data = var1_led;
            if isempty(agent)
                var_name = build_var_name_no_agent(base_cevent_prefix, tag);
            else
                var_name = build_var_name(base_cevent_prefix, tag, agent);
            end
            disp(var_name)
            record_additional_variable(sub_id, var_name, data);
            
            data = var1_led_lag;
            if isempty(agent)
                var_name = build_var_name_no_agent(base_cevent_prefix, tag_lag);
            else
                var_name = build_var_name(base_cevent_prefix, tag_lag, agent);
            end
            disp(var_name)
            record_additional_variable(sub_id, var_name, data);
            
            % no cond_cevent
            tag  = sprintf('no-%s', cond_cevent_name);
            data = no_var2_led;
            if isempty(agent)
                var_name = build_var_name_no_agent(base_cevent_prefix, tag);
            else
                var_name = build_var_name(base_cevent_prefix, tag, agent);
            end
            disp(var_name)
            record_additional_variable(sub_id, var_name, data);
        else
            sprintf('variable data is empty for %d',sub_id)
        end
    end
end