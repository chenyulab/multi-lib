% Summary:
% modified date: 10/06/2024
% This script demonstrates how to process and analyze event data in 
% relation to other dependent variables within a 3-second interval following 
% the onset of the naming event.
% 
% Process Overview:
% create_naming_dataset: create event(might be others) data based on 
% specified parameters. generate_hist_results_target: generate results related to 
% the dependent variable. Results is grouped into proportion bins.The results 
% will include both object level and subject level
% 
% required arguments:
% expIDs
%   - experiment id] 
%   - list of experiment id(not yet)
% 
% num_objs
%   - number of obj 
%   - list of number of obj(not yet)
% 
% input_file_name 
% dep_cevent 
% output_dir
% output_file_name
% 
% 
% 
% optional arguments
% 
% args.num_bin
%   - number of bins
%   - 10 (default)


function demo_generate_hist_results_target(option)

switch option

    case 1
        clear;
        % we want to see the proprotion of time for child roi occur in both known
        % and unknown naming event (define as 3 second period after naming event occcurs).
        % general configration
        exp_id = 12;
        num_obj = 24;
        output_dir = 'M:/extracted_datasets/plot_histogram/data';
        % dependent variable list, give us options we want to look
        dep_var_list = {'cevent_eye_roi_child', 'cevent_eye_roi_parent','cevent_inhand_child', 'cevent_inhand_parent',...
        'cevent_eye_joint-attend_child-lead-moment_both','cevent_eye_joint-attend_parent-lead-moment_both'};

        %% use extract_multi_measures to extract data for unknown naming
        % events in experiment 12 first
        cevent_name = 'cevent_speech_unknown-words';
        output_file_type = 'unknown_naming';
        
        % in this case, extract the moment of 3 seconds after the onset as
        % unknown naming instance
        args.cevent_measures = {'individual_prop_by_cat'};
        args.cevent_name = cevent_name; 
        args.cevent_values = 1:num_obj;
        args.whence = 'start';
        args.interval = [0 3];
        
        % use extract multi measure to extract data for unknown naming events in experiment 12
        % type: target, we want to find the proportion for target object
        type = 'target';
        args.label_matrix = ones(num_obj) * 2 + diag(-ones(num_obj,1));
        args.label_names = {'target', 'other'};
        file_name =fullfile(output_dir, sprintf('%s_onset_after3_%s_exp_%d.csv',output_file_type,type, exp_id));
        extract_multi_measures(dep_var_list, exp_id, file_name, args);

        % generate results for the proportion of time the child's gaze is 
        % fixated on the unknown object being named.
        args.dep_cevents = {'cevent_eye_roi_child','cevent_eye_roi_parent'};
        input_filename = sprintf('%s_onset_after3_%s',output_file_type,type);
        generate_hist_results_target(exp_id, input_filename, output_file_type, args);


        %% for now, let's generate the data for known naming event
        % extract data by extract_multi_measures
        cevent_name = 'cevent_speech_known-words';
        args.cevent_name = cevent_name; 
        output_file_type = 'known_naming';
        output_dir = 'M:/extracted_datasets/naming/example_1/data';
        file_name =fullfile(output_dir, sprintf('%s_onset_after3_%s_exp%d.csv',output_file_type,type, exp_id));
        % other cinfigration are the same as unknown one
        extract_multi_measures(dep_var_list, exp_id, file_name, args);
        generate_hist_results_target(exp_id, input_filename, output_file_type, args);

    case 2
        clear;
        % we want to see the proprotion of time for child roi occur in all naming event 
        % (define as 3 second period after naming event occcurs) for PIE.
        % general configration
        exp_ids = [77:79];
        num_objs = get_num_obj(exp_ids);
        output_dir = 'M:/extracted_datasets/plot_histogram/data';
        % dependent variable list, give us options we want to look
        dep_var_list = {'cevent_eye_roi_child', 'cevent_eye_roi_parent','cevent_inhand_child', 'cevent_inhand_parent',...
        'cevent_eye_joint-attend_child-lead-moment_both','cevent_eye_joint-attend_parent-lead-moment_both'};

        for e = 1:length(exp_ids)
            exp_id = exp_ids(e);
            num_obj = num_objs(e);
            %% use extract_multi_measures to extract data for unknown naming
            % events in experiment 12 first
            cevent_name = 'cevent_speech_naming_local-id';
            output_file_type = 'all_naming';
            
            % in this case, extract the moment of 3 seconds after the onset as
            % unknown naming instance
            args.cevent_measures = {'individual_prop_by_cat'};
            args.cevent_name = cevent_name; 
            args.cevent_values = 1:num_obj;
            args.whence = 'start';
            args.interval = [0 3];
            
            % use extract multi measure to extract data for unknown naming
            % events in experiment 77 -79
            % type: target, we want to find the proportion for target object
            type = 'target';
            args.label_matrix = ones(num_obj) * 2 + diag(-ones(num_obj,1));
            args.label_names = {'target', 'other'};
            file_name =fullfile(output_dir, sprintf('%s_onset_after3_%s_exp_%d.csv',output_file_type,type, exp_id));
            extract_multi_measures(dep_var_list, exp_id, file_name, args);
        end

        % generate results for the proportion of time the child's gaze is 
        % fixated on the unknown object being named.
        input_filename = sprintf('%s_onset_after3_%s',output_file_type,type);
        generate_hist_results_target(exp_id, input_filename, output_file_type, args);

end