%%%
% Author: Jingwen Pang
% Date: 6/16/2025
% 
% This function takes a speech file (any level), and the column indices for category ID, subject ID, and utterance. It generates a category × unique word matrix:
% Each cell indicates how often a word appears with an object.
% Outputs include an overall sheet and row-level sheets, grouped according to input csv.
% 
%% 
function count_cat2word_freq(input_csv,sub_col,cat_col,utt_col,output_excel,args)

    % check if there is optional parameters
    if ~exist('args', 'var') || isempty(args)
        args = struct([]);
    end

    if isfield(args, 'instance_col')
        instance_col = args.instance_col;
    else
        instance_col = 0;
    end
    
    output_file = output_excel;
    
    data = readtable(input_csv);
    
    % find expID base on the subID_list
    sub_list = table2array(unique(data(:,sub_col)));
    expID = unique(sub2exp(sub_list));
    
    if numel(expID) ~= 1
        error('please make sure all the subjects come from a single experiment');
    end

    % ---------- Lexicon (IDs & words) ----------
    lexicon          = get_exp_word_list(expID);     % Nx2: [id, word]
    unique_word_ids  = lexicon(:, 1);
    disp(unique_word_ids)
    % unique_word_ids_raw = unique_word_ids;
    unique_words     = lexicon(:, 2);
    max_id                   = max(cell2mat(unique_word_ids));

    % Build word->id map (case-insensitive)
    vocab_map = containers.Map('KeyType', 'char', 'ValueType', 'double');
    for k = 1:numel(unique_words)
        key = unique_words{k};
        vocab_map(key) = unique_word_ids{k};
    end

    disp(vocab_map)

    % ---------- Categories & labels ----------
    % cat_list = sort(unique(data{:, cat_col}));
    num_obj = get_num_obj(expID);
    cat_list = [1:num_obj];
    labels = get_object_label(expID,cat_list)';


    % Mark bad labels (uppercase tokens)
    bad = contains(string(labels), "UNKNOWN") | ...
    contains(string(labels), "ERROR")   | ...
    contains(string(labels), "INVALID_LABEL");

    labels   = labels(~bad);
    cat_list = cat_list(~bad);
    
    % ---------- Preallocate overall ----------
    overall_matrix = zeros(numel(cat_list), max_id, 'double');
    overall_counts = zeros(numel(cat_list), 1);


    % ---------- Helpers ----------
    normalize_text = @(s) normalize_utt(s);

    % initialize freq table, overall freq matrix
    freq_table = {};
    overall_matrix = zeros(length(cat_list),length(unique_words));
    sheet_list = [0, sub_list'];
    
    count_list = zeros(size(cat_list,2),1);
    
    % ---------- Row-wise counting: overall ----------
    for i = 1:height(data)
        cat_val = data{i, cat_col};
        cat_idx = find(cat_list == cat_val, 1);
        if isempty(cat_idx), continue; end

        utt = data{i, utt_col};
        if ismissing(utt) || (ischar(utt) && isempty(utt)) || (isstring(utt) && strlength(utt) == 0)
            if instance_col == 0
                overall_counts(cat_idx) = overall_counts(cat_idx) + 1;
            else
                overall_counts(cat_idx) = overall_counts(cat_idx) + data{i, instance_col};
            end
            continue;
        end

        tokens = tokenize_to_ids(normalize_text(utt), vocab_map);
        if isempty(tokens), continue; end
        % Count ids in this utterance and add to overall
        % tokens are valid ids in [1..max_id]
        per_row_counts = accumarray(tokens(:), 1, [max_id, 1], @sum, 0);
        overall_matrix(cat_idx, :) = overall_matrix(cat_idx, :) + per_row_counts.';
        if instance_col == 0
            overall_counts(cat_idx)    = overall_counts(cat_idx) + 1;
        else
            overall_counts(cat_idx)    = overall_counts(cat_idx) + data{i,instance_col};
        end
    end
    
    % ---------- Build overall sheet ----------
    headers = [{'cat_label'}, unique_words', {'total_instance'}];
overall_table = cell2table( ...
    horzcat(labels, num2cell(overall_matrix), num2cell(overall_counts)), ...
    "VariableNames", headers);
    
    % Store in cell array
    freq_table = cell(1 + numel(sub_list), 1);
    sheet_list = [0; sub_list];      % index 1 = overall, 2..end = subs
    freq_table{1} = overall_table;
    
    
    % ---------- Subject-level ----------
    for s = 1:numel(sub_list)
        sub_id   = sub_list(s);
        sub_data = data(data{:, sub_col} == sub_id, :);

        sub_matrix = zeros(numel(cat_list), max_id, 'double');
        sub_counts = zeros(numel(cat_list), 1);

        for i = 1:height(sub_data)
            cat_val = sub_data{i, cat_col};
            cat_idx = find(cat_list == cat_val, 1);
            if isempty(cat_idx), continue; end

            utt = sub_data{i, utt_col};
            if ismissing(utt) || (ischar(utt) && isempty(utt)) || (isstring(utt) && strlength(utt) == 0)
                if instance_col == 0
                    sub_counts(cat_idx) = sub_counts(cat_idx) + 1;
                else
                    sub_counts(cat_idx) = sub_counts(cat_idx) + sub_data{i, instance_col};
                end
                continue;
            end

            tokens = tokenize_to_ids(normalize_text(utt), vocab_map);

            if isempty(tokens), continue; end

            per_row_counts = accumarray(tokens(:), 1, [max_id, 1], @sum, 0);
            sub_matrix(cat_idx, :) = sub_matrix(cat_idx, :) + per_row_counts.';
            if instance_col == 0
                sub_counts(cat_idx)    = sub_counts(cat_idx) + 1;
            else
                sub_counts(cat_idx)    = sub_counts(cat_idx) + sub_data{i,instance_col};
            end
        end

        sub_table = cell2table( ...
    horzcat(labels, num2cell(sub_matrix), num2cell(sub_counts)), ...
    "VariableNames", headers);

        % Place at position s+1 (aligned with sheet_list)
        freq_table{s + 1} = sub_table;
    end
    
    
    % Delete existing file to remove default Sheet1
    if exist(output_file, 'file')
        delete(output_file);
        fprintf('Deleted existing file: %s\n', output_file);
    end
    
    for i = 1:length(freq_table)
        data = freq_table{i};
        subject_id = sheet_list(i);
    
        % Create sheet name
        if subject_id == 0
            sheetName = 'overall';
        else
            sheetName = sprintf('%d', subject_id);
        end
    
        % Debug info
        fprintf('Writing to sheet: %s\n', sheetName);
    
        % Write only if data is non-empty
        if ~isempty(data) && width(data) > 0
            writetable(data, output_file, ...
                'Sheet', sheetName);  % R2020a+
        else
            warning('Sheet %s is empty. Skipping.', sheetName);
        end
    end

end



function s = normalize_utt(s)
    if isstring(s), s = char(s); end
    s = strrep(s, ';', '');
    % Replace non-letters/digits/apostrophes/hyphens with space (keeps common word forms)
    s = regexprep(s, '\s+', ' ');
    s = strtrim(s);

    s = s{1}; % remove cell
end


function ids = tokenize_to_ids(utt, vocab_map)
    if isempty(utt)
        ids = [];
        return;
    end
    toks = strsplit(utt, ' ');
    ids  = zeros(1, numel(toks));
    n    = 0;
    for k = 1:numel(toks)
        tk = toks{k};
        if isempty(tk), continue; end
        if isKey(vocab_map, tk)
            n = n + 1;
            ids(n) = vocab_map(tk);
        end
        % Unknown words are ignored
    end
    ids = ids(1:n);
end