%%%
% Author: Jane Yang
% Last Modifier: 3/28/2023
% Demo function of extract_speech_in_situ().
% 
%%%

function demo_extract_speech_in_situ(option)
    switch option
        case 1
            % find speech utterances when roi is focusing on 'car' (obj3)
            expID = 12;
            cevent_var = 'cevent_eye_roi_child';
            category_list = 3;
            target_words = ["car" "vehicle"];
            output_filename = 'exp12_cevent-roi_speech-car-vehicle.csv';
            
            overall_instance = extract_speech_in_situ(expID,cevent_var,category_list,target_words,output_filename);      
        case 2
            % switch timestamps to three seconds before original onset
            expID = 12;
            cevent_var = 'cevent_eye_roi_child';
            category_list = 3;
            target_words = ["car" "vehicle"];
            output_filename = 'exp12_cevent-roi_speech-car-vehicle.csv';
            args.whence = 'onset';
            args.interval = [-3 0];
            % if shifting three seconds after original offset
            % args.whence = 'offset';
            % args.interval = [0 3];
            
            overall_instance = extract_speech_in_situ(expID,cevent_var,category_list,target_words,output_filename,args);
        case 3
            % find frequency of verb-noun combo
            expID = 12;
            cevent_var = 'cevent_eye_roi_child';
            category_list = 3;
            target_words = ["drive" "car"];
            output_filename = 'exp12_cevent-roi_speech-drive-car.csv';
            
            overall_instance = extract_speech_in_situ(expID,cevent_var,category_list,target_words,output_filename);          
        case 4
            % linking the parent's action holding 'knife' to noun 'jelly' in experiment 58
            expID = 58;
            cevent_var = 'cevent_inhand_parent';
            category_list = 4; % parent holding 'knife'
            target_words = ["jelly"];
            output_filename = 'exp58_cevent-parent-inhand-knife_speech-jelly.csv';
            
            overall_instance = extract_speech_in_situ(expID,cevent_var,category_list,target_words,output_filename);
        case 5
            % linking the parent's action holding 'knife' to verb 'spread' in experiment 58
            expID = 58;
            cevent_var = 'cevent_inhand_parent';
            category_list = 4; % parent holding 'knife'
            target_words = ["spread"];
            output_filename = 'exp58_cevent-parent-inhand-knife_speech-spread.csv';
            
            overall_instance = extract_speech_in_situ(expID,cevent_var,category_list,target_words,output_filename);
        case 6
            % linking parent's action holding 'knife' and kid's attention on 'knife' to word 'jelly' in experiment 58
            expID = 58;
            cevent_var = 'cevent_inhand-eye_parent-child';
            category_list = 4; % object 'knife'
            target_words = ["jelly","peanut_butter","bread","cut","spread","scoop"]; % multiple knife related nouns or verbs
            output_filename = 'exp58_cevent-inhand-eye_parent-child-knife_speech-jelly-PB-bread-cut-spread-scoop.csv';
            
            overall_instance = extract_speech_in_situ(expID,cevent_var,category_list,target_words,output_filename);
        case 7
            % linking parent's action holding 'knife' and kid's attention on 'knife' to word 'jelly' in experiment 58
            expID = 58;
            cevent_var = 'cevent_eye_roi_child';
            category_list = 4; % object 'knife'
            target_words = ["jelly","peanut_butter","bread","cut","spread","scoop"]; % multiple knife related nouns or verbs
            output_filename = 'exp58_cevent-eye-roi-child_speech-jelly-PB-bread-cut-spread-scoop.csv';
            
            overall_instance = extract_speech_in_situ(expID,cevent_var,category_list,target_words,output_filename);

    end
end