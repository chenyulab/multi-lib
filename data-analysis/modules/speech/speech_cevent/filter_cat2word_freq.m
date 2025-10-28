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
    target_raw   = word_list(:);
    target_names = matlab.lang.makeValidName(target_raw);  % desired output names

    % Existing data headers in the main block
    main_names = main_block.Properties.VariableNames;

    [tf, loc] = ismember(target_names, main_names);
    N = height(main_block);
    cols = cell(1, numel(target_names));

    for k = 1:numel(target_names)
        if tf(k)
            % Take existing column but rename to the desired target name (normalize)
            tmp = main_block(:, loc(k));
            tmp.Properties.VariableNames = {target_names{k}};
            cols{k} = tmp;
        else
            % Missing -> zero-filled placeholder with desired name
            cols{k} = array2table(zeros(N,1), 'VariableNames', {target_names{k}});
        end
    end

    selected = horzcat(cols{:});
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
