function [data] = key_roi_data(sub_var_data, rois)
    if rois{1}== -1
        data = sub_var_data;
        return;
    end
    len_rois = length(rois);
    data = [];
    for i = 1:height(sub_var_data)
        for k = 1:len_rois
            if sub_var_data(i,3) == rois{k}
                data = vertcat(data,sub_var_data(i,:));
                break;
            end 
        end
    end 
end

