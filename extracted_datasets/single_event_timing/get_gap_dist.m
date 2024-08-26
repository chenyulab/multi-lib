% Author: Ruchi Shah
 % Summary
    % This function outputs three files (of type specified by user in the
    % output_file argument (.csv recommended)) each containing a list of subjects
    % and the distribution of gaps of time window of variables.
    % 1) distribution of gaps between all categories
    % 2) distribution of gaps per category
    % 3) summation of gaps per category to category occurrences
    %
    % Arguments 
    % sub_expID
    %       -- supply an array of subject IDs or an experiment ID
    % num_cats
    %       -- number of categories for this experiment (include face if
    %       that is a valid category
    % var_name
    %       -- The variable of interest to determine distribution of gaps between
    % output_filename
    %       -- string filename for output file
    % args
    %       -- struct with two optional fields: bins_matrix and rois
    %       -- args.bins_matrix: a matrix of time ranges
    %       -- args.rois: a list of rois
    %       -- args.gap_def: definition of gap, between offset of current and
    %       onset of next or onset of current and onset of next
    %       -- args.outs: output 
function get_gap_dist(sub_expID, num_cats, var_name, output_filename, args) 
     if ~exist('args', 'var') || isempty(args)
         args = struct();
     end
     if ~isfield(args, 'bins_matrix')
         defined_bins = [0 0.5;
             0.5 1;
             1 1.5;
             1.5 2;
             2 realmax('double')];
         disp('Set bins to default.');
     else
         defined_bins = args.bins_matrix;
     end

     % used to find occurences that contain any of the rois and
     % calc gaps between these rois
     if isfield(args, 'rois')
         rois = args.rois;
         num_cats = length(rois);
     else 
         rois = {-1};
     end

     if isfield(args, 'gap_def') && isequal(args.gap_def,['onset', 'onset'])
         gap_def = [1 1];
         
     else
         gap_def = [2 1];
     end 

% Variables
    subIDs = cIDs(sub_expID);
    if isempty(subIDs)
         disp("ERROR: experiment does not exist or there are no subjects in this experiment.")
        return;
    end
    sub_col = subIDs;
    num_bins = size(defined_bins, 1);
    bin_names = cell(1, num_bins);
    for i = 1:num_bins
        bin_names{i} = strcat('(', num2str(defined_bins(i,1)), '-', num2str(defined_bins(i,2)), ')');
    end
    disp(bin_names)

    % access variable of interest for each subject
    mat = zeros(length(subIDs), height(defined_bins), 'double');
    
    sub_cat_col = {};
    mat_category_wise = zeros(length(subIDs) * num_cats, height(defined_bins), 'double');

    for i = 1:numel(subIDs)
        
        try
            sub_var_data = get_variable(subIDs(i), var_name);
        catch
            disp("ERROR: subject does not have variable.")
        end

        % cat_wise
        temp_mat = zeros(num_cats, height(defined_bins), 'double');
        for cat = 1: num_cats
            sub_cat_col{end+1} = subIDs(i);
            
            if rois{1} == -1
                category = {cat};
            else
                category = {rois{cat}};
            end
            data = key_roi_data(sub_var_data, category);
            if isempty(data)  || height(data) == 1
                % set all bin counts for this category to zero
                temp_mat(cat, :) = zeros(1, length(bin_names));
            end
            subTimes = {};
            % get times of each roi
            for j = 1:height(data)
                t = data(j, :);
                t1 = t(1);
                t2 = t(2);
                times = [t1,t2];
                subTimes{end+1} = times;
            end 
    
            for j = 1:(length(subTimes) - 1)
                time_e = subTimes{j};
                time_s = subTimes{j+1};
                time_off = time_e(gap_def(1));  % start of gap
                time_on_next = time_s(gap_def(2));  % end of gap
                gap = time_on_next - time_off;
                col = 1;
                for k = 1:height(defined_bins)
                    % get bin gap belongs to if any at all
                    if gap > defined_bins(k,1) && gap <= defined_bins(k,2)
                        temp_mat(cat, col) = temp_mat(cat, col) + 1;
                        break;
                    end 
                    col = col + 1;
                end
            end
        end
        start_index = (i-1) * num_cats + 1;
        end_index = start_index + num_cats - 1;
        mat_category_wise(start_index:end_index, :) = temp_mat;


        data = key_roi_data(sub_var_data, rois);
        subTimes = {};
        % get times of each roi
        for j = 1:height(data)
            t = data(j, :);
            t1 = t(1);
            t2 = t(2);
            times = [t1,t2];
            subTimes{end+1} = times;
        end 

        for j = 1:(length(subTimes) - 1)
            time_e = subTimes{j};
            time_s = subTimes{j+1};
            time_off = time_e(gap_def(1));  % start of gap
            time_on_next = time_s(gap_def(2));  % end of gap
            gap = time_on_next - time_off;
            col = 1;
            for k = 1:height(defined_bins)
                % get bin gap belongs to if any at all
                if gap > defined_bins(k,1) && gap <= defined_bins(k,2)
                    mat(i, col) = mat(i, col) + 1;
                    break;
                end 
                col = col + 1;
            end
        end
    end

    % output table creation
    mat = horzcat(sub_col, mat);
    T = array2table(mat);
    vars = horzcat({'subID'}, bin_names);
    T.Properties.VariableNames = vars;
    writetable(T, output_filename)
    output_filename = split(output_filename, ".");
   
    % Output table creation for category_wise
    % Add ROI column
    sub_cat_col = cell2mat(sub_cat_col)';

    roi_col = cell(size(sub_cat_col, 1), 1);
    if isfield(args, 'rois') && ~isempty(args.rois)
        % Flatten args.rois
        flattened_rois = [args.rois{:}];
        rois_sequence = repmat(flattened_rois, 1, ceil(numel(sub_cat_col) / length(flattened_rois)));
        rois_sequence = rois_sequence(1:numel(sub_cat_col));
    else
        rois_sequence = repmat(1:num_cats, 1, ceil(numel(sub_cat_col) / num_cats));
        rois_sequence = rois_sequence(1:numel(sub_cat_col));
    end
    for i = 1:numel(sub_cat_col)
        roi_col{i} = rois_sequence(i);
    end
    roi_col = cell2mat(roi_col);

    mat_cat_start = horzcat(sub_cat_col, roi_col);
    mat_category_wise = horzcat(mat_cat_start, mat_category_wise);
    T_category_wise = array2table(mat_category_wise);
    vars = horzcat({'subID'}, {'ROI'}, bin_names);
    T_category_wise.Properties.VariableNames = vars;
    
    % Write the table to a file for category_wise
    output_filename_category_wise = split(output_filename, ".");
    writetable(T_category_wise, strcat(output_filename_category_wise{1}, "_cat_wise.csv"));
    
    % sum the category-wise table
    % sums each column based on subID
    sumT = varfun(@sum, T_category_wise, 'InputVariables', bin_names, 'GroupingVariables', 'subID'); 
    sumT.GroupCount = [];
    for i = 1:length(bin_names)
        sumT.Properties.VariableNames{end - length(bin_names) + i} = bin_names{i};
    end
    
    writetable(sumT, strcat(output_filename{1}, "_summed.csv"));

end
