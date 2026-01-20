%%%
% This demo function demos master_make_speech_naming_expanded() and
% master_make_naming_pairs_files()
%
% master_make_speech_naming_expanded() 
%           -- generates 'cevent_speech_naming_local-id_expanded' variable 
%              based on 'cevent_speech_naming_local-id'
% master_make_naming_pairs_files()
%           -- This master function calls get_first_forward_pairs() and
%              get_backward_naming_pairs() to get the first forward and
%              backward pairing instances of expanded naming variable and paired_var.
%%%
function demo_speech_contingency_functions(option)
    switch option
        case 1 
            % generate 'cevent_speech_naming_local-id_expanded' variable based
            % on 'cevent_speech_naming_local-id'
            expIDs = [12 15 27 49];
            base_varname = 'cevent_speech_naming_local-id';
            output_varname = 'cevent_speech_naming_local-id_expanded';
            master_make_cevent_expanded(expIDs,base_varname,output_varname);
            % get the first forward and backward pairing instances of expanded 
            % naming variable and cevent_eye_roi_child.
            num_obj_list = [24 10 24 3];
            output_dir = 'M:/extracted_datasets/project_contingency/data';
            master_make_naming_pairs_files(expIDs, num_obj_list,'cevent_speech_naming_local-id','cevent_eye_roi_child',output_dir);
         case 2
            % get the first forward and backward pairing instances of expanded 
            % naming variable and cevent_eye_roi_child.
            expIDs = [77 78 79 80];
            num_obj_list = [10 10 10 10];
            output_dir = 'M:/extracted_datasets/project_contingency/data';

            base_varname = 'cevent_speech_naming_local-id';
            output_varname = 'cevent_speech_naming_local-id_expanded';
            master_make_cevent_expanded(expIDs,base_varname,output_varname);
            master_make_naming_pairs_files(expIDs,num_obj_list,'cevent_speech_naming_local-id','cevent_eye_roi_child',output_dir);
        case 3
            % get the first forward and backward pairing instances of expanded 
            % naming variable and cevent_eye_roi_child.
            expIDs = [96];
            num_obj_list = [6];
            output_dir = 'M:/extracted_datasets/project_contingency/data';

            base_varname = 'cevent_speech_naming_local-id';
            output_varname = 'cevent_speech_naming_local-id_expanded';
            master_make_cevent_expanded(expIDs,base_varname,output_varname);
            master_make_naming_pairs_files(expIDs,num_obj_list,'cevent_speech_naming_local-id','cevent_inhand-eye_child-child',output_dir);
        case 4
            % get the first forward and backward pairing instances of expanded 
            % naming variable and cevent_eye_roi_child.
            expIDs = [351];
            num_obj_list = [27];
            output_dir = 'M:/extracted_datasets/project_contingency/data';

            base_varname = 'cevent_speech_naming_local-id';
            output_varname = 'cevent_speech_naming_local-id_expanded';
            master_make_cevent_expanded(expIDs,base_varname,output_varname);
            master_make_naming_pairs_files(expIDs,num_obj_list,'cevent_speech_naming_local-id','cevent_eye_roi_child',output_dir);
        case 5
            % get the first forward and backward pairing instances of expanded 
            % naming variable and cevent_eye_roi_child.
            expIDs = [353];
            num_obj_list = [25];
            output_dir = 'M:/extracted_datasets/project_contingency/data';

            base_varname = 'cevent_speech_naming_local-id';
            output_varname = 'cevent_speech_naming_local-id_expanded';
            master_make_cevent_expanded(expIDs,base_varname,output_varname);
            master_make_naming_pairs_files(expIDs,num_obj_list,'cevent_speech_naming_local-id','cevent_eye_roi_child',output_dir);
        case 6
            % get the first forward and backward pairing instances of expanded 
            % naming variable and cevent_eye_roi_child.
            expIDs = [353];
            num_obj_list = [25];
            output_dir = 'M:/extracted_datasets/project_contingency/data';

            base_varname = 'cevent_eye_roi_child';
            output_varname = 'cevent_eye_roi_child_expanded';
            master_make_cevent_expanded(expIDs,base_varname,output_varname);
            master_make_naming_pairs_files(expIDs,num_obj_list,'cevent_speech_naming_local-id','cevent_eye_roi_child',output_dir);
    end
      
end