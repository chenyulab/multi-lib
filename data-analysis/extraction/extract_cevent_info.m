function [rawOut, T, datamatrix, hd] = extract_cevent_info(cevent_variable, subexpIDs, output_file)
% extract_cevent_info
%
% Creates the first 7 columns in the original extract_multi_measures-style
% format, using every row/instance of an input cevent variable.
%
% INPUTS:
%   cevent_variable : name of cevent variable, e.g.
%                     "cevent_speech_naming_local-id"
%
%   subexpIDs       : experiment ID, subject ID, or list of IDs.
%                     Examples:
%                         351
%                         35101
%                         [35101 35102 35103]
%
%   output_file     : .csv file
%
% OUTPUTS:
%  csv file          : original-format cell array with 4 header rows
%
% Output columns:
%   subID, expID, onset, offset, category, trialsID, instanceID

    if nargin < 3
        error("Must have 3 arguments (cevent, subexpID, output");
    end

    output_file = string(output_file);

    [folder, name, ext] = fileparts(output_file);

    if strlength(name) == 0 || strlength(ext) == 0

        error("Output file must include a valid file name and extension.");

    end

    if strlength(folder) > 0 && ~isfolder(folder)

        error("Output folder does not exist: %s", folder);

    end
    
    cevent_variable = string(cevent_variable);

    subs = cIDs(subexpIDs);

    allData = cell(numel(subs), 1);

    for s = 1:numel(subs)

        subID = subs(s);
        fprintf("\nProcessing %d\n", subID);

        %% Get raw cevent data
        try
            ceventData = get_variable(subID, char(cevent_variable));
        catch
            warning("Variable %s doesn't exist for subject %d\n", char(cevent_variable), subID);
            continue
        end

        if isempty(ceventData)
            warning("No data found for %s in subject %d", cevent_variable, subID);
            continue;
        end

        if size(ceventData, 2) < 3
            warning("%s for subject %d has fewer than 3 columns.", cevent_variable, subID);
            continue;
        end

        onset = ceventData(:, 1);
        offset = ceventData(:, 2);
        category = ceventData(:, 3);

        %% Assign trialsID using frame-window overlap
        trials = get_trials(subID);

        [trialIDs, keepMask, onsetClipped, offsetClipped] = assign_trial_ids_by_frame_window( ...
            subID, onset, offset, trials);

        onset = onsetClipped(keepMask);
        offset = offsetClipped(keepMask);
        category = category(keepMask);
        trialIDs = trialIDs(keepMask);
        

        nKeep = numel(onset);

        if nKeep == 0
            warning("No cevent rows for subject %d overlapped with trial windows.", subID);
            continue;
        end
        instanceID = (1:nKeep)';

        %% Build first 7 columns
        subCol = repmat(subID, nKeep, 1);
        expCol = repmat(sub2exp(subID), nKeep, 1);

        allData{s} = [ ...
            subCol, ...
            expCol, ...
            onset, ...
            offset, ...
            category, ...
            trialIDs, ...
            instanceID ...
        ];

    end

    %% ================================================================
    %  Combine subjects
    %  ================================================================

    allData = allData(~cellfun(@isempty, allData));

    if isempty(allData)
        datamatrix = zeros(0, 7);
    else
        datamatrix = vertcat(allData{:});
    end

    %% ================================================================
    %  Build original-format rawOut cell array

    nRows = size(datamatrix, 1);

    rawOut = cell(nRows + 4, 7);
    rawOut(:) = {""};

    % Four-row header format
    rawOut(1, :) = {"#", "", char("base:" + cevent_variable), "", "", "", ""};
    rawOut(2, :) = {"#", "", "", "", "", "", ""};
    rawOut(3, :) = {"#", "", "", "", "", "", ""};
    rawOut(4, :) = {"#subID", "expID", "onset", "offset", ...
                    "category", "trialsID", "instanceID"};

    % Data rows
    if nRows > 0
        rawOut(5:end, :) = num2cell(datamatrix);
    end

    output_file = string(output_file);
  
    writecell(rawOut, output_file);
    fprintf("\nSaved original-format CSV output to: %s\n", output_file);

end


%% ========================================================================
%  Helper: assign trial IDs by frame-window overlap
%  ========================================================================

function [trialIDs, keepMask, onsetClipped, offsetClipped] = assign_trial_ids_by_frame_window(subID, onset, offset, trials)

    nEvents = numel(onset);
    trialIDs = nan(nEvents, 1);
    keepMask = false(nEvents, 1);
    onsetClipped = onset;
    offsetClipped = offset;

    if isempty(trials); warning("No trials found for subject %d.", subID);return; end

    trialStartFrames = trials(:, 1);
    trialEndFrames = trials(:, 2);

    trialMinFrames = min(trialStartFrames, trialEndFrames);
    trialMaxFrames = max(trialStartFrames, trialEndFrames);

    nTrials = size(trials, 1);

    trialNums = (1:nTrials)';

    for i = 1:nEvents
        if isnan(onset(i)) || isnan(offset(i)); continue; end

        try 
            eventStartFrame = time2frame_num(onset(i), subID);
            eventEndFrame = time2frame_num(offset(i), subID);
        catch
            warning("Could not convert cevent row %d times to frames for sub %d", ...
                i, subID);
            continue;
        end
        
        eventMinFrame = min(eventStartFrame, eventEndFrame);
        eventMaxFrame = max(eventStartFrame, eventEndFrame);
        
        overlapStart = max(eventMinFrame, trialMinFrames);
        overlapEnd = min(eventMaxFrame, trialMaxFrames);

        overlaps = overlapEnd - overlapStart + 1;
        overlaps(overlaps < 0) = 0;

        [bestOverlap, bestIdx] = max(overlaps);

        if bestOverlap <= 0
            continue;
        end

        trialIDs(i) = trialNums(bestIdx);
        keepMask(i) = true;

        clippedStartFrame = overlapStart(bestIdx);
        clippedEndFrame = overlapEnd(bestIdx);

        onsetClipped(i) = frame_num2time(clippedStartFrame, subID);
        offsetClipped(i) = frame_num2time(clippedEndFrame, subID);
    end
end

