% Author: Ruchi Shah
function [data] = key_roi_data(sub_var_data, rois)
    if rois{1} == -1 % all cats
        data = sub_var_data;
        return;
    end

    % find only cats specified
    match = ismember(sub_var_data(:, 3), [rois{:}]);
    data = sub_var_data(match, :);
end

