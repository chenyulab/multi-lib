function obj_labels = get_object_label(exp_id, obj_ids)
% Author: Jingwen Pang
% Date: 08/16/2025
%
% key_exp_list = [12, 15, 27, 58, 65, 66, 67, 68, 69, 77, 78, 79, 96, 351, 353, 361, 362, 363];
% Given exp_id & object ids, return aligned labels from the dictionary.
% - For scalar input: returns a char/string ('' if missing).
% - For vector/matrix input: returns a cell array the same size as obj_ids,
%   with '' as placeholder when an id has no label.

    obj_id_col   = 3;
    obj_name_col = 1;

    % Exps whose object id is in column 5
    special_exps = [6,14,17,18,22,23,29,32,34,35,36,39,41,42,43,44,49,53,54,55,56,59,62,63,70,71,72,73,74,90];
    if ismember(exp_id, special_exps)
        obj_id_col = 5;
    end

    try
        dirp = fullfile(get_multidir_root(), sprintf('experiment_%d', exp_id));
        filename = sprintf('exp_%d_dictionary.xlsx', exp_id);
        T = readtable(fullfile(dirp, filename));

        ids   = T{:, obj_id_col};
        names = T{:, obj_name_col};

        % Normalize names -> cellstr
        if isstring(names)
            names = cellstr(names);
        elseif ischar(names)
            names = cellstr(names);
        elseif ~iscell(names)
            names = cellstr(string(names));
        end
        % Trim whitespace
        names = cellfun(@strtrim, names, 'UniformOutput', false);

        orig_sz = size(obj_ids);
        ids_vec = obj_ids(:);
        out_vec = cell(numel(ids_vec), 1);  % filled per element

        for k = 1:numel(ids_vec)
            oid = ids_vec(k);

            % Guard: skip non-numeric/non-string IDs cleanly
            if ~(isnumeric(oid) || isstring(oid) || ischar(oid))
                out_vec{k} = sprintf('<UNKNOWN:%s>', id2str(oid));
                continue;
            end

            idx = (ids == oid);
            if any(idx)
                lbls = names(idx);

                % Remove empties after trim
                is_empty = cellfun(@(c) isempty(c) || all(isspace(c)), lbls);
                lbls = lbls(~is_empty);

                if isempty(lbls)
                    % ID present but label(s) empty -> INVALID_LABEL: ID
                    out_vec{k} = sprintf('INVALID_LABEL:%s', id2str(oid));
                else
                    out_vec{k} = strjoin(lbls, '/');
                end
            else
                % ID not in dictionary at all
                out_vec{k} = sprintf('<UNKNOWN:%s>', id2str(oid));
            end
        end

        out = reshape(out_vec, orig_sz);

        if isscalar(obj_ids)
            obj_labels = out{1};
        else
            obj_labels = out;
        end

    catch ME
        disp(ME.message);
        if isscalar(obj_ids)
            obj_labels = '<ERROR>';
        else
            obj_labels = repmat({'<ERROR>'}, size(obj_ids));
        end
    end

    % ---- helper: robust ID -> string ----
    function s = id2str(v)
        if isnumeric(v) && isscalar(v) && isfinite(v)
            if mod(v,1)==0
                s = sprintf('%d', v);
            else
                s = sprintf('%.6g', v);
            end
        else
            s = char(string(v));
        end
    end
end
