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
    if width(tbl) < 2
        error('Input table must have at least one column of data plus row labels.');
    end

    % Labels / names
    row_labels = ensure_cellstr(tbl{:,1}); % row labels from first column
    varnames   = tbl.Properties.VariableNames;
    col_names  = varnames(2:end);

    % Numeric matrix
    X = tbl{:, 2:end};
    if ~isnumeric(X)
        X = double(X);
    end

    % If you want: empty {} means "keep all" (your sentinel)
    % Here we interpret empty cell {} as keep all; otherwise apply filtering/aggregation.
    if isempty(col_list)
        col_list = {}; % keep all
    end
    if isempty(row_list)
        row_list = {}; % keep all
    end

    % --- Aggregate/filter columns (flat list filters; nested list aggregates) ---
    [Xc, new_col_names] = aggregate_columns(X, col_names, col_list);

    % --- Aggregate/filter rows ---
    [Xcr, new_row_labels] = aggregate_rows(Xc, row_labels, row_list);

    % Build output table
    out_tbl = array2table(Xcr, 'VariableNames', matlab.lang.makeValidName(new_col_names, 'ReplacementStyle','delete'));
    new_row_labels = new_row_labels(:);
    out_tbl = addvars(out_tbl, new_row_labels, 'Before', 1, 'NewVariableNames', varnames(1));
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


function [groupLabels, groups] = parse_groups(list)
% list can be:
%   {} or []          -> keep-all sentinel (handled outside)
%   {'a','b'}         -> non-grouped (groups are singletons)
%   {{'a','b'},{'c'}} -> grouped
%
% Returns:
%   groups: cell array, each element is a cellstr of member words
%   groupLabels: cellstr, label for each group (e.g., 'a,b')

    if isempty(list)
        groupLabels = {};
        groups = {};
        return
    end

    % Normalize input to cell
    if isstring(list), list = cellstr(list); end

    isNested = iscell(list) && ~isempty(list) && any(cellfun(@iscell, list));

    if ~isNested
        % Flat list: treat each item as its own group (no aggregation)
        s = ensure_cellstr(list);
        groups = arrayfun(@(i){s(i)}, 1:numel(s)); % singleton groups
        groupLabels = s;
    else
        % Nested list: each element is a group
        groups = cell(size(list));
        groupLabels = cell(size(list));
        for i = 1:numel(list)
            members = ensure_cellstr(list{i});
            groups{i} = members;
            groupLabels{i} = strjoin(members, ',');
        end
    end
end

function [Y, newNames] = aggregate_columns(X, oldNames, groupList)
% Aggregate columns of X according to groupList.
% groupList can be flat or nested (same conventions as parse_groups).

    [newNames, groups] = parse_groups(groupList);

    % If parse_groups returns empty (meaning list empty), keep all columns
    if isempty(newNames)
        Y = X;
        newNames = oldNames;
        return
    end

    oldNames = ensure_cellstr(oldNames);

    nR = size(X,1);
    nG = numel(groups);
    Y = nan(nR, nG);

    for g = 1:nG
        members = groups{g};
        [tf, loc] = ismember(members, oldNames);
        idx = loc(tf);

        if isempty(idx)
            % No member found → zeros
            Y(:,g) = zeros(nR,1);
        else
            block = X(:, idx);
        
            % Sum ignoring NaNs
            s = nansum(block, 2);
        
            % If all contributors were NaN, force 0 (instead of NaN)
            s(sum(~isnan(block), 2) == 0) = 0;
        
            Y(:,g) = s;
        end
    end
end

function [Y, newLabels] = aggregate_rows(X, oldLabels, groupList)
% Aggregate rows of X according to groupList.

    [newLabels, groups] = parse_groups(groupList);

    % Empty list => keep all rows
    if isempty(newLabels)
        Y = X;
        newLabels = oldLabels;
        return
    end

    oldLabels = ensure_cellstr(oldLabels);

    nC = size(X,2);
    nG = numel(groups);
    Y = nan(nG, nC);

    for g = 1:nG
        members = groups{g};
        [tf, loc] = ismember(members, oldLabels);
        idx = loc(tf);
        
        if isempty(idx)
            % No member found → zeros
            Y(g,:) = zeros(1,nC);
        else
            block = X(idx, :);
        
            s = nansum(block, 1);
        
            % Force 0 if all contributors were NaN
            s(sum(~isnan(block), 1) == 0) = 0;
        
            Y(g,:) = s;
        end
    end
end