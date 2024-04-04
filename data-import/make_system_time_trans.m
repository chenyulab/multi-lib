%%
% Author: Anagha Kenikar
% Last modified: 02/21/2024
% This function takes in an experiment ID and creates a new version of 
% the speech transcription file to have onsets and offsets by the system
% time rather than the raw time.
%
% Input: Name                       Description
%        subID                     a subject ID
%
% Output: a text file with onsets and offsets adjusted by system time and
% the corresponding utterances
%
% sample function call: make_system_time_trans(1201)

function make_system_time_trans(subID)
    filepath = get_info_file_path(subID);
    subj_dir = get_subject_dir(subID);
    subj_info = get_subject_info(subID);
    
    kidID = subj_info(4);
    
    % getting the name and direcory of the speech transcription file to update
    speech_file_name = strcat('speech_',num2str(kidID), '.txt');
    dir = fullfile(subj_dir,'speech_transcription_p', speech_file_name);
    
    transcription_file = readtable(dir);
    trial = load(filepath);
    
    % finding the offsets between the raw and system time
    offset = trial.trialInfo.speechTime;
    indices = [1,2];
    
    % updating the time in the transcription file
    for i = 1:size(transcription_file, 1)
        transcription_file(i, indices) = round((transcription_file(i, indices)+offset), 6);
    end
    
    % output the new system time speech transcription file
    output_filename = strcat('speech_', num2str(kidID), '_system-time.txt');
    output_dir = fullfile(subj_dir, 'speech_transcription_p', output_filename);
    writetable(transcription_file, output_dir, 'WriteVariableNames', false, 'Delimiter', '\t');