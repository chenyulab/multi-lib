%%%
% Author: Jingwen Pang
% Last modifier: 2/19/2023
% Description:
%       This function generate eye-no-inhand, inhand-eye, inhand-no-eye
%       variables. 
%
%       Eye-no-inhand is the eye roi excluding the moment when the roi 
%       object is in hand. Those variables are derived from cstream_eye_roi &
%       cstream_inhand-eye_agent_agent.
%
%       Inhand-eye is the condition when using either one hand or two hands
%       to hold either one object or two objects, and relation with eye roi. 
%       There are 6 condtions for it:
%           - one hand holds one object, looking at it
%           - one hand holds one object, not looking at it
%           - two hand hold one object, looking at it
%           - two hand hold one object, not looking at it
%           - two hand hold two objects, looking at one of two
%           - two hand hold two objects, looking at neither of two
%       Those variables are derived from cstream_eye_roi, cstream_left-hand_obj-all,
%       cstream_right-hand_obj-all
%
%       Inhand-no-eye condition is when holding objects but eye is not
%       looking that object. Those variables are derived from the 3 eye off
%       condition when holding objects.
%       
% Input:
%       subexpIDs: exp id or subject id list
% Output: 
%       cstream/cevent eye no inhand variables
%           - 'cevent/cstream_eye_roi_no-inhand_agent'
%       cstream/cevent inhand eye variables
%           - 'cevent_inhand-eye_type_agent-agent'
%           - 'cevent/cstream_inhand-eye_1hand1obj_eye-on_agent-agent'
%           - 'cevent/cstream_inhand-eye_1hand1obj_eye-off_agent-agent'
%           - 'cevent/cstream_inhand-eye_2hand1obj_eye-on_agent-agent'
%           - 'cevent/cstream_inhand-eye_2hand1obj_eye-off_agent-agent'
%           - 'cevent/cstream_inhand-eye_2hand2obj_eye-on_target_agent-agent'
%           - 'cevent/cstream_inhand-eye_2hand2obj_eye-on_other_agent-agent'
%           - 'cevent/cstream_inhand-eye_2hand2obj_eye-off_agent-agent'
%       cevent inhand no eye variables  
%           - 'cevent_inhand_no-eye_agent'
% 
% Example calling: master_make_all_inhand_variables(1201)
%%%

function make_all_inhand_eye(subexpIDs)

    %% generate eye no inhand variables
    for flag = 1:2
        
        % 1 for child, 2 for parent
        if flag == 1
            agent = 'child';
        elseif flag == 2
            agent = 'parent';
        end
    
        % record cstream eye no inhand variables
        eye_only = sprintf('cstream_eye_roi_no-inhand_%s', agent);
        
        sub_list = cIDs(subexpIDs);
        
        for i = 1:numel(sub_list)
            subjectID = sub_list(i);
            
            try
                % if eye value & inhand-eye value are the same, set to 0,
                % keep other eye roi values.
                eye_roi = get_variable(subjectID, sprintf('cstream_eye_roi_%s', agent));
                inhand_eye = get_variable(subjectID,sprintf('cstream_inhand-eye_%s-%s', agent, agent));
                eye_roi(:,1) = round(eye_roi(:,1),4);
                inhand_eye(:,1) = round(inhand_eye(:,1),4);
                sdata = [];
                for j = 1:size(eye_roi,1)
                    matchRow = find(inhand_eye(:,1) == eye_roi(j,1));
                
                    if ~isempty(matchRow)
                        if eye_roi(j,2) == inhand_eye(matchRow,2)
                            value = 0;
                        else
                            value = eye_roi(j,2);
                        end
                        sdata = [sdata; eye_roi(j,1), value];
                    end
                end
                record_additional_variable(subjectID, eye_only, sdata);
    
            catch ME
                fprintf('%d: %s\n', subjectID, ME.message);
        
            end   
        end
    
        % record cevent eye no inhand variables
    
        eye_only = sprintf('cevent_eye_roi_no-inhand_%s', agent);
        
        sub_list = cIDs(subexpIDs);
        
        for i = 1:numel(sub_list)
            subjectID = sub_list(i);
            
            try
                cstream_value = get_variable(subjectID,sprintf('cstream_eye_roi_no-inhand_%s', agent));
                sdata = cstream2cevent(cstream_value); 
                record_additional_variable(subjectID, eye_only, sdata);
            catch ME
                fprintf('%d: %s\n', subjectID, ME.message);
        
            end   
        end
    end

    
    %% make inhand eye variables
    for flag = 1:4
        if flag == 1
            eye_agent = 'child';
            hand_agent = 'child';
        elseif flag == 2
            eye_agent = 'parent';
            hand_agent = 'parent';
        elseif flag == 3
            eye_agent = 'child';
            hand_agent = 'parent';
        elseif flag == 4
            eye_agent = 'parent';
            hand_agent = 'child';        
        end

        % generate cstream inhand-eye variables
        var_list = {'1hand1obj_eye-on','1hand1obj_eye-off',...
            '2hand1obj_eye-on','2hand1obj_eye-off',...
            '2hand2obj_eye-on_target','2hand2obj_eye-on_other',...
            '2hand2obj_eye-off_left','2hand2obj_eye-off_right',...
            'type'};
    
        var_label_list = {'OneHandOneObj_eyeOn','OneHandOneObj_eyeOff',...
            'TwoHandOneObj_eyeOn','TwoHandOneObj_eyeOff',...
            'TwoHandTwoObj_eyeOn_target','TwoHandTwoObj_eyeOn_other',...
            'TwoHandTwoObj_eyeOff_left','TwoHandTwoObj_eyeOff_right',...
            'type'};
       
        sub_list = cIDs(subexpIDs);
        
        for i = 1:numel(sub_list)
            subjectID = sub_list(i);
            
            try
                % get inhand and eye variables
                right_inhand = get_variable(subjectID, sprintf('cstream_inhand_right-hand_obj-all_%s', hand_agent));
                left_inhand = get_variable(subjectID, sprintf('cstream_inhand_left-hand_obj-all_%s', hand_agent));
                eye_roi = get_variable(subjectID, sprintf('cstream_eye_roi_%s', eye_agent));
                eye_only = get_variable(subjectID, sprintf('cstream_eye_roi_no-inhand_%s', eye_agent));
                
                % rounding to prevent error
                right_inhand(:,1) = round(right_inhand(:,1),4);
                left_inhand(:,1) = round(left_inhand(:,1),4);
                eye_roi(:,1) = round(eye_roi(:,1),4);
                eye_only(:,1) = round(eye_only(:,1),4);
    
                % Extract unique keys from the first column of eye_roi, left_inhand, and right_inhand eye_only
                keys = unique([eye_roi(:,1); left_inhand(:,1); right_inhand(:,1); eye_only(:,1)]);
                
                % Initialize the full_data matrix with zeros
                full_data = zeros(length(keys), 5);  % 5 columns: key, eye_roi, left_inhand, right_inhand eye_only
                
                % Fill the full_data matrix
                for j = 1:length(keys)
                    key = keys(j);
                    full_data(j, 1) = key;
                    % Find and fill from eye_roi
                    idx_eye_roi = find(eye_roi(:,1) == key);
                    if ~isempty(idx_eye_roi)
                        full_data(j, 2) = eye_roi(idx_eye_roi, 2);
                    end
                    
                    % Find and fill from left_inhand
                    idx_left_inhand = find(left_inhand(:,1) == key);
                    if ~isempty(idx_left_inhand)
                        full_data(j, 3) = left_inhand(idx_left_inhand, 2);
                    end
                
                    % Find and fill from right_inhand
                    idx_right_inhand = find(right_inhand(:,1) == key);
                    if ~isempty(idx_right_inhand)
                        full_data(j, 4) = right_inhand(idx_right_inhand, 2);
                    end
                
                    % Find and fill from eye_only
                    idx_eye_only = find(eye_only(:,1) == key);
                    if ~isempty(idx_eye_only)
                        full_data(j, 5) = eye_only(idx_eye_only, 2);
                    end
                
                end            
                variable_matrices = struct();
    
                % create empty matrics for each variable
                for j = 1:length(var_label_list)
                    name = var_label_list{j};
                    variable_matrices.(name) = [];
                end
    
                for j = 1:size(full_data, 1)
                    time = full_data(j,1);
                    eye = full_data(j,2);
                    left = full_data(j,3);
                    right = full_data(j,4);
                    eye_no_inhand = full_data(j,5);
    
                    % 2 hand 1 object condition
                    if left == right && (left ~= 0 && ~isnan(left))
                        % eye on
                        if eye == left
                            variable_matrices.TwoHandOneObj_eyeOn = [variable_matrices.TwoHandOneObj_eyeOn; time, left];
                            variable_matrices.type = [variable_matrices.type; time, 4];
                        % eye off
                        else
                            variable_matrices.TwoHandOneObj_eyeOff = [variable_matrices.TwoHandOneObj_eyeOff; time, left];
                            variable_matrices.type = [variable_matrices.type; time, 5];
                        end
                    % 2 hand 2 object condition
                    elseif left ~= right && (left ~= 0 && ~isnan(left)) && (right ~= 0 && ~isnan(right))
                        % eye on
                        % target & other obj
                        if eye == left
                            variable_matrices.TwoHandTwoObj_eyeOn_target = [variable_matrices.TwoHandTwoObj_eyeOn_target; time left];
                            variable_matrices.TwoHandTwoObj_eyeOn_other = [variable_matrices.TwoHandTwoObj_eyeOn_other; time, right];
                            variable_matrices.type = [variable_matrices.type; time, 6];
                        elseif eye == right
                            variable_matrices.TwoHandTwoObj_eyeOn_target = [variable_matrices.TwoHandTwoObj_eyeOn_target; time, right];
                            variable_matrices.TwoHandTwoObj_eyeOn_other = [variable_matrices.TwoHandTwoObj_eyeOn_other; time, left];
                            variable_matrices.type = [variable_matrices.type; time, 6];
                        % eye off
                        % left & right obj
                        else
                            variable_matrices.TwoHandTwoObj_eyeOff_left = [variable_matrices.TwoHandTwoObj_eyeOff_left; time, left];
                            variable_matrices.TwoHandTwoObj_eyeOff_right = [variable_matrices.TwoHandTwoObj_eyeOff_right; time, right];
                            variable_matrices.type = [variable_matrices.type; time, 7];
                        end
                    % 1 hand 1 object condition for left hand
                    elseif (left ~= 0 && ~isnan(left)) && (right == 0 || isnan(right))
                        % eye on
                        if eye == left
                            variable_matrices.OneHandOneObj_eyeOn = [variable_matrices.OneHandOneObj_eyeOn; time, left];
                            variable_matrices.type = [variable_matrices.type; time, 2];
                        % eye off
                        else
                            variable_matrices.OneHandOneObj_eyeOff = [variable_matrices.OneHandOneObj_eyeOff; time, left];
                            variable_matrices.type = [variable_matrices.type; time, 3];
                        end
                    % 1 hand 1 object condition for right hand
                    elseif (right ~= 0 && ~isnan(right)) && (left == 0 || isnan(left))
                        % eye on
                        if eye == right
                            variable_matrices.OneHandOneObj_eyeOn = [variable_matrices.OneHandOneObj_eyeOn; time, right];
                            variable_matrices.type = [variable_matrices.type; time, 2];
                        % eye off
                        else
                            variable_matrices.OneHandOneObj_eyeOff = [variable_matrices.OneHandOneObj_eyeOff; time, right];
                            variable_matrices.type = [variable_matrices.type; time, 3];
                        end
                    elseif eye_no_inhand ~= 0 && ~isnan(eye_no_inhand)
                        variable_matrices.type = [variable_matrices.type; time, 1];
                    end
    
                    % insert the gap for each matrices
                    for k = 1: length(var_label_list)
                        tolerance = 1e-6; % Set a small tolerance value
                        if isempty(variable_matrices.(var_label_list{k}))
                            variable_matrices.(var_label_list{k}) = [variable_matrices.(var_label_list{k}); time, 0];
                        elseif abs(variable_matrices.(var_label_list{k})(end,1) - full_data(j,1)) > tolerance
                            variable_matrices.(var_label_list{k}) = [variable_matrices.(var_label_list{k}); time, 0];
                        end
                    end
                end
                % record variables
                for j = 1:length(var_label_list)
                    type = var_list{j};
                    type_label = var_label_list{j};
                    var_name = sprintf('cstream_inhand-eye_%s_%s-%s',type,hand_agent,eye_agent);
                    sdata = variable_matrices.(type_label);
                    record_additional_variable(subjectID, var_name,sdata);
                    variable_matrices.(type_label) = [];
                end
    
            catch ME
                fprintf('%d: %s\n', subjectID, ME.message);
        
            end
            
        end
    
        % generate cevent inhand-eye variables
        var_list = {'1hand1obj_eye-on','1hand1obj_eye-off',...
                '2hand1obj_eye-on','2hand1obj_eye-off',...
                '2hand2obj_eye-on_target','2hand2obj_eye-on_other',...
                '2hand2obj_eye-off_left','2hand2obj_eye-off_right',...
                'type'};
        var_label_list = {'OneHandOneObj_eyeOn','OneHandOneObj_eyeOff',...
                'TwoHandOneObj_eyeOn','TwoHandOneObj_eyeOff',...
                'TwoHandTwoObj_eyeOn_target','TwoHandTwoObj_eyeOn_other',...
                'TwoHandTwoObj_eyeOff_left','TwoHandTwoObj_eyeOff_right',...
                'type'};
      
        sub_list = cIDs(subexpIDs);
        
        for i = 1:numel(sub_list)
            subjectID = sub_list(i);
                
            try
                cevent_matrices = struct();
                
                % get all cstream variables and convert to cevent
                for j = 1:length(var_list)
                    cstream_var_name = sprintf('cstream_inhand-eye_%s_%s-%s',var_list{j},hand_agent,eye_agent);
                    cstream_var_data = get_variable(subjectID, cstream_var_name);
                    cevent_var_data = cstream2cevent(cstream_var_data);
                    cevent_matrices.(var_label_list{j}) = cevent_var_data;
                end
                
                % generate all inhand sub variables
                for j = 1:6
                    cevent_var_name = sprintf('cevent_inhand-eye_%s_%s-%s',var_list{j},hand_agent,eye_agent);
                    sdata = cevent_matrices.(var_label_list{j});
                    record_additional_variable(subjectID, cevent_var_name,sdata);
                    cevent_matrices.(var_label_list{j}) = [];
                end
                
                % merge eye off right & left into one variable
                TwoHandTwoObj_eyeOff = [cevent_matrices.TwoHandTwoObj_eyeOff_left; cevent_matrices.TwoHandTwoObj_eyeOff_right];
                [~, sortIdx] = sort(TwoHandTwoObj_eyeOff);
                sdata = TwoHandTwoObj_eyeOff(sortIdx, :);
                TwoHandTwoObj_eyeOff_name = sprintf('cevent_inhand-eye_2hand2obj_eye-off_%s-%s',hand_agent,eye_agent);
                record_additional_variable(subjectID, TwoHandTwoObj_eyeOff_name,sdata)
                cevent_matrices.(var_label_list{7}) = [];
                cevent_matrices.(var_label_list{8}) = [];
    
    
                cevent_var_name = sprintf('cevent_inhand-eye_%s_%s-%s',var_list{9},hand_agent,eye_agent);
                sdata = cevent_matrices.(var_label_list{9});
                record_additional_variable(subjectID, cevent_var_name,sdata);
                cevent_matrices.(var_label_list{9}) = [];
        
            catch ME
                    fprintf('%d: %s\n', subjectID, ME.message);
            
            end
                
        end
    end
    
    %% make cevent inhand no eye variables
    for flag = 1:2
        % 1 for child, 2 for parent
        if flag == 1
            agent = 'child';
        elseif flag == 2
            agent = 'parent';
        end
    
        sub_list = cIDs(subexpIDs);
    
        for i = 1:numel(sub_list)
            subjectID = sub_list(i);
    
            try
                eye_off_1 = get_variable(subjectID,sprintf('cevent_inhand-eye_1hand1obj_eye-off_%s-%s',agent,agent));
                eye_off_2 = get_variable(subjectID,sprintf('cevent_inhand-eye_2hand1obj_eye-off_%s-%s',agent,agent));
                eye_off_3 = get_variable(subjectID,sprintf('cevent_inhand-eye_2hand2obj_eye-off_%s-%s',agent,agent));
                
                inhand_no_eye = [eye_off_1;eye_off_2;eye_off_3];
                [~, sortIdx] = sort(inhand_no_eye);
                sdata = inhand_no_eye(sortIdx,:);
                var_name = sprintf('cevent_inhand_no-eye_%s',agent);
                record_additional_variable(subjectID,var_name,sdata);

                % record the cstream variables to make sure they have the
                % same timestamps
                timing = get_trial_times(subjectID);
                start_time = timing(1,1);
                end_time = timing(end,2);
                rate = 1/30;
                cstream_1 = cevent2cstream(eye_off_1,start_time,rate,0,end_time);
                cstream_2 = cevent2cstream(eye_off_2,start_time,rate,0,end_time);
                cstream_3 = cevent2cstream(eye_off_3,start_time,rate,0,end_time);

                record_additional_variable(subjectID,sprintf('cstream_inhand-eye_1hand1obj_eye-off_%s-%s',agent,agent),cstream_1)
                record_additional_variable(subjectID,sprintf('cstream_inhand-eye_2hand1obj_eye-off_%s-%s',agent,agent),cstream_2)
                record_additional_variable(subjectID,sprintf('cstream_inhand-eye_2hand2obj_eye-off_%s-%s',agent,agent),cstream_3)
    
            catch ME
                fprintf('%d: %s\n', subjectID, ME.message);
        
            end   
    
        end 
    end

end