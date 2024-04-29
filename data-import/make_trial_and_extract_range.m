%%%
% Author: Jane Yang
% Last modified: 4/25/2024
%
% Description: This script finds the trial.csv file of an input subject and
% outputs one trialInfo.txt file and an extract_range.txt file. The
% trial.csv is created by Datavyu, and the script parses the trial.csv file
% and creates trialInfo.txt to contain trial information in frames. And the
% extract_range.txt file contains the onset and offset frame for frame
% extraction.
%
% Input:        expID - experiment ID
%               kidID - kid's unique identifier
%               date - kid's experiment date
%
% Output: extract_range.txt and trialInfo.txt saved under supporting_files
% under subject's folder in temp_backus
%%%
function make_trial_and_extract_range(expID,kidID,date)
    root = get_temp_backus_root();
    msTosec = 1/1000;
    frameRate = 30;
    
    % get subject's directory on temp_backus
    subRoot = fullfile(root,sprintf('experiment_%d',expID),'included',sprintf('__%d_%d',date,kidID));
    
    % get subject's supporting_files folder
    subFilePath = fullfile(subRoot,'supporting_files','trial.csv');
    extractRangePath = fullfile(subRoot,'supporting_files','extract_range.txt');
    trialInfoPath = fullfile(subRoot,'supporting_files','trialInfo.txt');
    
    trialData = readtable(subFilePath);
    
    onset = ceil(trialData{1,2}*msTosec*frameRate);
    offset = ceil(trialData{end,3}*msTosec*frameRate);
    
    % save onset&offset frame to extract_range.txt
    extract_range = vertcat(onset,offset);
    
    % check if the file already exists to prevent overwriting
    fileID = fopen(extractRangePath, 'w');
    for i = 1:size(extract_range,1)
        fprintf(fileID, '[%d]\n', extract_range(i));
    end
    fclose(fileID);
    
    % make trialInfo.csv file
    timestamps = horzcat(ceil(trialData{:,2}*msTosec*frameRate),ceil(trialData{:,3}*msTosec*frameRate));
    trialInfo = horzcat(trialData{:,end},timestamps);
    
    if ~exist(trialInfoPath,'file')
        writematrix(trialInfo,trialInfoPath,'Delimiter','comma');
    else
        disp('Subject already has an trialInfo.txt file!');
    end
end


