function [valid_ids, valid_labels] = get_valid_object_ids(expid)
    n = get_num_obj(expid);                 % e.g., 34 for exp 362
    ids = 1:n;
    labels = get_object_label(expid, ids);  % 1 x n cell

    % mark unknowns
    is_unknown = cellfun(@(s) ...
        isempty(s) || startsWith(s, '<UNKNOWN:'), labels);

    valid_ids = ids(~is_unknown);
    valid_labels = labels(~is_unknown);
end