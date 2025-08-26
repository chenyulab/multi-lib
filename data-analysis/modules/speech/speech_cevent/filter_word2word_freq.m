%%%
% Author: Jingwen Pang
% Date: 8/22/2025
% Remap row/column labels in a word matrix to match a provided word list.
% 
% Inputs:
%   Input_file
%   output_file
%   row_word_list: word list that filter row headers
%   col_word_list: word list that filter column headers
% 
% 
% Output:
% A remapped word matrix where the header aligns exactly with the word list; other words in the input file will be removed.
% If a word in the list is missing in the word matrix, its column/row will be filled with NaN.
%%%
function filter_word2word_freq(input_file, output_file, row_word_list, col_word_list)
    
    if nargin < 4
         col_word_list = row_word_list;  % reuse the same list for rows
    end

    % Helper to normalize inputs: {} -> keep all; [] -> keep all
    col_list = normalize_list(col_word_list);
    row_list = normalize_list(row_word_list);

    [~, ~, ext] = fileparts(input_file);

    switch lower(ext)
        case '.csv'
            tbl = readtable(input_file, 'PreserveVariableNames', true);
            out_tbl = subset_matrix_table(tbl, col_list, row_list);
            writetable(out_tbl, output_file);

        case '.xlsx'
            [~, sheetNames] = xlsfinfo(input_file);
            if isempty(sheetNames)
                error('No sheets found in "%s".', input_file);
            end
            for i = 1:numel(sheetNames)
                sheet = sheetNames{i};
                data = readtable(input_file, 'Sheet', sheet, 'PreserveVariableNames', true);
                out_tbl = subset_matrix_table(data, col_list, row_list);
                % For the first sheet, overwrite; for subsequent sheets, append
                if i == 1
                    writetable(out_tbl, output_file, 'Sheet', sheet);
                else
                    writetable(out_tbl, output_file, 'Sheet', sheet, 'WriteMode', 'overwritesheet');
                end
            end

        otherwise
            error('Unsupported file type: %s', ext);
    end
end


function list = normalize_list(in_list)
    % Convert [] to {}, pass through {}, leave other cell arrays unchanged.
    if isempty(in_list)
        list = {};  % keep-all sentinel
    else
        list = in_list;
    end
end

function out_tbl = subset_matrix_table(tbl, col_list, row_list)
    % tbl: first column = row labels; other columns = words (variables)

    if width(tbl) < 2
        error('Input table must have at least one column of data plus row labels.');
    end

    % Extract labels
    row_labels = tbl{:,1};                     % could be cellstr, string, numeric, categorical
    varnames   = tbl.Properties.VariableNames; % includes first label column
    data_names = varnames(2:end);              % only word columns

    % subset columns
    if ~isempty(col_list)  % non-empty cell => subset columns
        % Ensure cellstr of desired order
        col_list = ensure_cellstr(col_list);
        % Find indices in the existing columns, keeping the order of col_list
        col_idx = locate_in_order(data_names, col_list);
        data_keep_names = data_names(col_idx);
    else
        data_keep_names = data_names; % keep all
    end

    % subset rows
    if ~isempty(row_list)
        row_list = ensure_cellstr(row_list);
        row_labels_str = ensure_cellstr(row_labels);
        row_idx = locate_in_order(row_labels_str, row_list);
        tbl_rows = tbl(row_idx, :);
    else
        tbl_rows = tbl; % keep all
    end

    % Rebuild table: first column (labels) + selected columns (in requested order)
    out_tbl = tbl_rows(:, [1, 1 + find(ismember(data_names, data_keep_names))]);

    % Reorder selected data columns to match the requested order exactly
    % (since ismember preserves existing order, we explicitly reorder here)
    if ~isempty(col_list)
        % Current order of data columns in out_tbl (excluding first label col)
        current_data_names = out_tbl.Properties.VariableNames(2:end);
        % Target order
        [~, reorder_idx] = ismember(col_list, current_data_names);
        reorder_idx = reorder_idx(reorder_idx > 0);
        out_tbl = out_tbl(:, [1, 1 + reorder_idx]);
    end
end

function s = ensure_cellstr(x)
    % Convert various label types to a cell array of char vectors
    if iscell(x)
        if isstring(x)
            s = cellstr(x);
        else
            % ensure everything is char
            s = cellfun(@tochar, x, 'UniformOutput', false);
        end
    elseif isstring(x)
        s = cellstr(x);
    elseif iscategorical(x)
        s = cellstr(string(x));
    elseif isnumeric(x) || islogical(x)
        s = cellstr(string(x));
    else
        s = cellstr(string(x));
    end
end

function c = tochar(v)
    if ischar(v)
        c = v;
    else
        c = char(string(v));
    end
end

function idx = locate_in_order(existing_names, desired_names)
    % Return indices in existing_names that match desired_names, preserving the
    % order of desired_names and skipping names not found.
    [tf, loc] = ismember(desired_names, existing_names);
    idx = loc(tf);
end