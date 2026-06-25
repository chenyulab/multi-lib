% Def here % 

function cevent_to_img_frame(cevent_file, output_location, args)    
    %% ================ ARGS PARSING =================
    if ~exist('args', 'var') || isempty(args)
        args = struct([]);
    end
    
    % Include Attended Frames ? 
    if isfield(args, 'attended_obj')
        attended = args.attended_obj;
        fprintf("Processing frames (full and attended object frames) \n");
    else
        attended = false;
        fprintf("Processing frames \n");
    end
    
    % X frames per second or single frame ? 
    if isfield(args, 'fps')
        fpsArg = args.fps;
    else
        fpsArg = "single";
    end
    singleFrameMode = false;
    
    if isstring(fpsArg) || ischar(fpsArg)
        fpsStr = lower(strtrim(string(fpsArg)));
        if fpsStr == "single"
            singleFrameMode = true;
            fps = 1;
            fpsLabel = "_single";
            fprintf("with 1 frame per event\n");
        else
            fps = floor(str2double(fpsStr));
            if isnan(fps); error('args.fps must be numeric or "single".'); end
            
            if fps < 1
                singleFrameMode = true;
                fps = 1;
                fpsLabel = "1";
                fprintf("at 1 fps\n");
            else
                fpsLabel = string(fps);
                sprintf("at %d fps\n", fps);
            end
        end
    else
        fps = floor(double(fpsArg));
        if isnan(fps) || ~isfinite(fps); error('args.fps must be numeric or "single".'); end

        if fps < 1 
            singleFrameMode = true;
            fps = 1;
            fpsLabel = "1";
            fprintf("at 1 fps\n");
        else
            fpsLabel = string(fps);
            sprintf("at %d fps\n", fps);
        end
    end
    
    % Camera Views ? 
    if isfield(args, 'cameras')
        cameras = args.cameras;
    else
        cameras = ["cam07"];
    end

    camera_child = cameras(1);
    
    % Titles for folder and files ? 
    [~, inputName, ~] = fileparts(cevent_file);
    runName = string(inputName);
    if attended; runName = runName + "_att"; end
    runName = runName + "_fps" + fpsLabel;
    % 'output_location' is treated as a directory
    if ~exist("output_location", "var") || strlength(string(output_location)) == 0
        outputParentDir = pwd;
    else
        outputParentDir = string(output_location);
    end

    if ~isfolder(outputParentDir)
        mkdir(outputParentDir);
    end

    outputDir = fullfile(outputParentDir, runName);

    if ~isfolder(outputDir); mkdir(outputDir); end

    matOutputFile = fullfile(outputDir, runName + ".mat");
    
    % Input File ? 
    raw_input_file = cevent_file;
    raw = readcell(raw_input_file, "TextType", "string");
    hasExpID = any(string(raw) == "expID", 2);
    
    headerRow = find(hasExpID, 1, "first");
    if isempty(headerRow)
        error('Could not find a row containing "expID".');
    end
    
    originalHeader = raw(headerRow, :);
    isHeaderNonEmpty = ~cellfun(@isBlankCell, originalHeader);
    lastOriginalCol = find(isHeaderNonEmpty, 1, "last");
    if isempty(lastOriginalCol); error("Could not determine the last original header column."); end
    origHeaderNames = matlab.lang.makeUniqueStrings(matlab.lang.makeValidName(regexprep(string(raw(headerRow, 1:lastOriginalCol)), "^#", "")));
    
    
    varNames = string(raw(headerRow, :));
    varNames = regexprep(varNames, "^#", "");
    
    varNames = matlab.lang.makeValidName(varNames);
    varNames = matlab.lang.makeUniqueStrings(varNames);
    
    opts = detectImportOptions(raw_input_file);
    opts.VariableNamesLine = headerRow;
    opts.DataLines = [headerRow + 1, Inf];
    opts.VariableNames = varNames;
    
    T = readtable(raw_input_file, opts);
    % Remove blank/malformed rows that got read as data
    requiredCols = ["subID", "expID", "onset", "offset", ...
        "category", "trialsID", "instanceID"];

    for c = requiredCols
        if ~isnumeric(T.(c))
            T.(c) = str2double(string(T.(c)));
        end
    end

    validRows = true(height(T), 1);

    for c = requiredCols
        validRows = validRows & ~isnan(T.(c));
    end

    if any(~validRows)
        warning("Removing %d malformed rows from input table.", sum(~validRows));
    end

    T = T(validRows, :);
    subIDs = T{:, "subID"};
    expIDs = T{:, "expID"};
    onsets = T{:, "onset"};
    offsets = T{:, "offset"};
    categories = T{:, "category"};
    trialIDs = T{:, "trialsID"};
    instanceIDs = T{:, "instanceID"};
    
    n = height(T);
    folderCache = containers.Map();
    cstreamCache = containers.Map();
    
    selected_full_frame_paths = cell(n, 1);
    selected_full_frame_ids = cell(n, 1);
    
    for i = 1:n 
        selected_full_frame_ids{i} = [];
        selected_full_frame_paths{i} = strings(0, 1);
    end

    if attended                                                  
        selected_att_frame_paths = cell(n, 1);                  
        selected_att_frame_ids = cell(n, 1);
        
        for i = 1:n
            selected_att_frame_ids{i} = [];
            selected_att_frame_paths{i} = strings(0, 1);
        end
    end
    
    %% ================ Loop -- image paths and frame IDs =================
    
    for i = 1:n 
        subID = subIDs(i);
        expID = expIDs(i);
        onset = onsets(i);
        offset = offsets(i);
        category = categories(i); 
        trialID = trialIDs(i);
        instanceID = instanceIDs(i);
        
        onset_frame = time2frame_num(onset, subID);
        offset_frame = time2frame_num(offset, subID);
        mid_frame = time2frame_num((onset + offset) / 2, subID);
    
        subject_directory = get_subject_dir(subID);

        % ================= full frame first ===============
        full_camera_directory = sprintf("%s_frames_p", camera_child);
        full_image_folder = fullfile(subject_directory, full_camera_directory);
        if ~isfolder(full_image_folder)
            warning("Missing image folder: %s for instance %d", full_image_folder, instanceID);
        else
            full_cacheKey = sprintf("%d_%s", subID, full_image_folder);
            if isKey(folderCache, full_cacheKey)
                full_frameTable = folderCache(full_cacheKey);
            else
                full_frameTable = get_image_frame_table(full_image_folder);
                folderCache(full_cacheKey) = full_frameTable;
            end
        
            if isempty(full_frameTable)
                warning("No full frames found for sub %d, path=%s, instance %d", subID, full_image_folder, instanceID);
            else
                [fullIDs, fullPaths] = select_event_frames_by_fps(full_frameTable, onset, offset, subID, fps, false, singleFrameMode);
                if isempty(fullIDs); warning("No full image frames inside window for sub %d, instance %d", subID, instanceID)
                else
                    selected_full_frame_ids{i} = fullIDs;
                    selected_full_frame_paths{i} = fullPaths;
                end
            end
        end
    
        if attended
            % ==== Attended obj images ==== % 
            att_camera_directory = sprintf("%s_attended-objs-frames_p", camera_child);
            cstreamKey = sprintf("%d_cstreamROI", subID);
            if isKey(cstreamCache, cstreamKey)
                cstreamROI = cstreamCache(cstreamKey);
            else
                cstreamPath = fullfile(subject_directory, "derived", "cstream_eye_roi_child.mat");
                if ~isfile(cstreamPath); warning("Missing cstream ROI file for sub %d: %s", subID, cstreamPath);
                    continue;
                end

                cstreamStruct = load(cstreamPath);
                cstreamROI = cstreamStruct.sdata.data;
                cstreamCache(cstreamKey) = cstreamROI;
            end
        
            obj_att_ID = get_most_attended_object(cstreamROI, onset, offset);
            if isnan(obj_att_ID); warning("No attended obj for sub %d, instance %d", subID, instanceID);
                continue; 
            end
            att_image_folder = fullfile(subject_directory, att_camera_directory, sprintf("obj_%s", num2str(obj_att_ID)));
    
            if ~isfolder(att_image_folder); warning("Missing att obj folder: %s for instance %d", att_image_folder, instanceID); continue; end
    
            att_cacheKey = sprintf("%d_%s", subID, att_image_folder);
            if isKey(folderCache, att_cacheKey)
                att_frameTable = folderCache(att_cacheKey);
            else
                att_frameTable = get_image_frame_table(att_image_folder);
                folderCache(att_cacheKey) = att_frameTable;
            end  
            
            if isempty(att_frameTable)
                warning("No frames found for sub %d, object %d, path=%s, instance %d", subID, obj_att_ID, att_image_folder, instanceID);
                continue;
            end
            
            % Change for allowing duplicates or not
            [attIDs, attPaths] = select_event_frames_by_fps(att_frameTable, onset, offset, subID, fps, true, singleFrameMode);

            if isempty(attIDs); warning("No attended image frames inside window for sub %d, object %d, instance %d", subID, obj_att_ID, instanceID);
            else
                selected_att_frame_ids{i} = attIDs;
                selected_att_frame_paths{i} = attPaths;
            end
        end
    end
    
    T = add_frame_columns_to_table(T, selected_full_frame_ids, selected_full_frame_paths, "selected_full");

    if attended
        T = add_frame_columns_to_table(T, selected_att_frame_ids, selected_att_frame_paths, "selected_att");
    end
    
    fprintf("Copying images to %s\n", outputDir);
    copy_selected_images_to_folders(T, outputDir, camera_child, attended);
    
    %% ================ Save .mat =================
    rawOut = build_original_format_output(raw, T, origHeaderNames, lastOriginalCol, headerRow);
    save(matOutputFile, "rawOut", "-v7.3");
    fprintf("Saved original-format MAT output to: %s\n", matOutputFile);

    %% CSV Creation -- Currently Inactive --
    % allTNames = string(T.Properties.VariableNames);
    % newColNames = setdiff(allTNames, origHeaderNames, "stable");
    % 
    % if isempty(newColNames)
    %     warning("No new columns found in T to append."); 
    %     return;
    % end
    % 
    % nTRows = height(T);
    % 
    % if size(raw, 1) < headerRow + nTRows
    %     error("Raw cevent file has fewer rows than T expects.");
    % end
    % 
    % rawOut = raw;
    % 
    % nNewCols = numel(newColNames);
    % newColStart = lastOriginalCol + 1;
    % newColEnd = lastOriginalCol + nNewCols;
    % 
    % if size(rawOut, 2) < newColEnd
    %     rawOut(:, size(rawOut, 2)+1:newColEnd) = {""};
    % end
    % 
    % rawOut(headerRow, newColStart:newColEnd) = cellstr(newColNames);
    % dataRows = headerRow + 1 : headerRow + nTRows;
    % rawOut(dataRows, newColStart:newColEnd) = table2cell(T(:, newColNames));
    % 
    % rawOut = clean_missing(rawOut);
    % writecell(rawOut, output_location);
    % fprintf("Wrote output to: %s\n", output_location);
end

%% HELPERS

function [selectedIDs, selectedPaths] = select_event_frames_by_fps( ...
    frameTable, onset, offset, subID, fps, allowDuplicates, singleFrameMode)
    if isempty(frameTable)
        selectedIDs = [];
        selectedPaths = strings(0, 1);
        return;
    end

    eventDuration = offset - onset;
    if eventDuration <= 0
        selectedIDs = [];
        selectedPaths = strings(0, 1);
        return;
    end
    
    if singleFrameMode
        nWanted = 1;
    else
        nWanted = max(1, floor(eventDuration) * fps);
    end

    onsetFrame = time2frame_num(onset, subID);
    offsetFrame = time2frame_num(offset, subID);

    inEvent = frameTable.frame_id >= onsetFrame & frameTable.frame_id <= offsetFrame;

    candidates = frameTable(inEvent, :);

    if isempty(candidates)
        selectedIDs = [];
        selectedPaths = strings(0, 1);
        return;
    end

    % Evenly spaced frames
    % Currently if no distinct frame, allows duplicate even if allow
    % duplicates is false
    gap = eventDuration / (nWanted + 1);
    targetTimes = onset + gap * (1:nWanted);

    targetFrames = nan(nWanted, 1);

    for k = 1:nWanted
        targetFrames(k) = time2frame_num(targetTimes(k), subID);
    end

    selectedIdx = nan(nWanted, 1);

    if allowDuplicates
        for k = 1:nWanted
            [~, bestIdx] = min(abs(candidates.frame_id - targetFrames(k)));
            selectedIdx(k) = bestIdx;
        end
    else
        used = false(height(candidates), 1);
        for k = 1:nWanted
            [~, order] = sort(abs(candidates.frame_id - targetFrames(k)), "ascend");
            unusedIdx = order(find(~used(order), 1, "first"));

            if isempty(unusedIdx)
                [~, unusedIdx] = min(abs(candidates.frame_id - targetFrames(k)));
                fprintf("Duplicate frame used for %d", subID);
            end

            selectedIdx(k) = unusedIdx;
            used(unusedIdx) = true;
        end
    end
    selected = candidates(selectedIdx, :);
    selectedIDs = selected.frame_id;
    selectedPaths = selected.filepath;
end

function T = add_frame_columns_to_table(T, frameIDCells, framePathCells, prefix)
    n = height(T);
    counts = cellfun(@numel, frameIDCells);
    if isempty(counts) || max(counts) == 0; return; end

    maxFrames = max(counts);

    for k = 1:maxFrames
        ids = nan(n, 1);
        paths = strings(n, 1);

        for i = 1:n
            ids_i = frameIDCells{i};
            paths_i = framePathCells{i};

            if numel(ids_i) >= k
                ids(i) = ids_i(k);
            end

            if numel(paths_i) >= k
                paths(i) = paths_i(k);
            end
        end

        idColName = sprintf("%s_frame_id_%d", prefix, k);
        pathColName = sprintf("%s_frame_path_%d", prefix, k);

        T.(idColName) = ids;
        T.(pathColName) = paths;
    end
end

function [obj_att_ID] = get_most_attended_object(cstreamROI, onset, offset)
    timestamps = cstreamROI(:, 1);
    categories = cstreamROI(:, 2);

    inWindow = timestamps >= onset & timestamps <= offset & categories > 0;
    windowTimes = timestamps(inWindow);
    windowCategories = categories(inWindow);

    if isempty(windowCategories)
        obj_att_ID = NaN;
        return;
    end

    [uniqueCats, ~, groupIdx] = unique(windowCategories);
    counts = accumarray(groupIdx, 1);

    maxCount = max(counts);
    tiedCats = uniqueCats(counts == maxCount);

    midTime = onset + (offset - onset) / 2;

    isMostCommon = ismember(windowCategories, tiedCats);

    candidateTimes = windowTimes(isMostCommon);
    candidateCats = windowCategories(isMostCommon);

    [~, bestIdx] = min(abs(candidateTimes - midTime));

    obj_att_ID = candidateCats(bestIdx);


    
end

function frameTable = get_image_frame_table(image_folder)
    d = dir(image_folder);
    d = d(~[d.isdir]);

    names = string({d.name})';
    names = names(~ismember(names, ["Thumbs.db", ".DS_Store"]));
    if isempty(names); frameTable = table(); return; end

    frame_ids = nan(numel(names), 1);
    filepaths = strings(numel(names), 1);

    for j = 1:numel(names)
        [~, name, ~] = fileparts(names(j));
        tokens = regexp(name, '\d+', 'match');
        if isempty(tokens); frame_id = NaN; else; frame_id = str2double(tokens{end}); end

        frame_ids(j) = frame_id;
        filepaths(j) = fullfile(image_folder, names(j));
    end
    valid = ~isnan(frame_ids);

    frameTable = table(...
        names(valid), ...
        frame_ids(valid), ...
        filepaths(valid), ...
        'VariableNames', {'frame_name', 'frame_id', 'filepath'});

    frameTable = sortrows(frameTable, "frame_id", "ascend");
end

function tf = isBlankCell(x)
    if isempty(x)
        tf = true;
    elseif isstring(x) || ischar(x)
        sx = string(x);
        tf = ismissing(sx) || strlength(strtrim(sx)) == 0;
    elseif isnumeric(x)
        tf = isscalar(x) && isnan(x);
    else
        tf = false;
    end
end

function cleaned = clean_missing(cleaned)
    for k = 1:numel(cleaned)
        x = cleaned{k};

        if isa(x, "missing")
            cleaned{k} = "";
        elseif isstring(x) && isscalar(x) && ismissing(x)
            cleaned{k} = "";
        elseif iscategorical(x) && isscalar(x) && ismissing(x)
            cleaned{k} = "";
        end
    end
end

function copy_selected_images_to_folders(T, outputDir, defaultCamera, attended)
    rootDir = string(outputDir);
    fullDir = fullfile(rootDir, "full_images");
    attDir = fullfile(rootDir, "attended_images");
    if ~isfolder(rootDir); mkdir(rootDir); end
    if ~isfolder(fullDir); mkdir(fullDir); end
    if attended; if ~isfolder(attDir); mkdir(attDir); end; end

    varNames = string(T.Properties.VariableNames);

    fullPathCols = varNames(startsWith(varNames, "selected_full_frame_path_"));
    attPathCols = varNames(startsWith(varNames, "selected_att_frame_path_"));
    fullPathCols = sort_frame_path_cols(fullPathCols);
    attPathCols = sort_frame_path_cols(attPathCols);

    copy_image_group(T, fullPathCols, fullDir, defaultCamera);

    if attended; copy_image_group(T, attPathCols, attDir, defaultCamera); end

    fprintf("Copied selected images to: %s\n", rootDir);
end

function copy_image_group(T, pathCols, destDir, defaultCamera)
    
    if isempty(pathCols)
        return;
    end
    
    n = height(T);
    
    for i = 1:n
    
        subID = T.subID(i);
    
        if ismember("instanceID", string(T.Properties.VariableNames))
            instanceID = T.instanceID(i);
        else
            instanceID = i;
        end      
    
        for c = 1:numel(pathCols)
    
            pathCol = pathCols(c);
            currPath = string(T{i, pathCol});
    
            if ismissing(currPath) || strlength(strtrim(currPath)) == 0
                continue;
            end
    
            if ~isfile(currPath)
                warning("Image path does not exist: %s", currPath);
                continue;
            end
    
            % Get matching frame_id column from path column name
            idCol = replace(pathCol, "_path_", "_id_");
    
            frameID = T{i, idCol};
    
            camID = defaultCamera;
    
            [~, ~, ext] = fileparts(currPath);
    
            newName = sprintf("%s_%s_%s_%s%s", ...
                value_to_string(subID), ...
                value_to_string(camID), ...
                value_to_string(instanceID), ...
                value_to_string(frameID), ...
                ext);
    
            destPath = fullfile(destDir, newName);
    
            copyfile(currPath, destPath);
        end
    end
end

function sortedCols = sort_frame_path_cols(cols)

    if isempty(cols)
        sortedCols = cols;
        return;
    end
    
    nums = nan(numel(cols), 1);
    
    for k = 1:numel(cols)
        tok = regexp(cols(k), "_(\d+)$", "tokens", "once");
    
        if isempty(tok)
            nums(k) = inf;
        else
            nums(k) = str2double(tok{1});
        end
    end
    
    [~, order] = sort(nums);
    sortedCols = cols(order);
end

function s = value_to_string(x)

    if iscell(x)
        x = x{1};
    end
    
    if ismissing_value(x)
        s = "NA";
    elseif isnumeric(x)
        if isscalar(x) && isnan(x)
            s = "NA";
        elseif isscalar(x) && mod(x, 1) == 0
            s = string(sprintf("%d", x));
        else
            s = string(x);
        end
    elseif isstring(x) || ischar(x)
        s = string(x);
    elseif iscategorical(x)
        s = string(x);
    else
        s = string(x);
    end
    
    % Remove characters that are bad for filenames
    s = regexprep(s, "[^\w\-]", "");
end

function tf = ismissing_value(x)
    tf = false;
    
    if isempty(x)
        tf = true;
        return;
    end
    
    try
        tf = isscalar(x) && ismissing(x);
    catch
        tf = false;
    end
end

function rawOut = build_original_format_output(raw, T, origHeaderNames, lastOriginalCol, headerRow)
    allTNames = string(T.Properties.VariableNames);
    newColNames = setdiff(allTNames, string(origHeaderNames), "stable");
    rawOut = raw;

    if isempty(newColNames)
        warning("No new columns found in T to append.");
        rawOut = clean_missing(rawOut);
        return;
    end

    nTRows = height(T);
    dataRows = headerRow + 1 : headerRow + nTRows;

    if size(rawOut, 1) < dataRows(end)
        rawOut(size(rawOut, 1)+1:dataRows(end), :) = {""};
    end

    nNewCols = numel(newColNames);
    newColStart = lastOriginalCol + 1;
    newColEnd = lastOriginalCol + nNewCols;

    if size(rawOut, 2) < newColEnd
        rawOut(:, size(rawOut, 2)+1:newColEnd) = {""};
    end

    rawOut(headerRow, newColStart:newColEnd) = cellstr(newColNames);

    rawOut(dataRows, newColStart:newColEnd) = table2cell(T(:, newColNames));

    rawOut = clean_missing(rawOut);
end
