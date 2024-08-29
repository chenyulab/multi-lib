%%%
% Original author: Dr. Chen Yu
% Modifier: Jingwen Pang
% Last modified: 08/29/2024
% This function generates cstream/cevent_eye-joint_child/parent-lead-enter-type_both 
% variables for each subject in the input experiments.
%
% Input: exp_ids    - a list of expIDs
%        JA_types   - a list of joint attention type 
%                      1: child-lead JA , 2: parent-lead JA
%        inhand_pot - proportion of inhand cutoff threshold to filter data, i.e. 0%/50%
%
% Output: cstream/cevent_eye-joint_child/parent-lead-enter-type_both
% variables for each subject in the input experiments.
%
% Sample function call: make_JA_enter_type_v2([12 15 27 49 58 59 71 72 73 74 75 91 351 353], [1 2], 0)
%%%{

function make_JA_enter_type(exp_ids, JA_types, inhand_prop)
    % iterate through experiment
    for idx = 1:length(exp_ids)
        exp_id = exp_ids(idx);
        subj_list = cIDs(exp_id);
    
        for j = 1:length(JA_types)
            JA_type = JA_types(j);

            % hard-coded column index of data representation files
            if JA_type == 1
                face_col = 6;
                inhand_leader_target_col = 3;
                inhand_follower_target_col = 4;
                inhand_follower_other_col = 10;
                inhand_leader_other_col = 9;
                JA_name = 'child';
            else
                face_col = 5;
                inhand_leader_target_col = 4;
                inhand_follower_target_col = 3;
                inhand_follower_other_col = 9;
                inhand_leader_other_col = 10;
                JA_name = 'parent';
            end
    
            % load intermediate data representations - event & behavior
            % cell arrays
            file_name = sprintf('M:/extracted_datasets/multipathways/data/JA_%s-lead_before_exp%d.mat',JA_name, exp_id);
    
            output_cevent_name = sprintf('cevent_eye_joint-attend_%s-lead-enter-type_both',JA_name);
            output_cstream_name = sprintf('cstream_eye_joint-attend_%s-lead-enter-type_both',JA_name);

            % JA variables
            JA_cevent_name = sprintf('cevent_eye_joint-attend_%s-lead_both',JA_name);

    
            load(file_name);
            %data = vertcat(behavior{:});
    
            % iterate through each subject
            for i = 1 : length(event)
                % get subject level behavoir measures
                data = behavior{i};
                JA_follow_type{i} = zeros(1,size(data,1))+1; % default type is 1 - other JA enter type
    
                % filter data for each type of JA enter type
                % gaze following
                index_face = find(data(:,face_col)>0);
                JA_follow_type{i}(index_face) = 2;
                index_face_leader_hand = intersect(find(data(:,inhand_leader_target_col)>inhand_prop), find(data(:,face_col)>0));
                JA_follow_type{i}(index_face_leader_hand) = 3;
                index_rest = setxor(index_face_leader_hand, index_face); 
                %index_face_follower_hand = intersect(find(data(index_rest,inhand_follower_target_col)>inhand_prop),find(data(index_rest,face_col)>0));
                index_face_follower_hand = find(data(index_rest,inhand_follower_target_col)>inhand_prop); 
                JA_follow_type{i}(index_rest(index_face_follower_hand)) = 4;
                %index_rest = setxor(index_face_follower_hand, index_rest);

                % hand following
                index_rest = setxor(1:size(data,1), index_face);
%                 index_inhand = intersect(find(data(index_rest,inhand_leader_target_col)>inhand_prop),find(data(index_rest,inhand_leader_target_col)>=data(index_rest,inhand_leader_other_col)));
                index_inhand = find(data(index_rest,inhand_leader_target_col)>inhand_prop);
                JA_follow_type{i}(index_rest(index_inhand)) = 5;
    
                % hand following self
                index_rest = find(JA_follow_type{i}==1);
%                 index_inhand_self = intersect(find(data(index_rest,inhand_follower_target_col)>inhand_prop),find(data(index_rest,inhand_follower_target_col)>=data(index_rest,inhand_follower_other_col)));
                index_inhand_self = find(data(index_rest,inhand_follower_target_col)>inhand_prop);
                JA_follow_type{i}(index_rest(index_inhand_self)) = 6;

                % filter data for each type of JA enter type
                % % gaze following w/ hand on target
                % index_face = find(data(:,face_col));
                % index_face_hand_target = find(data(index_face,inhand_leader_target_col) > data(index_face,inhand_leader_other_col)); %% TODO: question - what happen if both target and other objects are inhand???
                % JA_follow_type{i}(index_face(index_face_hand_target)) = 2;
                % 
                % % gaze following w/ hand on others
                % index_rest = setxor(index_face, index_face(index_face_hand_target));
                % index_face_hand_other = find(data(index_rest,inhand_leader_other_col) > 0);
                % JA_follow_type{i}(index_rest(index_face_hand_other)) = 3;
                % 
                % % gaze following w/o hand
                % index_rest = setxor(index_face, vertcat(index_face(index_face_hand_target),index_rest(index_face_hand_other)));
                % index_face_no_hand = find(data(index_rest,inhand_leader_target_col)==0 & data(index_rest,inhand_leader_other_col)==0);
                % JA_follow_type{i}(index_rest(index_face_no_hand)) = 4;

                %%% SIX ENTER TYPE ATTEMPT BY JANE
                % % get subject level behavoir measures
                % data = behavior{i};
                % JA_follow_type{i} = zeros(1,size(data,1))+1; % default type is 1 - other JA enter type
                % 
                % % filter data for each type of JA enter type
                % % gaze following w/ hand on target
                % index_face = find(data(:,face_col));
                % index_face_hand_target = find(data(index_face,inhand_leader_target_col) > data(index_face,inhand_leader_other_col)); %% TODO: question - what happen if both target and other objects are inhand???
                % JA_follow_type{i}(index_face(index_face_hand_target)) = 2;
                % 
                % % gaze following w/ hand on others
                % index_rest = setxor(index_face, index_face(index_face_hand_target));
                % index_face_hand_other = find(data(index_rest,inhand_leader_other_col) > 0);
                % JA_follow_type{i}(index_rest(index_face_hand_other)) = 3;
                % 
                % % gaze following w/o hand
                % index_rest = setxor(index_face, vertcat(index_face(index_face_hand_target),index_rest(index_face_hand_other)));
                % index_face_no_hand = find(data(index_rest,inhand_leader_target_col)==0 & data(index_rest,inhand_leader_other_col)==0);
                % JA_follow_type{i}(index_rest(index_face_no_hand)) = 4;
                % 
                % 
                % % hand following
                % %% version 1 - rule: target inhand > 0
                % % index_rest = setxor(1:size(data,1), index_face);
                % % index_inhand = find(data(index_rest,inhand_leader_target_col)>inhand_pot);
                % % JA_follow_type{i}(index_rest(index_inhand)) = 3;
                % %% version 2 - rule: target > distractor
                % index_rest = setxor(1:size(data,1), index_face);
                % index_inhand = find(data(index_rest,inhand_leader_target_col) > data(index_rest,inhand_leader_other_col));
                % JA_follow_type{i}(index_rest(index_inhand)) = 5;
                % 
                % % hand following self
                % %% version 1 - rule: target inhand > 0
                % % index_rest = find(JA_follow_type{i}==1);
                % % index_inhand_self = find(data(index_rest,inhand_follower_target_col) > inhand_pot);
                % % JA_follow_type{i}(index_rest(index_inhand_self)) = 6;
                % %% version 2 - rule: target > distractor
                % index_rest = find(JA_follow_type{i}==1);
                % index_inhand_self = find(data(index_rest,inhand_follower_target_col) > data(index_rest,inhand_follower_other_col));
                % JA_follow_type{i}(index_rest(index_inhand_self)) = 6;
    
                % record new variables
                if isempty(event{i})
                    sub = subj_list(i);
                    % if there is no event but has JA variable, set a place
                    % holder to avoid misalignment
                    if has_variable(sub,JA_cevent_name)
                        empty_place_holder = zeros(0, 3);
                        record_additional_variable(sub,output_cevent_name, empty_place_holder);
                        timebase = get_variable(sub, 'cstream_trials');
                        cstream_data = cevent2cstreamtb(empty_place_holder, timebase);
                        record_additional_variable(sub,output_cstream_name, cstream_data);
                    end
                elseif ~isempty(JA_follow_type{i})
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

