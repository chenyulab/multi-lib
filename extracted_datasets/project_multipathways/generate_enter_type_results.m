function rtr = generate_enter_type_results(expIDs,JA_enter_type)
    for idx = 1:length(expIDs)
        expID = expIDs(idx);
        % a list of possible JA enter type variables
        JA_enter_type_varname = {'cevent_eye_joint-attend_child-lead-enter-type_both','cevent_eye_joint-attend_parent-lead-enter-type_both'};
        JA_varname = {'cevent_eye_joint-attend_child-lead-moment_both','cevent_eye_joint-attend_parent-lead-moment_both'};
    
    
        % get a list of subjects in this experiment
        subs = find_subjects(JA_enter_type_varname,expID);
    
        enter_type_prop = zeros(length(subs),length(JA_enter_type)*2);
        num_JA_instances = zeros(length(subs),2);
        trial_dur = zeros(length(subs),1);

    
    
    
        % iterate through each subject in the experiment
        for i = 1:length(subs)
            % get subject's trial time
            trial_time = get_trial_times(subs(i));
            trial_dur(i) = sum(trial_time(:,2)-trial_time(:,1));
            % iterate through JA enter type variable,
            for j = 1:length(JA_enter_type_varname)
                % find instances for each enter type
                JA_enter_var = get_variable(subs(i),JA_enter_type_varname{j});
    
                % % find the number of JA instances
                % JA_var = get_variable(subs(i),JA_varname{j});
                % sub_info = get_subject_info(subs(i));
                % 
                % % filter out instances where JA is on face or non-target
                % % (rare case)
                % if ~ismember(sub_info(2),[351 353])
                %     JA_var = JA_var(JA_var(:,3)~=25 & JA_var(:,3)~=0,:);
                % else
                %     JA_var = JA_var(JA_var(:,3)~=1 & JA_var(:,3)~=0,:);
                % end

                % find the number of JA instances
                num_JA_instances(i,j) = size(JA_enter_var,1);
                % disp(i);
                % disp(subs(i));
                % disp(size(event));
    
                % split instances by enter type value
                for k = 1:length(JA_enter_type)
                    enter_type_prop(i,(j-1)*length(JA_enter_type)+k) = sum(JA_enter_var(:,3) == JA_enter_type(k))/num_JA_instances(i,j);
                end
            end
        end
        
        % append subID, number of JA instances, and JA enter type ratio
        disp(size(subs));
        disp(size(trial_dur'));
        disp(size(num_JA_instances));
        disp(size(enter_type_prop));
        rtr = horzcat(subs,trial_dur,num_JA_instances(:,1),enter_type_prop(:,1:length(JA_enter_type)),num_JA_instances(:,2),enter_type_prop(:,length(JA_enter_type)+1:end));
    
        % save to csv
        colNames = {'subID','total session time',...
                    'num_child-led_JA','JA_child-lead_enter-type-1','JA_child-lead_enter-type-2','JA_child-lead_enter-type-3','JA_child-lead_enter-type-4','JA_child-lead_enter-type-5','JA_child-lead_enter-type-6',...
                    'num_parent-led_JA','JA_parent-lead_enter-type-1','JA_parent-lead_enter-type-2','JA_parent-lead_enter-type-3','JA_parent-lead_enter-type-4','JA_parent-lead_enter-type-5','JA_parent-lead_enter-type-6'};
%         colNames = {'subID','total session time',...
%                     'num_child-led_JA','JA_child-lead_enter-type-others','JA_child-lead_enter-type-gaze','JA_child-lead_enter-type-hand','JA_child-lead_enter-type-self-hand',...
%                     'num_parent-led_JA','JA_parent-lead_enter-type-others','JA_parent-lead_enter-type-gaze','JA_parent-lead_enter-type-hand','JA_parent-lead_enter-type-self-hand'};

        % rtr_table = array2table(rtr,'VariableNames',colNames);
        % writetable(rtr_table,output_filename);
        csvwrite(fullfile('M:\extracted_datasets\project_multipathways\result\6_categories',sprintf('JA-enter-type_results_exp%d.csv',expID)), rtr); 
    end

end
