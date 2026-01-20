% Summary:
% This script demonstrates how to process and analyze naming event data in 
% relation to other dependent variables within a 3-second interval following 
% the onset of the naming event.
% 
% Process Overview:
% create_naming_dataset: create naming event data based on specified parameters.
% generate_naming_results: generate results related to the dependent
% variable. Results is grouped into proportion bins.The results will
% include both object level and subject level


function demo_generate_naming_results(option)

switch option

    case 1
        % extract data for all naming events in experiment 12
        exp_list = [12];
        cevent_name = 'cevent_speech_naming_local-id';
        
        num_obj_list = [24];
        flag = 1; 
        output_dir = '../data';
        output_filename = 'all_naming';
        create_naming_dataset(exp_list,cevent_name,num_obj_list,flag,output_dir,output_filename);

        % generate results for the proportion of time the child's gaze is 
        % fixated on the object being named.
        input_filename = 'all_naming_onset_after3_target';
        dep_cevent = 'cevent_eye_roi_child';
        output_dir = '../result';
        generate_naming_results(exp_list, input_filename, dep_cevent, output_dir, output_filename)

    case 2
        % extract data for unknown naming events in experiment 12
        exp_list = [12];
        cevent_name = 'cevent_speech_unknown-words';
        num_obj_list = [24];
        flag = 1;
        output_dir = '../data';
        output_filename = 'unknown_naming';
        create_naming_dataset(exp_list,cevent_name,num_obj_list,flag,output_dir,output_filename);

        % generate results for the proportion of time the child's hand is 
        % on the object being named.
        input_filename = 'unknown_naming_onset_after3_target';
        dep_cevent = 'cevent_inhand_child';
        output_dir = '../result';
        generate_naming_results(exp_list, input_filename, dep_cevent, output_dir, output_filename)

    case 3
        % extract data for all naming events in experiment 12
        exp_list = [351 353];
        cevent_name = 'cevent_speech_naming_local-id';
        num_obj_list = [27 22];
        flag = 2;
        output_dir = '../data';
        output_filename = 'all_naming';
        create_naming_dataset(exp_list,cevent_name,num_obj_list,flag,output_dir,output_filename);
        
        % generate results for the proportion of time the child's gaze is
        % fixated on the object being named.
        input_filename = 'all_naming_onset_after3_target';
        dep_cevent = 'cevent_eye_roi_child';
        output_dir = '../result';
        generate_naming_results(exp_list, input_filename, dep_cevent, output_dir, output_filename)

   case 4
        % extract data for all naming events in experiment 12
        exp_list = [77 78 79 80];
        cevent_name = 'cevent_speech_naming_local-id';
        num_obj_list = [10 10 10 10];
        flag = 1;
        output_dir = '../data';
        output_filename = 'all_naming';
        create_naming_dataset(exp_list,cevent_name,num_obj_list,flag,output_dir,output_filename);
        
        % generate results for the proportion of time the child's gaze is
        % fixated on the object being named.
        input_filename = 'all_naming_onset_after3_target';
        dep_cevent = 'cevent_eye_roi_child';
        output_dir = '../result';
        generate_naming_results(exp_list, input_filename, dep_cevent, output_dir, output_filename)

    case 5
        % extract data for all naming events in experiment 12
        exp_list = [77 78 79 80];
        cevent_name = 'cevent_speech_naming_local-id';
        num_obj_list = [10 10 10 10];
        flag = 2;
        output_dir = '../data';
        output_filename = 'all_naming';
        create_naming_dataset(exp_list,cevent_name,num_obj_list,flag,output_dir,output_filename);
        
        % generate results for the proportion of time the child's gaze is
        % fixated on the object being named.
        input_filename = 'all_naming_onset_after3_target';
        dep_cevent = 'cevent_eye_roi_child';
        output_dir = '../result';
        generate_naming_results(exp_list, input_filename, dep_cevent, output_dir, output_filename)

end