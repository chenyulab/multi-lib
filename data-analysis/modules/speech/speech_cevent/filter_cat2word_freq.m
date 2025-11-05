%%%
% Author: Jingwen Pang
% Date: 8/14/2025
% Remap row/column labels in a word matrix to a provided word list.
% - Missing words -> created and filled with 0 (placeholders)
% - Nested groups (e.g., {{'a','b'}, 'c'}) -> per-row SUM columns (e.g., a_b, c)
% - Preserves first column (cat label) and, if present, the 'total_instance' column at the end
%%%
function filter_cat2word_freq(input_file, output_file, word_list)

    [~, ~, ext] = fileparts(input_file);
    ext = lower(ext);

    switch ext
        case '.csv'
            data = readtable(input_file, 'PreserveVariableNames', true);
            filtered_data = process_table(data, word_list);
            writetable(filtered_data, output_file);

        case '.xlsx'
            [~, sheetNames] = xlsfinfo(input_file);
            if isempty(sheetNames)
                error('No sheets found in "%s".', input_file);
            end
            for i = 1:numel(sheetNames)
                sheet = sheetNames{i};
                disp(['Processing sheet: ' sheet]);
                data = readtable(input_file, 'Sheet', sheet, 'PreserveVariableNames', true);
                filtered_data = process_table(data, word_list);
                writetable(filtered_data, output_file, 'Sheet', sheet, 'WriteMode', 'overwritesheet');
            end

        otherwise
            error('Unsupported file type: %s', ext);
    end
end

function filtered_data = process_table(data, word_list)
    wl = normalize_word_list(word_list);
    isNested = any(cellfun(@iscell, wl)); % determine if it is nested cell

    % ---- Identify metadata columns under the new layout ----
    % Left meta: first column (cat label)
    meta_left = data(:, 1);

    % Right meta: try to find 'total_instance' by (case-insensitive) name
    vnames = data.Properties.VariableNames;
    lower_names = lower(vnames);
    ti_idx = find(strcmp(lower_names, 'total_instance'), 1, 'first');

    % Build the main block = all columns excluding left meta and total_instance (if found)
    keep_out = 1;
    if ~isempty(ti_idx)
        keep_out = [keep_out, ti_idx];
    end
    main_cols = setdiff(1:width(data), keep_out, 'stable');
    main_block = data(:, main_cols);

    if ~isNested
        % Flat list -> select columns in order, create 0-filled placeholders
        main = extract_word_matrix_zero(main_block, wl);
        if ~isempty(ti_idx)
            meta_right = data(:, ti_idx);
            filtered_data = [meta_left, main, meta_right];
        else
            filtered_data = [meta_left, main];
        end
        return;
    end

    % Nested: groups -> row-wise SUM column; singles -> single column
    parts = {};
    for i = 1:numel(wl)
        item = wl{i};
        if iscell(item)
            sub = extract_word_matrix_zero(main_block, item); % N x K
            y   = sum(table2array(sub), 2);                   % N x 1 sum
            gname = make_group_name(item);                    % e.g., a_b
            parts{end+1} = array2table(y, 'VariableNames', {gname}); %#ok<AGROW>
        else
            sub = extract_word_matrix_zero(main_block, {item}); % N x 1
            parts{end+1} = sub; %#ok<AGROW>
        end
    end

    % Safety check (all N rows)
    N = height(meta_left);
    assert(all(cellfun(@height, parts) == N), 'Row mismatch across parts.');
    
    % --- NEW: uniquify column names across parts ---
    part_names = cellfun(@(t) t.Properties.VariableNames{1}, parts, 'UniformOutput', false);
    part_names_unique = make_unique_after_valid(part_names);
    for i = 1:numel(parts)
        parts{i}.Properties.VariableNames = {part_names_unique{i}};
    end
    
    main_out = horzcat(parts{:});

    if ~isempty(ti_idx)
        meta_right = data(:, ti_idx);
        filtered_data = [meta_left, main_out, meta_right];
    else
        filtered_data = [meta_left, main_out];
    end
end

% Returns ONLY the selected word columns from the provided MAIN block.
% 'main_block' should already exclude metadata columns.
function selected = extract_word_matrix_zero(main_block, word_list)
    % Keep original labels
    target_raw = cellstr(string(word_list(:)));
    % Drop empty/whitespace-only items
    target_raw = target_raw(~cellfun(@(s) isempty(s) || all(isspace(s)), target_raw));

    N = height(main_block);

    % If nothing left, return an empty table with N rows (0 variables)
    if isempty(target_raw)
        selected = table('Size', [N 0], 'VariableTypes', {}, 'VariableNames', {});
        return;
    end

    % Convert to valid names, make unique (car, car_2, ...)
    target_names = make_unique_after_valid(target_raw);

    % For lookup against existing main_block headers (validize only)
    main_names   = main_block.Properties.VariableNames;
    lookup_valid = matlab.lang.makeValidName(target_raw, 'ReplacementStyle', 'underscore');

    [tf, loc] = ismember(lookup_valid, main_names);

    cols = cell(1, numel(target_names));
    for k = 1:numel(target_names)
        if tf(k)
            tmp = main_block(:, loc(k));
            tmp.Properties.VariableNames = {target_names{k}};
            cols{k} = tmp;
        else
            cols{k} = array2table(zeros(N,1), 'VariableNames', {target_names{k}});
        end
    end

    % If cols is empty (defensive), still return N×0 table
    if isempty(cols)
        selected = table('Size', [N 0], 'VariableTypes', {}, 'VariableNames', {});
    else
        selected = horzcat(cols{:});
    end
end


function name = make_group_name(words)
    words = cellstr(string(words(:)));
    joined = strjoin(words, ',');
    name = matlab.lang.makeValidName(joined);
end

function out = normalize_word_list(wl)
    % Accept char, string, cellstr, or nested cell-of-cells; return top-level cell
    if isstring(wl), wl = cellstr(wl); end
    if ~iscell(wl),  wl = {wl};        end
    out = wl;
end

function uniqueNames = make_unique_after_valid(baseNames)
% Ensure valid, unique MATLAB variable names.
% - baseNames: cellstr of desired labels (original words or group names)
% - Returns names that are valid and unique, using suffixes _2, _3, ...
%
% First occurrence: 'car'     -> 'car'
% Second occurrence:          -> 'car_2'
% Third occurrence:           -> 'car_3', etc.

    % 1) Make valid (preserve "original header initially" as much as possible)
    valid = matlab.lang.makeValidName(baseNames, 'ReplacementStyle', 'underscore');

    % 2) De-duplicate with custom counters (start suffix at _2)
    uniqueNames = valid;
    seen = containers.Map('KeyType','char','ValueType','double');
    for i = 1:numel(valid)
        name = valid{i};
        if isKey(seen, name)
            cnt = seen(name) + 1;
            seen(name) = cnt;
            uniqueNames{i} = sprintf('%s_%d', name, cnt);
        else
            seen(name) = 1;   % first time: keep as-is
            uniqueNames{i} = name;
        end
    end
end