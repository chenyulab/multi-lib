%%
% Author: Jane Yang
% Last modified: 1/23/2024
% This demo function presents different cases on how to use the
% query_csv_speech/cevent function to generate a csv file containing
% instances when a (speech) keyword OR a (event) target ROI happened.
%
% Input: Name                       Description
%        option                     number of demo case to try
% Example function call: demo_query_csv_speech_or_event(1)

function demo_query_csv_speech_or_event(option)
    switch option
        case 1
            expIDs = 12;
            word_list = {'babyname'};
            output_dir = 'M:\event_clips\test';
            output_filename = 'test-babyname.csv';
            
            % this case finds all speech utterances in exp12 where the
            % keyword "babyname" appeared in the utterance
            % output csv file contains timestamps (raw speech transcription
            % time, system time, and frame) information for each instance 
            % found. The file also contains the source camera frame and
            % video path needed for generating video clips for each found
            % instance.
            query_csv_speech(expIDs,word_list,output_dir,output_filename);
        case 2
            expIDs = 12;
            word_list = {'car'};
            output_dir = 'M:\event_clips\test';
            output_filename = 'test-car.csv';

            args.cam = 1; % change source camera to cam01 (kid's view with 
                          % superimposed gaze)

            args.whence = 'start'; % manipulate timestamps based on onset
            args.interval = [0 3]; % set time window to 3 seconds after onset
            
            % this case finds all speech utterances in exp12 where the
            % keyword "car" appeared in the utterance
            query_csv_speech(expIDs,word_list,output_dir,output_filename,args);
        case 3
            expIDs = 12;
            cevent_varname = 'cevent_eye_joint-attend_child-lead-moment_both';
            target_obj_list = 1:24; % all ROIs in exp12

            output_dir = 'M:\event_clips\test';
            output_filename = 'test_clJA_exp12.csv';
            args.cam = 2; % because the event is child-lead joint attention
                          % moments, we set the source camera to be 
                          % parent's view with gaze

            args.whence = 'start'; % manipulate timestamps based on onset
            args.interval = [-3 0]; % set time window to 3 seconds before onset

            % this case finds all instances within 3 seconds before child-lead JA moments
            query_csv_cevent(expIDs,cevent_varname,target_obj_list,output_dir,output_filename,args);
        case 4
            expIDs = 12;
            cevent_varname = 'cevent_eye_joint-attend_parent-lead-moment_both';
            target_obj_list = 1:24; % specify a list of target ROIs that you'd like to query, in this case we are interested in all 24 ROIs in the experiment

            output_dir = 'M:\event_clips\test';
            output_filename = 'test_plJA_exp12.csv';
            args.cam = 1; % because the event is parent-lead joint attention
                          % moments, we set the source camera to be 
                          % child's view with gaze

            args.whence = 'start'; % manipulate timestamps based on onset
            args.interval = [-3 0]; % set time window to 3 seconds before onset

            % this case finds all instances within 3 seconds before child-lead JA moments
            query_csv_cevent(expIDs,cevent_varname,target_obj_list,output_dir,output_filename,args);
        case 5
            expIDs = 12;
            cevent_varname = 'cevent_eye_joint-attend_child-lead-enter-type_both';
            target_obj_list = 4; % one can also just specify one target ROI to query

            output_dir = 'M:\event_clips\test';
            output_filename = 'test_clJA-enter-type_exp12.csv';
            args.cam = 2; % because the event is child-lead joint attention
                          % moments, we set the source camera to be 
                          % parent's view with gaze

            % this case finds all instances within 3 seconds before child-lead JA moments
            query_csv_cevent(expIDs,cevent_varname,target_obj_list,output_dir,output_filename,args);
        case 6
            expIDs = 12;
            word_list = {'cat'};
            output_dir = 'M:\event_clips\test';
            output_filename = 'test-cat.csv';

            args.cam = 1; % change source camera to cam01 (kid's view with 
                          % superimposed gaze)

            args.whence = 'startend'; % manipulate timestamps based on both onset and offset
            args.interval = [-3 0]; % set time window to 3 seconds before onset to the original utterance offset
            
            % this case finds all speech utterances in exp12 where the
            % keyword "cat" appeared in the utterance
            query_csv_speech(expIDs,word_list,output_dir,output_filename,args);
    end
end