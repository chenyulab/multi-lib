%%%
% Author: Jingwen Pang
% Last modified: 2/20/2024
%
% This function split variable A based on variable B. Take variable A onset
% and determine if variable B occurs, otherwise determine whether variable B 
% occurs during variable A
%
%   case 1: variable B lead
%             [-----var A event----]
%       [----var B event----]
%   case 2: variable A lead
%       [----var A event----]
%             [-----var B event----]
%   case 3: no variable B
%       [----var A event----]
%                                    [--var B event--]
% 
% example call:
%   subexpIDs = 351
%   var_1 = 'cevent_speech_naming_local-id';
%   var_2 = 'cevent_eye_roi_child';
%   type_1 = 'naming';
%   type_2 = 'eye';
%   agent_1 = 'parent';
%   agent_2 = 'child';
%   make_cevent_leading(subexpIDs,var_1,var_2,type_1,type_2,agent_1,agent_2)
%%%
function make_cevent_leading(subexpIDs,var_1,var_2,type_1,type_2,agent_1,agent_2)

    sub_ids = cIDs(subexpIDs);
    
    for s = 1:length(sub_ids)
    
        sub_id = sub_ids(s);
        
        data_1 = get_variable_by_trial_cat(sub_id,var_1);
        data_2 = get_variable_by_trial_cat(sub_id,var_2);
        
        % sort data make sure they are follow the timestamps order
        if ~isempty(data_1) && ~isempty(data_2)
            data_1 = sortrows(data_1,1);
            data_2 = sortrows(data_2,1);
            
            var2_led = [];
            var1_led = [];
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
                        var2_led = [var2_led;instance_1];
                        check_point = 1;
                        break;
                    % check if the onset of var 2 is in the var 1
                    elseif onset_2 >= onset_1 && onset_2 <= offset_1 && value_1 == value_2
                        var1_led = [var1_led;instance_1];
                        check_point = 1;
                        break;
                    end
                end
            
                % if the var 1 is not overlap with var 2, no lead
                if check_point == 0
                    no_var2_led = [no_var2_led;instance_1];
                end
            
            end
            
            % var 2 lead 
            data = var2_led;
            var_name = sprintf('cevent_%s-%s_%s-led_%s-%s',type_1,type_2,type_2,agent_1,agent_2);
            record_additional_variable(sub_id,var_name,data);
            
            % var 1 lead 
            data = var1_led;
            var_name = sprintf('cevent_%s-%s_%s-led_%s-%s',type_1,type_2,type_1,agent_1,agent_2);
            record_additional_variable(sub_id,var_name,data);
            
            % no var 2
            data = no_var2_led;
            var_name = sprintf('cevent_%s-%s_no-%s_%s-%s',type_1,type_2,type_2,agent_1,agent_2);
            record_additional_variable(sub_id,var_name,data);
        else
            sprintf('variable data is empty for %d',sub_id)
        end
    end
end