%%%
% Original author: Dr. Chen Yu
% Modifier: Jane Yang
% Last modified: 10/19/2023
% This function generates cstream/cevent_eye-joint_child/parent-lead-enter-type_both 
% variables for each subject in the input experiments.
%
% Input: exp_ids    - a list of expIDs
%        JA_types   - a list of joint attention type
%        inhand_pot - proportion of inhand cutoff threshold to filter data, i.e. 0%/50%
%
% Output: cstream/cevent_eye-joint_child/parent-lead-enter-type_both
% variables for each subject in the input experiments.
%
% Sample function call: main_multipathways([12 15 27 49 58 59 71 72 73 74 75 351 353], [1 2])
%%%

function main_multipathways(exp_ids, JA_types)
    % iterate through experiment
    for idx = 1:length(exp_ids)
        exp_id = exp_ids(idx);
    
        for j = 1:length(JA_types)
            JA_type = JA_types(j); % 1 - 'child lead JA', 'parent lead JA'

            % hard-coded column index of data representation files
            if JA_type == 1
                face_col = 6;
                inhand_col = 3;
                inhand_self_col = 4;
                inhand_self_other_col = 10;
                inhand_other_col = 9;
                JA_name = 'child';
            else
                face_col = 5;
                inhand_col = 4;
                inhand_self_col = 3;
                inhand_self_other_col = 9;
                inhand_other_col = 10;
                JA_name = 'parent';
            end
    
            % load intermediate data representations - event & behavior
            % cell arrays
            file_name = sprintf('M:/extracted_datasets/project_multipathways/data/JA_%s-lead_before_exp%d.mat',JA_name, exp_id);
    
            output_cevent_name = sprintf('cevent_eye_joint-attend_%s-lead-enter-type_both',JA_name);
            output_cstream_name = sprintf('cstream_eye_joint-attend_%s-lead-enter-type_both',JA_name);
    
            load(file_name);
            %data = vertcat(behavior{:});
    
            % iterate through each subject
            for i = 1 : length(event)
                % get subject level behavoir measures
                data = behavior{i};
                JA_follow_type{i} = zeros(1,size(data,1))+1; % default type is 1 - other JA enter type
    
                % filter data for each type of JA enter type
                % gaze following w/ hand on target
                index_face = find(data(:,face_col));
                index_face_hand_target = find(data(index_face,inhand_col) > data(index_face,inhand_other_col)); %% TODO: question - what happen if both target and other objects are inhand???
                JA_follow_type{i}(index_face(index_face_hand_target)) = 2;

                % gaze following w/ hand on others
                % index_rest = setxor(index_face, index_face(index_face_hand_target));
                index_face_hand_other = find(data(index_face,inhand_other_col) > 0 & data(index_face,inhand_col) > 0);
                JA_follow_type{i}(index_face(index_face_hand_other)) = 3;

                % gaze following w/o hand
                % index_rest = setxor(index_face, vertcat(index_face(index_face_hand_target),index_rest(index_face_hand_other)));
                index_face_no_hand = find(data(index_face,inhand_col)==0 & data(index_face,inhand_other_col)==0);
                JA_follow_type{i}(index_face(index_face_no_hand)) = 4;

    
                % hand following
                %% version 1 - rule: target inhand > 0
                % index_rest = setxor(1:size(data,1), index_face);
                % index_inhand = find(data(index_rest,inhand_col)>inhand_pot);
                % JA_follow_type{i}(index_rest(index_inhand)) = 3;
                %% version 2 - rule: target > distractor
                index_rest = setxor(1:size(data,1), index_face);
                index_inhand = find(data(index_rest,inhand_col) > data(index_rest,inhand_other_col));
                JA_follow_type{i}(index_rest(index_inhand)) = 5;
    
                % hand following self
                %% version 1 - rule: target inhand > 0
                % index_rest = find(JA_follow_type{i}==1);
                % index_inhand_self = find(data(index_rest,inhand_self_col) > inhand_pot);
                % JA_follow_type{i}(index_rest(index_inhand_self)) = 6;
                %% version 2 - rule: target > distractor
                index_rest = find(JA_follow_type{i}==1);
                index_inhand_self = find(data(index_rest,inhand_self_col) > data(index_rest,inhand_self_other_col));
                JA_follow_type{i}(index_rest(index_inhand_self)) = 6;
                
    
                % record new variables
                if ~isempty(JA_follow_type{i})
                    sub = event{i}(1,1);
                    enter_type_data = [event{i}(:,3:4) JA_follow_type{i}'];
                    % record cevent variable
                    record_additional_variable(sub,output_cevent_name, enter_type_data);
                    
                    % convert cevent to cstream and record cstream variable
                    timebase = get_variable(sub, 'cstream_trials');
                    cstream_data = cevent2cstreamtb(enter_type_data, timebase);
                    record_additional_variable(sub,output_cstream_name, cstream_data);
                end
            end
        end
    end
end

