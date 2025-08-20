function count_word2word_freq(input_csv, utt_col, sub_col, cat_col, output_dir, args)
% Author: Jingwen Pang
% Date: 2025-08-20
%
% For each ROW:
%   - Tokenize utterance, map tokens to word IDs via experiment lexicon
%   - Build V x (V+2) co-occurrence matrix
%   - Save "subID_catID.csv"
% Aggregates:
%   - Sum across rows per subject -> "subID.csv"
%   - Sum across rows per category -> "cat-<catID>.csv"
%   - Sum across all rows -> "<expID>_all.csv"
%
% Required columns: utt_col (utterance), sub_col (subject id), cat_col (category id)
% Optional args: args.exp_col (default: 2)

    % --------- Args & setup ---------
    if ~exist('args','var') || isempty(args), args = struct(); end
    if ~isfield(args,'exp_col'), args.exp_col = 2; end

    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
        fprintf('Created folder: %s\n', output_dir);
    end

    T = readtable(input_csv);

    % --------- Experiment id ---------
    exp_ids = unique(T{:, args.exp_col});
    if numel(exp_ids) ~= 1
        error('Please ensure all rows belong to a single experiment. Found: %s', mat2str(exp_ids));
    end
    exp_id = exp_ids(1);

    % --------- Vocabulary (IDs & words) ---------
    % Expect get_exp_word_list(exp_id) -> Nx2 cell: [id, word]
    lexicon    = get_exp_word_list(exp_id);
    word_ids   = lexicon(:,1);
    word_terms = lexicon(:,2);

    % Convert id cell -> numeric vector (robust)
    if iscell(word_ids)
        wid = cellfun(@(x) double(x), word_ids);
    else
        wid = double(word_ids);
    end
    max_id = max(wid);

    % Map WORD (exact form) -> ID (no case conversion)
    word2id = containers.Map('KeyType','char','ValueType','double');
    V = numel(word_terms);
    for i = 1:V
        term = word_terms{i};
        word2id(term) = wid(i);
    end

    % Build id->term (1..max_id), fill missing with id_x labels
    id2term = strings(max_id,1);
    for i = 1:V
        if wid(i) >= 1 && wid(i) <= max_id
            id2term(wid(i)) = string(word_terms{i});
        end
    end
    for i = 1:max_id
        if id2term(i) == ""
            id2term(i) = sprintf('id_%d', i);
        end
    end

    headers_words = cellstr(id2term);  % 1..max_id
    headers = [{'words_col'}, headers_words', {'word_freq','word_pair_freq'}];

    % --------- Accumulators ---------
    overall = zeros(max_id, max_id + 2, 'double');

    % Subject and category aggregators
    subAgg = containers.Map('KeyType','double','ValueType','any');   % subID -> matrix
    catAgg = containers.Map('KeyType','double','ValueType','any');   % catID -> matrix

    % Warn each unknown token once
    warned_unknown = containers.Map('KeyType','char','ValueType','logical');

    % --------- Process each row -> write one CSV ---------
    nrows = height(T);
    for r = 1:nrows
        disp(r)
        utter = T{r, utt_col};
        subID = double(T{r, sub_col});
        catID = double(T{r, cat_col});

        % Normalize utterance
        utt = normalize_utt_(utter);

        % Tokenize -> word IDs (warn & skip if not in experiment list)
        ids = tokenize_to_ids_warn_(utt, word2id, warned_unknown);

        % Build individual matrix (even if empty)
        indiv = zeros(max_id, max_id + 2, 'double');

        if ~isempty(ids)
            % Count frequency of each ID in this utterance
            per_counts = accumarray(ids(:), 1, [max_id, 1], @sum, 0);  % max_id x 1

            present_ids = find(per_counts > 0);
            for k = 1:numel(present_ids)
                g  = present_ids(k);         % word ID (1..max_id)
                tf = per_counts(g);          % term frequency in this utterance

                % Diagonal: self-pairs
                indiv(g, g) = indiv(g, g) + max(tf - 1, 0);
                % Single word count
                indiv(g, end-1) = indiv(g, end-1) + tf;

                % Co-occurrence with others:
                others = present_ids(present_ids ~= g);
                if ~isempty(others)
                    indiv(g, others) = indiv(g, others) + tf;
                end

                % Total pair freq (including self-pairs)
                indiv(g, end) = indiv(g, end) + tf * numel(others) + max(tf - 1, 0);
            end
        end

        % Write row-level CSV: "subID_catID.csv"
        row_name = fullfile(output_dir, sprintf('%d_%d.csv', subID, catID));
        row_tbl  = cell2table([cellstr(id2term), num2cell(indiv)], 'VariableNames', headers);
        writetable(row_tbl, row_name);
        % fprintf('Wrote: %s\n', row_name);

        % Accumulate into overall
        overall = overall + indiv;

        % Accumulate into subject-level
        if ~isKey(subAgg, subID)
            subAgg(subID) = zeros(max_id, max_id + 2, 'double');
        end
        subAgg(subID) = subAgg(subID) + indiv;

        % Accumulate into category-level
        if ~isKey(catAgg, catID)
            catAgg(catID) = zeros(max_id, max_id + 2, 'double');
        end
        catAgg(catID) = catAgg(catID) + indiv;
    end

    % --------- Write overall ---------
    overall_tbl  = cell2table([cellstr(id2term), num2cell(overall)], 'VariableNames', headers);
    overall_name = fullfile(output_dir, sprintf('exp-%d_all.csv', exp_id));
    writetable(overall_tbl, overall_name);

    % --------- Write subject aggregates ---------
    subKeys = cell2mat(keys(subAgg));
    for i = 1:numel(subKeys)
        sid = subKeys(i);
        M   = subAgg(sid);
        sub_tbl  = cell2table([cellstr(id2term), num2cell(M)], 'VariableNames', headers);
        sub_name = fullfile(output_dir, sprintf('%d.csv', sid));  % subject: subID.csv
        writetable(sub_tbl, sub_name);
    end

    % --------- Write category aggregates ---------
    catKeys = cell2mat(keys(catAgg));
    for i = 1:numel(catKeys)
        cid = catKeys(i);
        M   = catAgg(cid);
        cat_tbl  = cell2table([cellstr(id2term), num2cell(M)], 'VariableNames', headers);
        cat_name = fullfile(output_dir, sprintf('cat-%d.csv', cid));  % category: cat-catID.csv
        writetable(cat_tbl, cat_name);
    end
end

% ===================== Helpers =====================

function s = normalize_utt_(s)
    % Convert to char, strip semicolons, collapse spaces, trim.
    if iscell(s),   s = s{1}; end
    if isstring(s), s = char(s); end
    if isempty(s),  s = ''; return; end
    s = strrep(s, ';', '');
    s = regexprep(s, '\s+', ' ');
    s = strtrim(s);
end

function ids = tokenize_to_ids_warn_(utt, word2id, warned_unknown)
    if isempty(utt)
        ids = [];
        return;
    end
    toks = strsplit(utt, ' ');
    ids = zeros(1, numel(toks));
    n   = 0;
    for i = 1:numel(toks)
        tk = toks{i};
        if isempty(tk), continue; end
        if isKey(word2id, tk)
            n = n + 1;
            ids(n) = word2id(tk);
        else
            if ~isKey(warned_unknown, tk)
                warned_unknown(tk) = true;
                warning('Skipping word "%s": not in experiment word list.', tk);
            end
        end
    end
    ids = ids(1:n);
end
