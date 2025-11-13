function words_out = get_object_words(exp_id, obj_ids)
% Author: Jingwen Pang
% Date: 10/10/2025
%
% Given exp_id & object ids, return aliases/words from object_word_pairs.xlsx.
% - For scalar input: returns a 1×K cell array of words ({} if missing).
% - For vector/matrix input: returns a cell array same size as obj_ids,
%   with each cell a 1×K cell array of words ({} if no match).
%
% Expected columns (case-insensitive, flexible):
%   - id column:   one of {'obj_id','object_id','id'}
%   - word column: one of {'name','word','alias'}
%
% Notes:
%   - Empty/whitespace-only names are removed.
%   - Duplicates removed, original order preserved.
%   - If file missing or error: returns {'<ERROR>'} for scalar, or a cell
%     array of {'<ERROR>'} for each element.

    try
        % -------- locate file --------
        dirp = fullfile(get_multidir_root(), sprintf('experiment_%d', exp_id));
        filename = 'object_word_pairs.xlsx';
        T = readtable(fullfile(dirp, filename));

        % -------- find columns by (case-insensitive) header names --------
        id_col   = find_first_var(T, {'obj_id','object_id','id'});
        word_col = find_first_var(T, {'name','word','alias'});

        if isempty(id_col) || isempty(word_col)
            error('Required columns not found: need an id and a word/name/alias column.');
        end

        ids_raw   = T{:, id_col};
        words_raw = T{:, word_col};

        % Normalize words to cellstr and trim
        if isstring(words_raw)
            words_raw = cellstr(words_raw);
        elseif ischar(words_raw)
            words_raw = cellstr(words_raw);
        elseif ~iscell(words_raw)
            words_raw = cellstr(string(words_raw));
        end
        words_raw = cellfun(@strtrim, words_raw, 'UniformOutput', false);

        % Normalize ids column type checks
        ids_is_numeric = isnumeric(ids_raw);

        % Prepare outputs
        orig_sz = size(obj_ids);
        ids_vec = obj_ids(:);
        out_vec = cell(numel(ids_vec), 1);

        % For stable iteration order, keep table row order
        for k = 1:numel(ids_vec)
            oid = ids_vec(k);

            % match rows for this id
            if ids_is_numeric
                % Try to coerce oid -> double for numeric compare
                key = NaN;
                if isnumeric(oid) && isscalar(oid) && isfinite(oid)
                    key = double(oid);
                elseif isstring(oid) || ischar(oid)
                    key = str2double(string(oid));
                end
                if isnan(key)
                    idx = false(size(ids_raw));
                else
                    idx = (double(ids_raw) == key);
                end
            else
                % Treat ids as strings for compare
                ids_str = string(ids_raw);
                key = string(oid);
                idx = (ids_str == key);
            end

            if any(idx)
                cand = words_raw(idx);

                % remove empties
                is_empty = cellfun(@(c) isempty(c) || all(isspace(c)), cand);
                cand = cand(~is_empty);

                % de-duplicate preserving order
                cand = unique_stable(cand);

                % ensure row orientation (1×K)
                cand = reshape(cand, 1, []);

                % final assignment
                out_vec{k} = cand;     % cand is a 1×K cellstr; may be {}
            else
                % No mapping -> empty list
                out_vec{k} = {};
            end
        end

        % reshape
        out = reshape(out_vec, orig_sz);

        if isscalar(obj_ids)
            words_out = out{1};  % 1×K cell array (possibly {})
        else
            words_out = out;     % same size as obj_ids, each cell is 1×K cell array
        end

    catch ME
        disp(ME.message);
        if isscalar(obj_ids)
            words_out = {'<ERROR>'};
        else
            words_out = repmat({{'<ERROR>'}}, size(obj_ids));
        end
    end

    % ------- helpers -------
    function idx = find_first_var(tbl, candidates)
        vn = string(tbl.Properties.VariableNames);
        cand = string(lower(candidates));
        vn_lower = lower(vn);
        pos = [];
        for ci = 1:numel(cand)
            hit = find(vn_lower == cand(ci), 1, 'first');
            if ~isempty(hit)
                pos = hit;
                break;
            end
        end
        if isempty(pos)
            idx = [];
        else
            idx = pos;
        end
    end

    function out = unique_stable(c)
        % c is 1×N cellstr
        % Return unique values preserving first occurrence order
        [~, ia] = unique(c, 'stable');
        out = c(sort(ia));
    end
end
