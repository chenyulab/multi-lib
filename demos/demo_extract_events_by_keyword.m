%%
% Author: Jane Yang
% Modifier: Jingwen Pang
% Last modified: 11/12/2024
% This demo function presents different cases on how to use the
% extract_events_by_keyword function to generate a csv file containing
% instances when a (speech) keyword happened.
% 
% extract_events_by_keyword
% - Given a list of keywords, retrieve all timestamps of speech utterances 
%   containing the keywords
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
function demo_extract_events_by_keyword(option)
    % this is the demo output directory, if you want to try functions on your own,
    % you can modify this to save your output file into your own place
    output_dir = 'Z:\demo_output_files\extract_events_by_keyword';
    switch option
        case 1
            % Retrieve all timestamps of speech utterances containing the keyword
            % 'babyname' and save as csv
            expIDs = 12;
            word_list = {'babyname'};
            output_filename = fullfile(output_dir,'exp12_speech_babyname.csv');
            
            extract_events_by_keyword(expIDs,word_list,output_filename)
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
            extract_events_by_keyword(expIDs,word_list,output_filename,args);

    end
end