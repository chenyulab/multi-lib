function master_smi(subID_or_expID, flag)

% This function works only for comma separated txt data
% The subID_or_expID can be a subject/a list_of_subjects/an experimentID/a list_of_experimentIDs
% flag can be one of:
%   - 'overall'     (for debugging use; export all files listed below)
%   - 'all'         (exports all files except blink & saccade & undefined & missing) *Default
%   - 'roi'         (cstream_eye_roi_child & cevent_eye_roi_child)
%   - 'fixroi'      (cstream_eye_roi_fixation_child & cevent_eye_roi_fixation_child)
%   - 'trials'      (cevent_trials)
%   - 'blocks'      (cevent_blocks)
%   - 'cont2xy'     (cont2_eye_xy_child)
%   - 'blinkroi'    (cstream_eye_roi_blink_child)
%   - 'saccaderoi'  (cstream_eye_roi_saccade_child)
%   - 'undefined'   (cstream_eye_roi_undefined_child)   (when the event is not categorized by the SMI program)
%   - 'missing'     (cstream_eye_roi_missing_child)     (when the point of regard is beyond the screen)
%
% AOI data:
%   n+1 'White Space'
%   (n is the number of AOIs)
%   99  blink
%   98  saccade
%   97  undefined
%   96  missing
%
% E.g. master_smi([10001 10002])
%
% To make sure that this function works, there needs to be a
% 'expID_design.csv' and 'expID_design_subset.csv' inside the experiment folder
% and a 'both.txt' file inside the /extra_p folder. 
% E.g.  Experiment_folder
%       |_  expID_design.csv
%       |_  expID_design_subset.csv
%       |_  included
%           |_  extra_p
%               |_  both.txt

if ~exist('flag', 'var')
    flag = 'all';
end
for j = 1:numel(subID_or_expID)
    tmp = subID_or_expID(j);
    numOfTrialsInEachBlock = input('How many trials in each block?\n>>');
    trialLength = input('How many secs in each trial?\n>>');
    if ismember(tmp, list_experiments())
        subjects = list_subjects(tmp);
        disp(3)
        for i = 1:numel(subjects)
            tmpSub = subjects(i);
            master_smi_exp(tmpSub, flag, numOfTrialsInEachBlock, trialLength)
            disp(tmpSub)
        end
    elseif ismember(tmp, list_subjects())
        master_smi_exp(tmp, flag, numOfTrialsInEachBlock, trialLength)
    end
end
disp('[+] All done! Press Enter to close all figure windows...')
pause()
close all
end


function master_smi_exp(subID, flag, numOfTrialsInEachBlock, trialLength)   
%filename = 'Raw Data - Raw Data';
% subID = 10419;
% filename = '23568.txt';
disp('[*] Creating data files, please wait...')
sep = filesep();

if ~exist('flag', 'var')
    flag = 'all';
end

if ~exist('filename', 'var')
    %filename = 'Raw Data - Raw Data.txt';
    %filename = num2str(subID);
    %subj_info = get_subject_info(subID);
    %filename = [num2str(subj_info(4)), '.txt'];
end

%path = [get_subject_dir(subID) sep 'derived' sep]; 
file_dir = [get_subject_dir(subID) sep 'extra_p' sep 'both'];

T = readtable(file_dir);

%Exclude Trials and Stimulus
numOfData = numel(T.RecordingTime_ms_);
trialsToBeExcluded = {};
stimulusToBeExcluded = {};
trialsToBeIncluded = [1:numOfData];
stimulusToBeIncluded = [1:numOfData];
for i = 1:numel(trialsToBeExcluded)
    trialsToBeIncluded = intersect(trialsToBeIncluded, ...
        find(~strcmp(trialsToBeExcluded{i}, T.Trial)));
end
for i = 1:numel(stimulusToBeExcluded)
    stimulusToBeIncluded = intersect(stimulusToBeIncluded, ...
        find(~strcmp(stimulusToBeExcluded{i}, T.Stimulus)));
end
categoryGroupToBeIncluded = find(strcmp('Eye', T.CategoryGroup));
indexToBeIncluded = intersect(trialsToBeIncluded, stimulusToBeIncluded);
indexToBeIncluded = intersect(indexToBeIncluded, categoryGroupToBeIncluded);

%Innitializing data(recordingTime/trials/stimulus/categoryRight/x/y/aoi/numOfCleanData)
sampleRate = 30;
recordingTime  = T.RecordingTime_ms_(indexToBeIncluded) / 1000;
trials = {T.Trial{indexToBeIncluded}};
stimulus = {T.Stimulus{indexToBeIncluded}};

categoryRight = {T.CategoryRight{indexToBeIncluded}};
categoryLeft = {T.CategoryLeft{indexToBeIncluded}};

cellxRight = {T.PointOfRegardRightX_px_{indexToBeIncluded}};
cellxLeft = {T.PointOfRegardLeftX_px_{indexToBeIncluded}};

cellyRight = {T.PointOfRegardRightY_px_{indexToBeIncluded}};
cellyLeft = {T.PointOfRegardLeftY_px_{indexToBeIncluded}};

cellaoiRight = {T.AOINameRight{indexToBeIncluded}}';
cellaoiLeft = {T.AOINameLeft{indexToBeIncluded}}';

[categroy, cellx, celly, cellaoi] = merge_leftnright(categoryRight, categoryLeft,...
    cellxRight, cellxLeft, cellyRight, cellyLeft, cellaoiRight, cellaoiLeft);

numOfCleanData = numel(recordingTime);
x = zeros(numOfCleanData, 1);
y = zeros(numOfCleanData, 1);
aoi = zeros(numOfCleanData, 1);
    
%Ask for the designed number of AOIs
designedNumberOfAOIs = 44;%input('How many AOIs in this study?\n>>');

%Ask for the number of trials in each block
%numOfTrialsInEachBlock = input('How many trials in each block?\n>>');
%--------------> Moved to the main function

%Ask for the minDuration
minDuration = 0.07;%input('The minDuration of small sgements? (in seconds E.g. 0.25) cevent duration less than this number will be removed.\n>>');

%Ask for the maxGap
maxGap = 0.3;%input('The maxGap that can be merged? (in seconds E.g. 0.5) cevent gap duration less than this number will be merged. No more than 1 sec.\n>>');

%Actual number of AOIs in this study
numOfAOIs = 0;
listOfAOIs = {};
for i = 1:numOfCleanData
    if ~any(strcmp(cellaoi{i}, listOfAOIs)) &&...
            ~strcmp(cellaoi{i}, 'White Space') &&...
            ~strcmp(cellaoi{i}, '-')
        numOfAOIs = numOfAOIs + 1;
        listOfAOIs = horzcat(listOfAOIs, cellaoi{i});
    end
end

disp(['[*] There are ' num2str(numOfAOIs) ' AOIs detected in this trial'])
for i = 1:numOfCleanData
    
    if strcmp(cellx{i}, '-')
        x(i) = NaN;
    else
        x(i) = str2num(cellx{i});
    end
    
    if strcmp(celly{i}, '-')
        y(i) = NaN;
    else
        y(i) = str2num(celly{i});
    end
    
    if strcmp(cellaoi{i}, '-')
        aoi(i) = 96;
    elseif strcmp(cellaoi{i}, 'White Space')
        aoi(i) = designedNumberOfAOIs + 1;
    else
        aoi(i) = str2num(cellaoi{i});
    end
end

%Seperate the data for each trials
trialIndex = {};
trialSet = {};
numOfTrials = 0;
for i = 1:numOfCleanData
    if ~any(strcmp(trials{i}, trialSet))
        numOfTrials = numOfTrials + 1;
        trialSet{numOfTrials} = trials{i};
    end
end
for i = 1:numel(trialSet)
    trialIndex{i} = find(strcmp(trialSet{i}, trials));
end

%Formate time stamps
%trialLength = input('How many secs in each trial?\n>>');
%--------------> Moved to the main function
startingTime = 30;
intervalBetweenTwoTrials = 1;
intervalBetweenTwoStamps = 0.033;
numOfTimeStamps = trialLength * sampleRate;
formattedTimeStamps = zeros(numOfTimeStamps, 1);
for i = 1:numOfTimeStamps
    mili = rem(i - 1, 3) * intervalBetweenTwoStamps;
    pointSec = fix((i - 1) / 3) * 0.1;
    sec = mili + pointSec;
    formattedTimeStamps(i) = sec;
end

revisedData = {};

for i = 1:numel(trialIndex)
    currentTrialInd = trialIndex{i};
    tmpRecordingTime = recordingTime(currentTrialInd);
    %tmpStimulus = {stimulus{currentTrialInd}};
    tmpCategory = {categroy{currentTrialInd}};
    tmpx = x(currentTrialInd);
    tmpy = y(currentTrialInd);
    tmpaoi = aoi(currentTrialInd);
    tmpRecordingTime = tmpRecordingTime - tmpRecordingTime(1);
    finalIndex = suitTimeStamps(tmpRecordingTime, formattedTimeStamps);
    tmpTrialData = {};
    for j = 1:numel(finalIndex)
        tmpInd = finalIndex(j);
        if ~isnan(tmpInd)
            tmpTrialData{j,1} = formattedTimeStamps(tmpInd) + ...
                (trialLength + intervalBetweenTwoTrials) * (i - 1) + startingTime;
            tmpTrialData{j,2} = tmpCategory{tmpInd};
            tmpTrialData{j,3} = tmpx(tmpInd);
            tmpTrialData{j,4} = tmpy(tmpInd);
            tmpTrialData{j,5} = tmpaoi(tmpInd);
        else
            tmpTrialData{j,1} = NaN;
            tmpTrialData{j,2} = NaN;
            tmpTrialData{j,3} = NaN;
            tmpTrialData{j,4} = NaN;
            tmpTrialData{j,5} = NaN;
        end
    end
    revisedData = vertcat(revisedData, tmpTrialData);
end

%Stimulus list
stimList = {};
currentStimulus = '';
for i = 1:numel(stimulus)
    if ~strcmp(stimulus{i}, currentStimulus)
        currentStimulus = stimulus{i};
        stimList{end+1} = currentStimulus;
    end
end

%Simulus(characters) list to number list
visitedStim = {};
tmpCounter = 0;
stimNumList = [];
for i = 1:numel(stimList)
    if ismember(stimList{i}, visitedStim)
        stimNumList(end+1) = find(strcmp(stimList{i}, visitedStim));
    else
        tmpCounter = tmpCounter + 1;
        stimNumList(end+1) = tmpCounter;
        visitedStim{end+1} = stimList{i};
    end
end

%Transcribe the final data to lab format data
%Generating cevent_trials data
cevent_trials = [];
for i = 1:numOfTrials
    cevent_trials(i, 1) = 30 + ...
        (i - 1) * (trialLength + intervalBetweenTwoTrials);
    cevent_trials(i, 2) = cevent_trials(i, 1) + trialLength;
    cevent_trials(i, 3) = stimNumList(i);
end

%Onsets and Offsets are used for generating the experiment design files
onsets = cevent_trials(:, 1);
offsets = cevent_trials(:, 2);
%----------------------------> See (line 335)

%generating cevent_blocks data
cevent_blocks = [];
cevent_blocks(:, 1:2) = cevent_trials(:, 1:2);
numOfBlocks = numOfTrials / numOfTrialsInEachBlock;
for i = 1:numOfBlocks
    cevent_blocks(((i-1)*numOfTrialsInEachBlock)+1:i*numOfTrialsInEachBlock, 3) = i;
end

%====================================
cont2_eye_xy_child = [];
cstream_eye_roi_child_all = [];
cstream_eye_roi_fixation_child = [];
cstream_eye_roi_saccade_child = [];
cstream_eye_roi_blink_child = [];
cstream_eye_roi_undefined_child = [];

%fixCounter = 1;

for i = 1:size(revisedData, 1)
    cont2_eye_xy_child(i, 1) = revisedData{i, 1};
    cont2_eye_xy_child(i, 2) = revisedData{i, 3};
    cont2_eye_xy_child(i, 3) = revisedData{i, 4};
    cstream_eye_roi_child_all(i, 1) = revisedData{i, 1};
    cstream_eye_roi_child_all(i, 2) = revisedData{i, 5};
    %---fixation---(raw)
    if strcmp(revisedData{i, 2}, 'Fixation') && (96 ~= revisedData{i, 5})
        cstream_eye_roi_fixation_child(i, 1) = revisedData{i, 1};
        cstream_eye_roi_fixation_child(i, 2) = revisedData{i, 5};
        %fixCounter = fixCounter + 1;
    else
        cstream_eye_roi_fixation_child(i, 1) = revisedData{i, 1};
        cstream_eye_roi_fixation_child(i, 2) = 0;
    end
    %----Saccade----
    if strcmp(revisedData{i, 2}, 'Saccade')
        cstream_eye_roi_saccade_child(i, 1) = revisedData{i, 1};
        cstream_eye_roi_saccade_child(i, 2) = revisedData{i, 5};
        cstream_eye_roi_child_all(i, 1) = revisedData{i, 1};
        cstream_eye_roi_child_all(i, 2) = 98;
    else
        cstream_eye_roi_saccade_child(i, 1) = revisedData{i, 1};
        cstream_eye_roi_saccade_child(i, 2) = 0;
    end
    %-----Blink-----
    if strcmp(revisedData{i, 2}, 'Blink')
        cstream_eye_roi_blink_child(i, 1) = revisedData{i, 1};
        cstream_eye_roi_blink_child(i, 2) = revisedData{i, 5};
        cstream_eye_roi_child_all(i, 1) = revisedData{i, 1};
        cstream_eye_roi_child_all(i, 2) = 99;
    else
        cstream_eye_roi_blink_child(i, 1) = revisedData{i, 1};
        cstream_eye_roi_blink_child(i, 2) = 0;
    end
    %---Undefined---
    if strcmp(revisedData{i, 2}, '-')
        cstream_eye_roi_undefined_child(i, 1) = revisedData{i, 1};
        cstream_eye_roi_undefined_child(i, 2) = revisedData{i, 5};
        cstream_eye_roi_child_all(i, 1) = revisedData{i, 1};
        cstream_eye_roi_child_all(i, 2) = 97;
    else
        cstream_eye_roi_undefined_child(i, 1) = revisedData{i, 1};
        cstream_eye_roi_undefined_child(i, 2) = 0;
    end
    %----missing----
    if 96 == revisedData{i, 5}
        cstream_eye_roi_missing_child(i, 1) = revisedData{i, 1};
        cstream_eye_roi_missing_child(i, 2) = revisedData{i, 5};
        cstream_eye_roi_child_all(i, 1) = revisedData{i, 1};
        cstream_eye_roi_child_all(i, 2) = 96;
    else
        cstream_eye_roi_missing_child(i, 1) = revisedData{i, 1};
        cstream_eye_roi_missing_child(i, 2) = 0;
    end
end

cat_list = [1:get_num_obj(subID)+1];
cevent_eye_roi_child = cevent_merge_segments(cevent_remove_small_segments(cstream2cevent(cstream_eye_roi_fixation_child), minDuration), maxGap,cat_list);
timeBase = cell2mat(revisedData(:, 1));
cstream_eye_roi_child = cevent2cstreamtb(cevent_eye_roi_child, timeBase);

%generating design variables
design_to_variables(subID, onsets, offsets, timeBase)
design_to_variables_subset(subID, onsets, offsets, timeBase)

%recording data
switch flag
    
    case 'overall'
        %----cont2----
        record_variable(subID, 'cont2_eye_xy_child', cont2_eye_xy_child)
        %-----roi-----
        record_additional_variable(subID, 'cstream_eye_roi_child_all', cstream_eye_roi_child_all)
        record_additional_variable(subID, 'cevent_eye_roi_child_all', cstream2cevent(cstream_eye_roi_child_all))
        %---fixation---(raw)
        record_variable(subID, 'cstream_eye_roi_fixation_child', cstream_eye_roi_fixation_child)
        record_variable(subID, 'cevent_eye_roi_fixation_child', cstream2cevent(cstream_eye_roi_fixation_child))
        %---fixation---(merged)
        %record_variable(subID, ...
        %    'cevent_eye_roi_child', ...
        %    cevent_merge_segments(cevent_remove_small_segments(cstream2cevent(cstream_eye_roi_fixation_child), minDuration), maxGap))
        record_variable(subID, 'cstream_eye_roi_child',  cstream_eye_roi_child)
        record_variable(subID, 'cevent_eye_roi_child',  cevent_eye_roi_child)
        %----Saccade----
        record_additional_variable(subID, 'cstream_eye_roi_saccade_child', cstream_eye_roi_saccade_child)       
        %-----Blink-----
        record_additional_variable(subID, 'cstream_eye_roi_blink_child', cstream_eye_roi_blink_child)
        %---Undefined---
        record_additional_variable(subID, 'cstream_eye_roi_undefined_child', cstream_eye_roi_undefined_child)
        %----Missing----
        record_additional_variable(subID, 'cstream_eye_roi_missing_child', cstream_eye_roi_missing_child)
        %----trials----
        record_variable(subID, 'cevent_trials', cevent_trials)
        %----blocks----
        record_additional_variable(subID, 'cevent_block_order', cevent_blocks)
        
        
    case 'all'
        %----cont2----
        record_variable(subID, 'cont2_eye_xy_child', cont2_eye_xy_child)
        %-----roi-----
        record_additional_variable(subID, 'cstream_eye_roi_child_all', cstream_eye_roi_child_all)
        record_additional_variable(subID, 'cevent_eye_roi_child_all', cstream2cevent(cstream_eye_roi_child_all))
        %---fixation---(raw)
        record_variable(subID, 'cstream_eye_roi_fixation_child', cstream_eye_roi_fixation_child)
        record_variable(subID, 'cevent_eye_roi_fixation_child', cstream2cevent(cstream_eye_roi_fixation_child))
        %---fixation---(merged)
        %record_variable(subID, ...
        %    'cevent_eye_roi_child', ...
        %    cevent_merge_segments(cevent_remove_small_segments(cstream2cevent(cstream_eye_roi_fixation_child), minDuration), maxGap))
        record_variable(subID, 'cstream_eye_roi_child',  cstream_eye_roi_child)
        record_variable(subID, 'cevent_eye_roi_child',  cevent_eye_roi_child)
        %----trials----
        record_variable(subID, 'cevent_trials', cevent_trials)
        %----blocks----
        record_additional_variable(subID, 'cevent_block_order', cevent_blocks)
        
    case 'roi'
        %-----roi-----
        record_additional_variable(subID, 'cstream_eye_roi_child_all', cstream_eye_roi_child_all)
        record_additional_variable(subID, 'cevent_eye_roi_child_all', cstream2cevent(cstream_eye_roi_child_all))
        
    case 'fixroi'
        %---fixation---(raw)
        record_variable(subID, 'cstream_eye_roi_fixation_child', cstream_eye_roi_fixation_child)
        record_variable(subID, 'cevent_eye_roi_fixation_child', cstream2cevent(cstream_eye_roi_fixation_child))
        %---fixation---(merged)
        %record_variable(subID, ...
        %    'cevent_eye_roi_child', ...
        %    cevent_merge_segments(cevent_remove_small_segments(cstream2cevent(cstream_eye_roi_fixation_child), minDuration), maxGap))
        record_variable(subID, 'cstream_eye_roi_child',  cstream_eye_roi_child)
        record_variable(subID, 'cevent_eye_roi_child',  cevent_eye_roi_child)
        
    case 'trials'
        %----trials----
        record_variable(subID, 'cevent_trials', cevent_trials)
        
    case 'blocks'
        %----blocks----
        record_additional_variable(subID, 'cevent_block_order', cevent_blocks)
        
    case 'cont2xy'
        %----cont2----
        record_variable(subID, 'cont2_eye_xy_child', cont2_eye_xy_child)
        
    case 'blinkroi'
        %-----Blink-----
        record_additional_variable(subID, 'cstream_eye_roi_blink_child', cstream_eye_roi_blink_child)
        
    case 'saccaderoi'
        %----Saccade----
        record_additional_variable(subID, 'cstream_eye_roi_saccade_child', cstream_eye_roi_saccade_child)
        
    case 'undefined'
        %---Undefined---
        record_additional_variable(subID, 'cstream_eye_roi_undefined_child', cstream_eye_roi_undefined_child)
        
    case 'missing'
        %----Missing----
        record_additional_variable(subID, 'cstream_eye_roi_missing_child', cstream_eye_roi_missing_child)
    otherwise
        disp('[-] Not a valid flag')
        return
end
disp('[+] Data files created')
vis_smi(subID)
end

function [category, x, y, aoi] = merge_leftnright(rcategory, lcategory, rx, lx, ry, ly, raoi, laoi)
category = {};
x = {};
y = {};
aoi = {};

for i = 1:numel(raoi)
    if (strcmp(raoi{i}, '-') && ~strcmp(laoi{i}, '-')) || ...
            (strcmp(raoi{i}, 'White Space') && ...
            ~strcmp(laoi{i}, 'White Space') && ...
            ~strcmp(laoi{i}, '-'))
        category{i} = lcategory{i};
        x{i} = lx{i};
        y{i} = ly{i};
        aoi{i} = laoi{i};
    else
        category{i} = rcategory{i};
        x{i} = rx{i};
        y{i} = ry{i};
        aoi{i} = raoi{i};
    end
end
end

function design_to_variables(subID, onset, offset, timeBase)
expID = sub2exp(subID);
design_dir = fullfile(get_multidir_root, sprintf('experiment_%d', expID), sprintf('%d_design.csv', expID));
T = importdata(design_dir);
for i = 1:numel(T.colheaders)
    nameOfCfile = T.colheaders{i};
%     assignin('base', 'nameOfCfile', nameOfCfile)
%     assignin('base', 'colheaders', T.colheaders)
    cfileData = T.data(:, i);
    ceventToBeRecorded = [onset offset cfileData];
    cstreamToBeRecorded = cevent2cstreamtb(ceventToBeRecorded, timeBase);
    record_additional_variable(subID, nameOfCfile, ceventToBeRecorded)
    record_additional_variable(subID, strrep(nameOfCfile, 'cevent', 'cstream'), cstreamToBeRecorded)
end
end

function design_to_variables_subset(subID, onset, offset, timeBase)
expID = sub2exp(subID);
design_dir = fullfile(get_multidir_root, sprintf('experiment_%d', expID), sprintf('%d_design_subset.csv', expID));
T = importdata(design_dir);
for i = 1:numel(T.colheaders)
    nameOfCfile = T.colheaders{i};
%     assignin('base', 'nameOfCfile', nameOfCfile)
%     assignin('base', 'colheaders', T.colheaders)
    cfileData = T.data(:, i);
    indToBeIncluded = find(cfileData ~= 0);
    ceventToBeRecorded = [onset(indToBeIncluded) offset(indToBeIncluded) cfileData(indToBeIncluded)];
    cstreamToBeRecorded = cevent2cstreamtb(ceventToBeRecorded, timeBase);
    record_additional_variable(subID, nameOfCfile, ceventToBeRecorded)
    record_additional_variable(subID, strrep(nameOfCfile, 'cevent', 'cstream'), cstreamToBeRecorded)
end
end
