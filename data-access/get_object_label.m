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
        dirp = fullfile(get_multidir_root(), sprintf('experiment_%d', exp_id)); % <-- () added
        filename = sprintf('exp_%d_dictionary.xlsx', exp_id);
        T = readtable(fullfile(dirp, filename));

        ids   = T{:, obj_id_col};
        names = T{:, obj_name_col};

        % Normalize names to a cellstr
        if isstring(names)
            names = cellstr(names);
        elseif ischar(names)
            names = cellstr(names); % char matrix -> cellstr by row
        elseif ~iscell(names)
            names = cellstr(string(names));
        end

        orig_sz   = size(obj_ids);
        ids_vec   = obj_ids(:);
        out_vec   = repmat({''}, numel(ids_vec), 1);  % default placeholders

        for k = 1:numel(ids_vec)
            oid = ids_vec(k);

            % Skip non-numeric gracefully
            if ~(isnumeric(oid) || (isstring(oid) && strlength(oid) > 0))
                out_vec{k} = '';
                continue;
            end

            idx = (ids == oid);
            if any(idx)
                lbls = names(idx);

                % ensure cellstr & drop empties
                if isstring(lbls), lbls = cellstr(lbls); end
                if ischar(lbls),  lbls = cellstr(lbls);  end
                lbls = lbls(:);
                lbls = lbls(~cellfun(@isempty, lbls));

                if isempty(lbls)
                    out_vec{k} = '';
                else
                    out_vec{k} = strjoin(lbls, '/');
                end
            else
                out_vec{k} = '';  % <-- placeholder when no dictionary entry
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
            obj_labels = '';
        else
            obj_labels = repmat({''}, size(obj_ids));
        end
    end
end
