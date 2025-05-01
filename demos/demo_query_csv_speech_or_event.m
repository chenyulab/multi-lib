%%
% Author: Jane Yang
% Modifier: Jingwen Pang
% Last modified: 11/12/2024
% This demo function presents different cases on how to use the
% query_keywords and query_csv_cevent function to generate a csv file containing
% instances when a (speech) keyword OR a (event) target ROI happened.
% 
% All the output files will be saved in event_clips data directory:
%   - M:\extracted_datasets\event_clips\event_data
% 
% query_keywords
% - Given a list of keywords, retrieve all timestamps of speech utterances 
%   containing the keywords
%   
% query_csv_cevent
% - Given a list of category IDs and a cevent variable, retrieve all
%   timestamps of instance of category in that cevent variable
% 
% Output csv columns for both functions:
% - subID                   subject id
% - fileID                  subject folder name
% - onset_system_time       onset time for a cevent instance/utterance
% - onset_frame             onset frame
% - offset_system_time      offset time
% - offset_frame            offset frame
% - catID/word              category id for cevent
%                           keyword for speech utterance
% - source_video_path       path to camera frame folder (default is cam07)
% - source_audio_path       path to the default aduio
% - extract_range_onset     onset of extract range
%%%
function demo_query_csv_speech_or_event(option)
    % this is the demo output directory, if you want to try functions on your own,
    % you can modify this to save your output file into your own place
    output_dir = 'Z:\demo_output_files\query_csv_speech_or_event';
    switch option
        case 1
            % Retrieve all timestamps of speech utterances containing the keyword
            % 'babyname' and save as csv
            expIDs = 12;
            word_list = {'babyname'};
            output_filename = fullfile(output_dir,'exp12_speech_babyname.csv');
            
            query_keywords(expIDs,word_list,output_filename)
        case 2
            % Retrieve all timestamps of speech utterances containing the keyword
            % 'car','truck'
            expIDs = 12;
            word_list = {'car','truck'};
            output_filename = fullfile(output_dir,'exp12_speech_vehicles.csv');

            args.cam = 1; % change source camera to cam01 (kid's view with 
                          % superimposed gaze)

            args.whence = 'start'; % manipulate timestamps based on onset
            args.interval = [0 3]; % set time window to 3 seconds after onset
            
            % this case finds all speech utterances in exp12 where the
            % keywords "car" and "truck" appeared in the utterance with 3
            % second window after utterance start
            query_keywords(expIDs,word_list,output_filename,args);
        case 3
            expIDs = 12;
            cevent_varname = 'cevent_eye_joint-attend_child-lead-moment_both';
            num_objs = get_num_obj(expIDs);
            target_obj_list = 1:num_objs; % all ROIs in exp12

            output_filename = fullfile(output_dir,'test_clJA_exp12.csv');
            args.cam = 2; % because the event is child-lead joint attention
                          % moments, we set the source camera to be 
                          % parent's view with gaze

            args.whence = 'start'; % manipulate timestamps based on onset
            args.interval = [-3 0]; % set time window to 3 seconds before onset

            % this case finds all instances within 3 seconds before child-lead JA moments
            query_csv_cevent(expIDs,cevent_varname,target_obj_list,output_filename,args);
        case 4
            expIDs = 12;
            cevent_varname = 'cevent_eye_joint-attend_parent-lead-moment_both';
            target_obj_list = 1:24; % specify a list of target ROIs that you'd like to query, in this case we are interested in all 24 ROIs in the experiment

            output_filename = 'test_plJA_exp12.csv';
            args.cam = 1; % because the event is parent-lead joint attention
                          % moments, we set the source camera to be 
                          % child's view with gaze

            args.whence = 'start'; % manipulate timestamps based on onset
            args.interval = [-3 0]; % set time window to 3 seconds before onset

            % this case finds all instances within 3 seconds before child-lead JA moments
            query_csv_cevent(expIDs,cevent_varname,target_obj_list,output_filename,args);
        case 5
            expIDs = 12;
            cevent_varname = 'cevent_eye_joint-attend_child-lead-enter-type_both';
            target_obj_list = 4; % one can also just specify one target ROI to query

            output_filename = fullfile(output_dir,'test_clJA-enter-type_exp12.csv');
            args.cam = 2; % because the event is child-lead joint attention
                          % moments, we set the source camera to be 
                          % parent's view with gaze

            % this case finds all instances within 3 seconds before child-lead JA moments
            query_csv_cevent(expIDs,cevent_varname,target_obj_list,output_filename,args);
        case 6
            expIDs = 12;
            word_list = {'cat'};
            output_filename = fullfile(output_dir,'exp12_speech_cat.csv');

            args.cam = 1; % change source camera to cam01 (kid's view with 
                          % superimposed gaze)

            args.whence = 'startend'; % manipulate timestamps based on both onset and offset
            args.interval = [-3 0]; % set time window to 3 seconds before onset to the original utterance offset
            
            % this case finds all speech utterances in exp12 where the
            % keyword "cat" appeared in the utterance
            query_keywords(expIDs,word_list,output_filename,args);
    end
end