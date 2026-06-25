function image_GBVS_profile(inputMat)

    if ~isfile(inputMat)
        error("Input file %s doesn't exist", inputMat);
    end

    [folder, name, ext] = fileparts(inputMat);
    if ~isfolder(folder)
        error("Output directory %s doesn't exist", folder);
    end

    
    gbvsImgDir = fullfile(folder, "gbvs_images");
    outputMat = fullfile(folder, name + "_gbvs" + ext);

    if ~isfolder(gbvsImgDir); mkdir(gbvsImgDir); end
    
    if ~isfile(inputMat); error("Input file doesn't exist: %s", inputMat); end
    
    S = load(inputMat);
    rawOut = S.rawOut;

    rawStr = cell_to_string_matrix(rawOut);
    rawStrClean = strtrim(erase(rawStr, "#"));

    hasExpID = any(rawStrClean == "expID", 2);
    headerRow = find(hasExpID, 1, "first");
    if isempty(headerRow); error("Could not find a row containing 'expID'");end

    headers = rawStrClean(headerRow, :);
    isHeaderNonEmpty = strlength(strtrim(headers)) > 0 & ~ismissing(headers);
    lastCol = find(isHeaderNonEmpty, 1, "last");

    headers = headers(1:lastCol);

    for j = 1:lastCol
        rawOut{headerRow, j} = headers{j};
    end

    fullPathMask = startsWith(headers, "selected_full_frame_path_");
    fullPathCols = headers(fullPathMask);
    if isempty(fullPathCols); error("No selected_full_frame_path_ columns found.");end

    isHeaderNonEmpty = strlength(strtrim(headers)) > 0 & ~ismissing(headers);
    nextCol = find(isHeaderNonEmpty, 1, "last") + 1;

    dataRows = headerRow + 1 : size(rawOut, 1);

    subIDIdx = find(headers == "subID", 1, "first");
    instanceIDIdx = find(headers == "instanceID", 1, "first");
    if isempty(subIDIdx); error("Could not find 'subID' column."); end
    if isempty(instanceIDIdx); error("Could not find 'instanceID' column.");end
    
    for c = 1:numel(fullPathCols)
        pathCol = fullPathCols(c);
        pathIdx = find(headers == pathCol, 1, "first");

        suffix = extractAfter(pathCol, "selected_full_frame_path_");

        candidateFrameIDCols = [
            "selected_full_frame_id_" + suffix
            "selected_full_frameID_" + suffix
        ];

        frameIDIdx = [];
        for j = 1:numel(candidateFrameIDCols)
            frameIDIdx = find(headers == candidateFrameIDCols(j), 1, "first");
            if ~isempty(frameIDIdx); break; end
        end

        if isempty(frameIDIdx); warning("Missing frame ID columns for %s", pathCol); continue;end

        fprintf("Processing %s\n", pathCol);
        
        for r = dataRows
            fullPath = cell_to_string(rawOut{r, pathIdx});
            frameID = cell_to_double(rawOut{r, frameIDIdx});
    
            if ismissing(fullPath) || strlength(strtrim(fullPath)) == 0 || ~isfile(fullPath) || isnan(frameID)
                continue;
            end
    
            subID = cell_to_double(rawOut{r, subIDIdx});
            instanceID = cell_to_string(rawOut{r, instanceIDIdx});

            if isnan(subID); warning("Missing or invalid subID on row %d", r);
                continue;
            end

            subjectDir = get_subject_dir(subID);
            numObj = get_num_obj(subID);

            boxesFile = fullfile(subjectDir, "extra_p", sprintf("%d_child_boxes.mat",subID));
            if ~isfile(boxesFile); warning("Missing boxes fil for subject %d", subID); continue; end

            B = load(boxesFile);
            boxData = B.box_data;
            boxFrameIDs = [boxData.frame_id];
            boxRow = find(boxFrameIDs == frameID, 1);

            if isempty(boxRow); warning("Box row is empty for frame %d", frameID); continue; end
            
            fullImg = imread(fullPath);
            gbvsOut = gbvs(fullImg);
            salMap = double(gbvsOut.master_map_resized);

            imgBaseName = string(subID) + "_cam07_" + ...
                string(instanceID) + "_" + ...
                string(frameID);

            % gbvsMapFile = fullfile(gbvsImgDir, imgBaseName + "_gbvs_map.jpg");
            % imwrite(mat2gray(gbvsOut.master_map_resized), gbvsMapFile);

            gbvsOverlayFile = fullfile(gbvsImgDir, imgBaseName + "_gbvs_overlay.jpg");
            fig = figure("Visible", "off");
            show_imgnmap(fullImg, gbvsOut);
            title("GBVS map overlayed");
            exportgraphics(gca, gbvsOverlayFile);
            close(fig);

            totalSal = sum(salMap(:));

            if totalSal == 0 || isnan(totalSal);warning("Total saliency is either 0 or NaN");continue;end

            for obj = 1:numObj
                outColName = "gbvs_obj_" + obj + "_saliency_" + suffix;

                [rawOut, headers, outColIdx, nextCol] = get_or_create_column(...
                    rawOut, headers, headerRow, outColName, nextCol);

                % objFolder = fullfile(subjectDir, ...
                %     "cam07_attended-objs-frames_p", ...
                %     "obj_" + obj);
                % 
                % if ~isfolder(objFolder)
                %     rawOut{r, outColIdx} = 0;
                %     continue;
                % end
                % 
                % objFramePattern = "*" + string(frameID) + "*";
                % objFrameFiles = dir(fullfile(objFolder, objFramePattern));
                % 
                % if isempty(objFrameFiles)
                %     rawOut{r, outColIdx} = 0;
                %     continue;
                % end

                bbox = boxData(boxRow).post_boxes(obj, :);
                if any(isnan(bbox)) || all(bbox == 0)
                    rawOut{r, outColIdx} = 0;
                    continue;
                end

                mask = bbox_to_mask(bbox, size(salMap));
                objSal = sum(salMap(mask));

                rawOut{r, outColIdx} = objSal / totalSal;
            end   
        end
    end
    rawOut = clean_missing(rawOut);
    save(outputMat, "rawOut", "-v7.3");
    fprintf("Saved GBVS original-format MAT file to: %s\n", outputMat);
end

function mask = bbox_to_mask(bbox, salMapSize)
    mask = false(salMapSize);

    H = salMapSize(1);
    W = salMapSize(2);

    cx = bbox(1) * W;
    cy = bbox(2) * H;
    w = bbox(3) * W;
    h = bbox(4) * H;

    x1 = max(1, floor(cx - w/2) + 1);
    y1 = max(1, floor(cy - h/2) + 1);
    x2 = min(W, ceil(cx + w/2));
    y2 = min(H, ceil(cy + h/2));

    if x1>x2 || y1>y2
        return;
    end

    mask(y1:y2, x1:x2) = true;
end

function s = cell_to_string(x)
    if iscell(x); x = x{1}; end
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

function [rawOut, headers, colIdx, nextCol] = get_or_create_column(...
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

function d = cell_to_double(x)
    if iscell(x) 
        x = x{1};
    end
    
    if isempty(x)
        d = NaN;
    elseif isnumeric(x)
        if isscalar(x)
            d = double(x);
        else
            d = NaN;
        end
    else
        s = cell_to_string(x);
        if ismissing(s) || strlength(strtrim(s)) == 0
            d = NaN;
        else
            d = str2double(s);
        end
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







        



