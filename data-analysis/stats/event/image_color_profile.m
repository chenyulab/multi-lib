function image_color_profile(input_file, frameType)
%% =============== ARGS PARSING ===============
    validTypes = ["all", "full", "attended"];
    if ~ismember(frameType, validTypes)
        error('FrameType must be "all", "full", or "attended".');
    end

    S = load(input_file);
    rawOut = S.rawOut;

    colorLabels = ["red", "orange", "yellow", "green", "blue", ...
                   "purple", "pink", "white", "black", "gray"];
    
    palette = [
        1.00 0.00 0.00 % red
        1.00 0.50 0.00 % orange
        1.00 1.00 0.00 % yellow
        0.00 1.00 0.00 % green
        0.00 0.00 1.00 % blue
        0.50 0.00 0.80 % purple
        1.00 0.40 0.70 % pink
        1.00 1.00 1.00 % white
        0.00 0.00 0.00 % black
        0.50 0.50 0.50 % gray
    ];

    [folder, name, ~] = fileparts(input_file);
    if strlength(string(folder)) == 0; folder = pwd; end

    outFile = fullfile(folder, name + "_" + frameType + "_colors.mat");
    colorImgDir = fullfile(folder, "color_images");
    
    if ~isfolder(colorImgDir);mkdir(colorImgDir);end

    %% Find header row
    rawStr = cell_to_string_matrix(rawOut);
    rawStrClean = strtrim(erase(rawStr, "#"));
    hasExpID = any(rawStrClean == "expID", 2);
    headerRow = find(hasExpID, 1, "first");

    if isempty(headerRow)
        error('Could not find a row containing "expID".');
    end

    headers = rawStrClean(headerRow, :);
    
    isHeaderNonEmpty = strlength(strtrim(headers)) > 0 & ~ismissing(headers);
    lastCol = find(isHeaderNonEmpty, 1, "last");

    headers = headers(1:lastCol);

    for j = 1:lastCol
        rawOut{headerRow, j} = headers(j);
    end
    %% Find selected frame path columns from the original-format header row
    fullMask = startsWith(headers, "selected_full_frame_path_");
    attMask = startsWith(headers, "selected_att_frame_path_");
    
    switch frameType
        case "all"
            pathMask = fullMask | attMask;
        case "full"
            pathMask = fullMask;
        case {"attended"}
            pathMask = attMask;
    end

    pathCols = headers(pathMask);

    if isempty(pathCols)
        error("No selected frame path columns found.");
    end

    pathCols = sort_frame_path_cols(pathCols);

    pathColIdx = zeros(numel(pathCols), 1);

    for c = 1:numel(pathCols)
        pathColIdx(c) = find(headers == pathCols(c), 1, "first");
    end

    %% Determine where new columns should go
    isHeaderNonEmpty = strlength(strtrim(headers)) > 0 & ~ismissing(headers);
    nextCol = find(isHeaderNonEmpty, 1, "last") + 1;

    dataRows = headerRow + 1 : size(rawOut, 1);

    %% Process each selected frame path column
    for c = 1:numel(pathCols)
        pathCol = pathCols(c);
        pathIdx = pathColIdx(c);
        suffix = regexp(pathCol, "_(\d+)$", "tokens", "once");
        if isempty(suffix)
            error("Could not get suffix from path column: %s", pathCol);
        end
        suffix = suffix{1};
        keyword = "";
        if contains(pathCol, "selected_full")
            candidateFrameIDCols = [
                "selected_full_frameID_" + suffix
                "selected_full_frame_id_" + suffix
                ];
            keyword = "full";
        elseif contains(pathCol, "selected_att")
            candidateFrameIDCols = [
                "selected_att_frameID_" + suffix
                "selected_att_frame_id_" + suffix
                ];
            keyword = "att";
        else
            error("Unknown path column type: %s", pathCol);
        end

        frameIDIdx = [];
        for j = 1:numel(candidateFrameIDCols)
            frameIDIdx = find(headers == candidateFrameIDCols(j), 1, "first");
            if ~isempty(frameIDIdx)
                break;
            end
        end

        if isempty(frameIDIdx)
            error("Could not find matching frameID column for path column: %s", pathCol);
        end

        subIDIdx = find(headers == "subID", 1, "first");
        instanceIDIdx = find(headers == "instanceID", 1, "first");

        if isempty(subIDIdx)
            error('Could not find "subID" column.');
        end

        if isempty(instanceIDIdx)
            error('Could not find "instanceID" column.');
        end

        fprintf("Processing color info for column: %s\n", pathCol);

        colorVecColName = replace(pathCol, "_frame_path_", "_color_vector_");
        dominantColName = replace(pathCol, "_frame_path_", "_dominant_color_");

        colorVecColName = matlab.lang.makeValidName(colorVecColName);
        dominantColName = matlab.lang.makeValidName(dominantColName);

        % If these columns already exist, reuse them.
        % Otherwise, append them at the end.
        [rawOut, headers, colorVecOutCol, nextCol] = get_or_create_column( ...
            rawOut, headers, headerRow, colorVecColName, nextCol);

        [rawOut, headers, dominantOutCol, nextCol] = get_or_create_column( ...
            rawOut, headers, headerRow, dominantColName, nextCol);

        colorOutCols = zeros(numel(colorLabels), 1);

        for k = 1:numel(colorLabels)
            colorColName = replace(pathCol, "_frame_path_", "_" + colorLabels(k) + "_pct_");
            colorColName = matlab.lang.makeValidName(colorColName);

            [rawOut, headers, colorOutCols(k), nextCol] = get_or_create_column(...
                rawOut, headers, headerRow, colorColName, nextCol);
        end

        for r = dataRows
            subID = cell_to_string(rawOut{r, subIDIdx});
            instanceID = cell_to_string(rawOut{r, instanceIDIdx});
            frameID = cell_to_string(rawOut{r, frameIDIdx});
        
            imgPath = cell_to_string(rawOut{r, pathIdx});

            if ismissing(imgPath) || strlength(strtrim(imgPath)) == 0
                rawOut{r, colorVecOutCol} = "";
                rawOut{r, dominantOutCol} = "";

                for k = 1:numel(colorOutCols)
                    rawOut{r, colorOutCols(k)} = "";
                end
                continue;
            end

            if ~isfile(imgPath)
                warning("Image path does not exist: %s", imgPath);
                rawOut{r, colorVecOutCol} = "";
                rawOut{r, dominantOutCol} = "";
                for k = 1:numel(colorOutCols)
                    rawOut{r, colorOutCols(k)} = "";
                end
                continue;
            end

            [colorVec, colorClassMap] = get_image_color_vector(imgPath);

            [~, maxIdx] = max(colorVec);
            dominantColor = colorLabels(maxIdx);

            rawOut{r, colorVecOutCol} = color_vector_to_string(colorVec);
            rawOut{r, dominantOutCol} = dominantColor;
            for k = 1:numel(colorLabels)
                rawOut{r, colorOutCols(k)} = colorVec(k);
            end

            binnedImg = label2rgb(colorClassMap, palette, [1 0 1]);


            imgBaseName = string(subID) + "_cam07_" + ...
                string(instanceID) + "_" + ...
                string(frameID) + "_" + ...
                string(keyword);
            binnedDestPath = fullfile(colorImgDir, imgBaseName + "_color.jpg");

            imwrite(binnedImg, binnedDestPath);
        end
    end

    rawOut = clean_missing(rawOut);

    save(outFile, "rawOut", "-v7.3");

    fprintf("Saved color-enhanced original-format MAT file to: %s\n", outFile);
end

function [rawOut, headers, colIdx, nextCol] = get_or_create_column( ...
        rawOut, headers, headerRow, colName, nextCol)
    
    existingIdx = find(headers == string(colName), 1, "first");
    
    if ~isempty(existingIdx)
        colIdx = existingIdx;
        return;
    end
    
    colIdx = nextCol;
    
    if size(rawOut, 2) < colIdx
        rawOut(:, size(rawOut, 2)+1:colIdx) = {""};
    end
    
    rawOut{headerRow, colIdx} = string(colName);
    
    if numel(headers) < colIdx
        headers(1, numel(headers)+1:colIdx) = "";
    end
    
    headers(colIdx) = string(colName);
    
    nextCol = nextCol + 1;
end

function s = cell_to_string(x)
    if iscell(x)
        x = x{1};
    end
    
    if isempty(x)
        s = "";
    elseif isa(x, "missing")
        s = "";
    elseif isstring(x)
        if isscalar(x) && ismissing(x)
            s = "";
        else
            s = string(x);
        end
    elseif ischar(x)
        s = string(x);
    elseif isnumeric(x)
        if isscalar(x) && isnan(x)
            s = "";
        else
            s = string(x);
        end
    elseif iscategorical(x)
        if ismissing(x)
            s = "";
        else
            s = string(x);
        end
    else
        s = string(x);
    end
end

function M = cell_to_string_matrix(C)
    M = strings(size(C));
    
    for k = 1:numel(C)
        M(k) = cell_to_string(C{k});
    end
end

function s = color_vector_to_string(colorVec)
    s = "[" + join(compose("%.6f", colorVec), ",") + "]";
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

function [colorVec, colorClassMap] = get_image_color_vector(imgPath)
    
    [I, cmap, alpha] = imread(string(imgPath));
    
    I = im2double(I);
    HSV = rgb2hsv(I);
    H = HSV(:,:,1);
    S = HSV(:,:,2);
    V = HSV(:,:,3);
    
    colorClassMap = zeros(size(H), "uint8");
    
    % Gray 
    isGray = (V < 0.70 & V > 0.15) & S < 0.20;
    colorClassMap(isGray) = 10;
    
    % Black
    isBlack = (V < 0.15);
    colorClassMap(isBlack) = 9;
    
    % White
    isWhite = (V > 0.80 & S < 0.10);
    colorClassMap(isWhite) = 8;
    
    remaining = colorClassMap == 0;
    
    colorClassMap(remaining & (H < 0.03 | H >= 0.97)) = 1;  % Red
    colorClassMap(remaining & H >= 0.03 & H < 0.10) = 2;    % Orange
    colorClassMap(remaining & H >= 0.10 & H < 0.17) = 3;    % Yellow
    colorClassMap(remaining & H >= 0.17 & H < 0.42) = 4;    % Green
    colorClassMap(remaining & H >= 0.42 & H < 0.72) = 5;    % Blue
    colorClassMap(remaining & H >= 0.72 & H < 0.84) = 6;    % Purple
    colorClassMap(remaining & H >= 0.84 & H < 0.97) = 7;    % Pink
    
    counts = zeros(1, 10);
    
    for k = 1:10
        counts(k) = sum(colorClassMap(:) == k);
    end
    
    totalPixels = numel(H);
    
    colorVec = counts ./ totalPixels;
end

function sortedCols = sort_frame_path_cols(cols)   
    if isempty(cols)
        sortedCols = cols;
        return;
    end
    
    nums = nan(numel(cols), 1);
    types = strings(numel(cols), 1);
    
    for k = 1:numel(cols)
    
        col = string(cols(k));
    
        if contains(col, "selected_full")
            types(k) = "full";
        elseif contains(col, "selected_att")
            types(k) = "att";
        else
            types(k) = "other";
        end
    
        tok = regexp(col, "_(\d+)$", "tokens", "once");
    
        if isempty(tok)
            nums(k) = inf;
        else
            nums(k) = str2double(tok{1});
        end
    end
    
    % full columns first, then attended, each by frame number
    typeRank = zeros(numel(cols), 1);
    typeRank(types == "full") = 1;
    typeRank(types == "att") = 2;
    typeRank(types == "other") = 3;
    
    [~, order] = sortrows([typeRank, nums]);
    
    sortedCols = cols(order);
end