function make_joint_attention_smart_room(IDs)
subs = cIDs(IDs);

var_list = {'cevent_eye_roi_child','cevent_eye_roi_parent'};
sub_list = subs;

%sub_list = 3401;

%categories = [ 1 2 3];
%sub_list = [2902 2903];
%sub_list = [2903 2908 2909 2911 2912 2913 2918 2921 3201 3202 3204 3207 ...
%            3208 3209]';
%sub_list = [ 3208];
is_io = 1;

%sub_list = 3206


face_roi = 25;
min_dur = 1;
merge_gap_single = 1;
merge_gap_joint = 1;
merge_gap_other_roi = 1;
min_joint_dur = 0.5;

num_timing = 0.2;

for i = 1 : size(sub_list,1)
    sub_list(i)
    if has_all_variables(sub_list(i), var_list)
        chunks{1} = get_variable_by_trial(sub_list(i), var_list{1});
        chunks{2} = get_variable_by_trial(sub_list(i), var_list{2});
        cevent_joint = []; cevent_child_lead = []; cevent_parent_lead = [];
        
        for  m = 1  : size(chunks{1},1)
            
            is_empty = 0;
            % filter and clean each data stream before calculating the joint
            % one
            for j = 1 : 2
                
                cevents = chunks{j}{m};
                new_cevents = cevents;
                for n = 2 : size(cevents,1)-1
                    pre_cevent = cevents(n-1,:);
                    next_cevent = cevents(n+1,:);
                    now_cevent = cevents(n,:);
                    
                    % if a short non-face look between looking at the same ROI
                    % then the short looks will be assigned to that ROI and
                    % merged later
                    if (now_cevent(2) - now_cevent(1)) < min_dur % only target
                        % short ones
                        if (pre_cevent(3) ~= face_roi) && (pre_cevent(3) == next_cevent(3)) &&  (now_cevent(3) ~= pre_cevent(3))
                            % check timing
                            if (next_cevent(1) - pre_cevent(2)) < merge_gap_other_roi
                                new_cevents(n,3) = next_cevent(3);
                            end;
                        end;
                    end;
                    
                    % if it is a short face look between the same pre and after
                    % roi, then that face look is assigned to thte roi
                    if (now_cevent(3) == face_roi)  && (pre_cevent(3) == next_cevent(3)) ...
                            && ((now_cevent(2)-now_cevent(1))<min_dur) && ...
                            ((next_cevent(1) - pre_cevent(2))<min_dur)
                        new_cevents(n,3) = next_cevent(3);
                    end;
                    
                    
                    
                end; % n
                
                if ~isempty(new_cevents)
                    cevent_final{j} = cevent_merge_segments(new_cevents, ...
                        merge_gap_single);
                else
                    is_empty = 1;
                    cevent_joint{m} = [];
                end;
                
            end; % j
            
            if is_empty == 0
                % joint moments
                cevent_joint{m} = cevent_shared(cevent_final{1},cevent_final{2});
                % if two joint events are close enough, merge them into one big
                % one
                if ~isempty(cevent_joint{m})
                    cevent_joint{m} = cevent_merge_segments(cevent_joint{m},merge_gap_joint);
                    
                    
                    % remove short ones;
                    cevent_joint{m} = ...
                        cevent_remove_small_segments(cevent_joint{m},min_joint_dur);
                end
                if ~isempty(cevent_joint{m})
                    % prop of valid data
                    temp = event_AND(cevent_final{1},cevent_final{2});
                    valid_data{i,m} = event_total_length(cevent_joint{m})/ ...
                        event_total_length(temp)
                    
                    %
                    % calculating leading and following
                    %
                    leading =[];
                    leading = zeros(size(cevent_joint{m},1),2);
                    
                    % calculating face looks between leading and following
                    is_look_face = [] ;
                    is_look_face = zeros(size(cevent_joint{m},1),1);
                    
                    
                    % for each joint moment, calculating in both eye roi streams, the
                    % onset of the previous event sharing the same roi
                    % one of the two onsets should share the same/similar value with
                    % the onset of joint event, and the other should be before that.
                    % that is, one starts first, and the other joins in to create a
                    % joint moment
                    for n = 1 : size(cevent_joint{m},1)
                        temp = cevent_before_certain_event(cevent_joint{m}(n,1) + 0.01, ... % +0.01 in case that the timestamp of joint_attention is not identical with the raw roi cevent data - DZ 
                            cevent_joint{m}(n,3),  chunks{1}{m},1);
                        
                        if isempty(temp)
                            temp = -Inf;
                        end
                        
                        leading(n,1) = temp(1);
                        
                        
                        temp = cevent_before_certain_event(cevent_joint{m}(n,1) + 0.01, ... % +0.01 same as above
                            cevent_joint{m}(n,3), ...
                            chunks{2}{m},1);
                        if isempty(temp)
                            temp = -Inf;
                        end
                        
                        leading(n,2) = temp(1);
                        
                        if n>1
                            if  leading(n,1) > leading(n,2)
                                if leading(n,2) < cevent_joint{m}(n-1,2)
                                    leading(n,2) = cevent_joint{m}(n-1,2);
                                    
                                end;
                            else
                                if leading(n,1) < cevent_joint{m}(n-1,2);
                                    leading(n,1) = cevent_joint{m}(n-1,2);
                                end;
                            end;
                        end;
                        
                        %
                        % checking face look
                        % before the onset of joint attention
                        % after leader's initial look that initializes the
                        % episode of joint attention
                        % needed to handle two cases: child following and
                        % parent following
                        % assigning two values in each case: face look or w/o
                        % face look
                        % child following: 10 no face look, 11 face look
                        % parent following: 20 no face look, 21 face look
                        %  the summer of two cases should be the total number
                        %  of child/parent following
                        %
                        if (leading(n,1) - leading(n,2) > 0)
                            
                            % child later, parent first,therefore looking at child
                            temp = extract_ranges(chunks{1}{m},'cevent',[leading(n,1) ...
                                leading(n,2)]);
                            if (isempty(temp)) || (sum(temp{1}(:,3) == face_roi) == 0)
                                is_look_face(n) = 10;  % in case of child
                                % following, no face
                                % look
                            else
                                is_look_face(n) = 11;  % in case of child
                                % following, face look
                                
                            end;
                        else
                            temp = extract_ranges(chunks{2}{m},'cevent',[leading(n,2) ...
                                leading(n,1)]);
                            if (isempty(temp)) || (sum(temp{1}(:,3)==face_roi) == 0)
                                is_look_face(n) = 20; % parent following, no
                                % face look
                            else
                                is_look_face(n) = 21; % parent following,
                                % face look
                            end;
                            
                        end; % if (leading(n,1) - leading(n,2) > 0)
                        
                    end; %n
                end; % if ~empty
            end;     % if empty
            
            if ~isempty(cevent_joint{m})
                timing_all{i}{m}(1,:) = leading(:,1) - leading(:,2);
                look_face_all{i}{m} (1,:)= is_look_face;
                
                %find the gap between leader and follower
                % consider two cases: either child lead or parent lead
                %
                index = find((leading(:,1) - leading(:,2)>0));
                % child later, parent first
                cevent_parent_lead{m}(:,1) = leading(index,2);
                cevent_parent_lead{m}(:,2) = leading(index,1);
                cevent_parent_lead{m}(:,3) = cevent_joint{m}(index,3);
                
                % parent later, child first
                index = find((leading(:,1) - leading(:,2)<0));
                % child later, parent first
                cevent_child_lead{m}(:,1) = leading(index,1);
                cevent_child_lead{m}(:,2) = leading(index,2);
                cevent_child_lead{m}(:,3) = cevent_joint{m}(index,3);
                
                
                for n = 1 : size(cevent_joint{m},1)
                    if ((cevent_joint{m}(n,2) - cevent_joint{m}(n,1)) > ...
                            min_joint_dur) && (cevent_joint{m}(n,3) ~= face_roi)
                        
                    end;
                end; % for
            end;
        end; % m, chunks/trials
        
        
        if is_io == 1
            data = cat(1,cevent_joint{:});
            record_variable(sub_list(i),'cevent_eye_joint-attend_both', data);
            gt = get_timing(sub_list(i));
            cstream = cevent2cstream_v2(data,1/gt.camRate,frame_num2time(gt.trials([1 end]), gt));
            record_variable(sub_list(i),'cstream_eye_joint-attend_both', ...
                cstream);
            
            data = cat(1,cevent_child_lead{:});
            record_variable(sub_list(i),'cevent_eye_joint-attend_child-lead_both', data);
            cstream = cevent2cstream_v2(data, 1/gt.camRate, frame_num2time(gt.trials([1 end]), gt));
            record_variable(sub_list(i), 'cstream_eye_joint-attend_child-lead_both', cstream);
            
            data = cat(1,cevent_parent_lead{:});
            record_variable(sub_list(i),'cevent_eye_joint-attend_parent-lead_both', data);
            cstream = cevent2cstream_v2(data, 1/gt.camRate, frame_num2time(gt.trials([1 end]), gt));
            record_variable(sub_list(i), 'cstream_eye_joint-attend_parent-lead_both', cstream);
            
            make_joint_attention_leading(sub_list(i));
        end;
    end
end; % subject

% if is_io == 1
%     save(sprintf('exp%d_joint_attend_timing.mat',exp_id),'timing_all','look_face_all','sub_list');
% end;
end




