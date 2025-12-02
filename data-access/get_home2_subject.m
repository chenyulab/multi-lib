% This function compares cross-activity visit patterns among subjects for 
% experiments in the 350-series. It reads the file *350_multi-visit.xlsx* 
% to obtain each subject's visiting records and the mapping of visits across activities.
% 
% Author: Jingwen Pang
% Date: 12/1/2025
% 
% INPUT:
% expIDs – A single experiment ID (e.g., 351) or an array of experiment IDs 
% (e.g., [351 353]). Only IDs in the 350-series are supported.
% 
% OUTPUT:
% visit_mat – A numeric matrix where:
% • Each entry is the subject ID for that visit.
% • Missing or unusable visits are returned as NaN.
% 
% FUNCTION BEHAVIOR:
% 
% • When a single experiment ID is provided, the function returns a table of 
% visit IDs for all 4 possible visits for that activity. If a subject does not 
% have a valid visit for a specific visit number, that entry is filled with NaN.
% 
% Example:
% expIDs = 351;
% Output:
% 35101 35109 NaN 35115
% 35102 NaN NaN 35120
% Interpretation:
% - Kid 1 has valid visits 1, 2, and 4. Visit 3 is missing/unusable.
% - Kid 2 has valid visits 1 and 4; Visits 2–3 are missing/unusable.
% 
% • When multiple experiment IDs are provided, the function aligns subjects 
% across the activities and returns one column per activity.
% 
% Example:
% expIDs = [351 353];
% Output:
% 35101 35301
% 35109 35308
% 35115 35314
% 35102 35302
% Interpretation:
% - Each row represents a visit index.
% - The kid in this visit attended all activities
% - Columns represent the corresponding visit ID for each activity.
% 
% NOTES:
% Currently supports only experiments in the 350-series.
function rtr_matrix = get_home2_subject(expIDs)

    mapping_file = 'multi-visit_exp-mapping.xlsx';
    mapping_path = fullfile(get_multidir_root,mapping_file);
    mapping_data = readtable(mapping_path);
    
    visit_list = 1:4;
    
    exp2main = containers.Map(mapping_data.expID,mapping_data.mainExpID);
    
    flag = 1; % 1 - single case; 2 - multiple case
    
    try
        % check if the expID is valid
        if isnumeric(expIDs) && isscalar(expIDs) % single case
            mainExpID = exp2main(expIDs);
        else % multiple case
            mainExpID = unique(arrayfun(@(x) exp2main(x),expIDs));
            if ~isscalar(mainExpID)
                disp('ERROR: multiple mainExpIDs are detected!')
                return
            end
            flag = 2;
        end
    
    catch ME
        disp('ERROR: The expID is not in the mapping file, check the expID')
        return
    end
    
    exp_data_path = fullfile(get_multidir_root,sprintf('%d_multi-visit_subject-id.xlsx',mainExpID));
    
    data = readtable(exp_data_path);
    
    headers = data.Properties.VariableNames;
    
    if flag == 1
        idx = contains(headers, num2str(expIDs));
        rtr_matrix = table2array(data(:,idx));
        rtr_matrix = rtr_matrix(~all(isnan(rtr_matrix),2),:); % remove rows where every element is NaN
    else
        rtr_matrix = [];
        for i = visit_list
            sub_matrix = [];
            for exp = expIDs
                label = sprintf('v%d_%d',i,exp);
                idx = contains(headers,label);
                sub_matrix = [sub_matrix,table2array(data(:,idx))];
            end
            rtr_matrix = [rtr_matrix;sub_matrix];
        end
        rtr_matrix = rtr_matrix(~any(isnan(rtr_matrix), 2), :); % remove rows where every element is NaN
    
    end



end