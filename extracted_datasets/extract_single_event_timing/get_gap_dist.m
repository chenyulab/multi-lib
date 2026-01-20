% Author: Ruchi Shah
 % Summary
    % This function outputs three csv files each containing a list of subjects
    % and the distribution of gaps of time window of variables.
    % 1) distribution of gaps between all categories
    % 2) distribution of gaps per category
    % 3) summation of gaps per category to category occurrences
    %
    % Arguments 
    % subexpid
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
    %       -- args.time_bins: a matrix of time ranges
    %       -- args.cats: a list of categories
    %       -- args.gap_def: definition of gap, between offset of current and
    %       onset of next or onset of current and onset of next
    %
    % NOTE: look at demo_get_gap_dist for more help

function get_gap_dist(subexpid, num_cats, var_name, output_filename, args)
    if ~exist('args', 'var') || isempty(args)
        args = struct();
    end

    if isfield(args, 'by_trial') && (args.by_trial)
        get_gap_by_trial(subexpid, num_cats, var_name, output_filename, args)
        
        return;
    end
    
    % Set default bins if not provided.
    if ~isfield(args, 'time_bins')
        defined_bins = [0    0.5;
                        0.5  1;
                        1    1.5;
                        1.5  2;
                        2    Inf];
    else
        defined_bins = args.time_bins;
    end
    
    % ROIs if provided.
    if isfield(args, 'cats')
        rois = args.cats;
        num_cats = length(rois);
    else 
        rois = {-1};  
    end
    
    % Determine gap definition.
    if isfield(args, 'gap_def') && isequal(args.gap_def, ['onset', 'onset'])
        gap_def = [1 1];  % (onset of current, onset of next)
    else
        gap_def = [2 1];  % (offset of current, onset of next) by default
    end 
    
    subIDs = cIDs(subexpid);
    if isempty(subIDs)
        disp("ERROR: experiment does not exist or there are no subjects in this experiment.");
        return;
    end
    sub_col = subIDs;  
    
    num_bins = size(defined_bins, 1);
    bin_names = cell(1, num_bins);
    for i = 1:num_bins
        bin_names{i} = strcat('(', num2str(defined_bins(i,1)), '-', num2str(defined_bins(i,2)), ')');
    end
    
    % Initialize matrices
    mat = zeros(length(subIDs), num_bins);     
    mat_category_wise = zeros(length(subIDs) * num_cats, num_bins);
    sub_cat_col = {};
    
    for i = 1:numel(subIDs)
        try
            sub_var_data = get_variable_by_trial_cat(subIDs(i), var_name, 1);
            trials = unique(sub_var_data(:, end));
        catch
            disp(['ERROR: subject ' num2str(subIDs(i)) ' does not have variable.']);

            % Fill with NaNs for missing subject
            mat(i, :) = NaN;
            start_index = (i - 1) * num_cats + 1;
            end_index = start_index + num_cats - 1;
            mat_category_wise(start_index:end_index, :) = NaN;
            
            for cat = 1:num_cats
                sub_cat_col{end+1} = subIDs(i);
            end

            continue;
        end
        
        % Category-wise gap computations
        
        temp_mat = zeros(num_cats, num_bins);
        for cat = 1:num_cats
            sub_cat_col{end+1} = subIDs(i);
            
            if rois{1} == -1
                category = {cat};
            else
                category = {rois{cat}};
            end
            
            % Extract data for an ROI.
            data = key_roi_data(sub_var_data, category);
            if isempty(data)
                continue;
            end
            
            % by trial.
            for trl = 1:length(trials)
                trial = trials(trl);
                trial_data = data(data(:, end) == trial, :);
                if size(trial_data, 1) < 2
                    continue;  % Need at least two data points for a gap.
                end
                
                subTimes = cell(1, size(trial_data, 1));
                for j = 1:size(trial_data, 1)
                    t = trial_data(j, :);
                    subTimes{j} = [t(1), t(2)];
                end
                
                % Compute gaps within this trial.
                for j = 1:(length(subTimes) - 1)
                    time_e = subTimes{j};
                    time_s = subTimes{j+1};
                    gap = time_s(gap_def(2)) - time_e(gap_def(1));
                    
                    % Place gap into its bin.
                    for k = 1:num_bins
                        % lower bound excluded, upper bound included
                        if gap > defined_bins(k,1) && gap <= defined_bins(k,2)
                            temp_mat(cat, k) = temp_mat(cat, k) + 1;
                            break;
                        end
                    end
                end
            end
        end
        
        % category-wise counts.
        start_index = (i - 1) * num_cats + 1;
        end_index = start_index + num_cats - 1;
        mat_category_wise(start_index:end_index, :) = temp_mat;
        
        % Overall across ROI
        all_data = key_roi_data(sub_var_data, rois);
        if isempty(all_data)
            continue;
        end
        
        % trial processing.
        for trl = 1:length(trials)
            trial = trials(trl);
            trial_data = all_data(all_data(:, end) == trial, :);
            if size(trial_data, 1) < 2
                continue;
            end
            
            subTimes = cell(1, size(trial_data, 1));
            for j = 1:size(trial_data, 1)
                t = trial_data(j, :);
                subTimes{j} = [t(1), t(2)];
            end
            
            for j = 1:(length(subTimes) - 1)
                time_e = subTimes{j};
                time_s = subTimes{j+1};
                gap = time_s(gap_def(2)) - time_e(gap_def(1));
                for k = 1:num_bins
                    if gap > defined_bins(k,1) && gap <= defined_bins(k,2)
                        mat(i, k) = mat(i, k) + 1;
                        break;
                    end
                end
            end
        end
    end 
    
    % Output overall gap distribution
    overall_mat = [num2cell(sub_col(:)), num2cell(mat)];
    T = cell2table(overall_mat, 'VariableNames', [{'subID'}, bin_names]);
    writetable(T, output_filename);
    disp(['Overall gap distribution file written to: ' output_filename]);

    
    % Output category-wise gap distribution.
    sub_cat_col_vec = cell2mat(sub_cat_col(:));
    roi_col = zeros(length(sub_cat_col_vec), 1);
    if isfield(args, 'cats') && ~isempty(args.cats)
        flattened_rois = [args.cats{:}];
        rois_sequence = repmat(flattened_rois, 1, ceil(length(sub_cat_col_vec) / length(flattened_rois)));
        rois_sequence = rois_sequence(1:length(sub_cat_col_vec));
        roi_col = rois_sequence(:);
    else
        rois_sequence = repmat(1:num_cats, 1, ceil(length(sub_cat_col_vec) / num_cats));
        roi_col = rois_sequence(1:length(sub_cat_col_vec))';
    end
    cat_wise_mat = [num2cell(sub_cat_col_vec), num2cell(roi_col), num2cell(mat_category_wise)];
    T_category_wise = cell2table(cat_wise_mat, 'VariableNames', [{'subID'}, {'cat'}, bin_names]);
    
    % Output category-wise table.
    [filepath, name, ~] = fileparts(output_filename);
    cat_wise_filename = fullfile(filepath, [name, '_cat_wise.csv']);
    writetable(T_category_wise, cat_wise_filename);
    disp(['Category-wise gap distribution file written to: ' cat_wise_filename]);

    
    
    % Output summed category-wise gap counts by subject.
    sumT = varfun(@sum, T_category_wise, 'InputVariables', bin_names, 'GroupingVariables', 'subID');
    if ismember('GroupCount', sumT.Properties.VariableNames)
        sumT.GroupCount = [];
    end
    for k = 1:num_bins
        sumT.Properties.VariableNames{end - num_bins + k} = bin_names{k};
    end
    
    summed_filename = fullfile(filepath, [name, '_cat_wise_summed.csv']);
    writetable(sumT, summed_filename);
    disp(['Summed category-wise gap distribution file written to: ' summed_filename]);
end



function [data] = key_roi_data(sub_var_data, rois)
    if rois{1} == -1 % all cats
        data = sub_var_data;
        return;
    end

    % find only cats specified and trial match
    try
        match = ismember(sub_var_data(:, 3), [rois{:}]);
    catch
        match = [];
    end

    data = sub_var_data(match, :);
end

function get_gap_by_trial(sub_expID, num_cats, var_name, output_filename, args)
    % Set defaults
    if ~exist('args','var') || isempty(args)
        args = struct();
    end
    if ~isfield(args, 'time_bins')
        defined_bins = [0    0.5;
                        0.5  1;
                        1    1.5;
                        1.5  2;
                        2    Inf];
    else
        defined_bins = args.time_bins;
    end
    if isfield(args, 'rois')
        rois = args.rois;
        num_cats = length(rois);
    else
        rois = {-1};
    end
    if isfield(args, 'gap_def') && isequal(args.gap_def, ['onset','onset'])
        gap_def = [1 1];
    else
        gap_def = [2 1];
    end
    
    subIDs = cIDs(sub_expID);
    if isempty(subIDs)
        disp('ERROR: experiment does not exist or there are no subjects.');
        return;
    end
    
    num_bins = size(defined_bins,1);
    bin_names = cell(1,num_bins);
    for i = 1:num_bins
        bin_names{i} = strcat('(', num2str(defined_bins(i,1)), '-', num2str(defined_bins(i,2)), ')');
    end

    overall_rows = {};
    category_rows = {};
    
    % Loop through subjects
    for s = 1:length(subIDs)
        sub_id = subIDs(s);
        try
            sub_var_data = get_variable_by_trial_cat(sub_id, var_name, 1);
            trials = unique(sub_var_data(:, end));

        catch
            disp(['ERROR: subject ' num2str(sub_id) ' does not have variable.']);
            continue;
        end
        % Get trial from the last column.
        % across ROIs
        all_data = key_roi_data(sub_var_data, rois);
        
        % Process each trial separately.
        for t = 1:length(trials)
            trial_num = trials(t);
            
            % Overall gap counts for this trial.
            trial_all_data = all_data(all_data(:, end) == trial_num, :);
            overall_gap_counts = zeros(1, num_bins);
            if size(trial_all_data,1) >= 2
                subTimes = cell(size(trial_all_data,1), 1);
                for j = 1:size(trial_all_data,1)
                    tdata = trial_all_data(j, :);
                    subTimes{j} = [tdata(1), tdata(2)];
                end
                for j = 1:(length(subTimes)-1)
                    gap = subTimes{j+1}(gap_def(2)) - subTimes{j}(gap_def(1));
                    for k = 1:num_bins
                        if gap > defined_bins(k,1) && gap <= defined_bins(k,2)
                            overall_gap_counts(k) = overall_gap_counts(k) + 1;
                            break;
                        end
                    end
                end
            end
            newRow = cell(1, 2+num_bins);
            newRow{1} = sub_id;
            newRow{2} = trial_num;
            for b = 1:num_bins
                newRow{2+b} = overall_gap_counts(b);
            end
            overall_rows = [overall_rows; newRow];  
            
            % Category-wise gap counts for this trial.
            for cat = 1:num_cats
                if rois{1} == -1
                    category = {cat};
                else
                    category = {rois{cat}};
                end
                data_cat = key_roi_data(sub_var_data, category);
                trial_cat_data = data_cat(data_cat(:, end) == trial_num, :);
                cat_gap_counts = zeros(1, num_bins);
                if size(trial_cat_data,1) >= 2
                    subTimes = cell(size(trial_cat_data,1), 1);
                    for j = 1:size(trial_cat_data,1)
                        tdata = trial_cat_data(j, :);
                        subTimes{j} = [tdata(1), tdata(2)];
                    end
                    for j = 1:(length(subTimes)-1)
                        gap = subTimes{j+1}(gap_def(2)) - subTimes{j}(gap_def(1));
                        for k = 1:num_bins
                            if gap > defined_bins(k,1) && gap <= defined_bins(k,2)
                                cat_gap_counts(k) = cat_gap_counts(k) + 1;
                                break;
                            end
                        end
                    end
                end
                newRow = cell(1, 3+num_bins);
                newRow{1} = sub_id;
                newRow{2} = trial_num;
                if rois{1} == -1
                    newRow{3} = cat;
                else
                    newRow{3} = rois{cat};
                end
                for b = 1:num_bins
                    newRow{3+b} = cat_gap_counts(b);
                end
                category_rows = [category_rows; newRow]; 
            end
        end
    end

    %  --- Trial-Level Files --- 
    % Overall Trial-Level
    [filepath, name, ~] = fileparts(output_filename);
    overall_header = [{'subID','trial'}, bin_names];
    T_overall = cell2table(overall_rows, 'VariableNames', overall_header);
    trial_overall_filename = fullfile(filepath, [name, '_trial_overall.csv']);
    
    % Category-wise Trial-Level
    category_header = [{'subID','trial','cat'}, bin_names];
    T_category = cell2table(category_rows, 'VariableNames', category_header);
    trial_cat_filename = fullfile(filepath, [name, '_trial_cat_wise.csv']);

    % Summed Category-wise Trial-Level 
    T_category_sum = varfun(@sum, T_category, 'InputVariables', bin_names, 'GroupingVariables', {'subID','trial'});
    if ismember('GroupCount', T_category_sum.Properties.VariableNames)
        T_category_sum.GroupCount = [];
    end

    for k = 1:num_bins
        T_category_sum.Properties.VariableNames{end - num_bins + k} = bin_names{k};
    end
    trial_summed_filename = fullfile(filepath, [name, '_trial_summed.csv']);

    if isfield(args, 'by_trial') && (args.by_trial)
        writetable(T_overall, trial_overall_filename);
        disp(['Overall trial-level file written to: ' trial_overall_filename]);
        writetable(T_category, trial_cat_filename);
        disp(['Category-wise trial-level file written to: ' trial_cat_filename]);
        writetable(T_category_sum, trial_summed_filename);
        disp(['Summed trial-level file written to: ' trial_summed_filename]);
    end
    
    % --- Without Trial Information ---
    % % Overall  
    % T_agg_overall = varfun(@sum, T_overall, 'InputVariables', bin_names, 'GroupingVariables', 'subID');
    % if ismember('GroupCount', T_agg_overall.Properties.VariableNames)
    %     T_agg_overall.GroupCount = [];
    % end
    % for k = 1:num_bins
    %     T_agg_overall.Properties.VariableNames{end - num_bins + k} = bin_names{k};
    % end
    % agg_overall_filename = fullfile(filepath, [name, '_agg_overall.csv']);
    % writetable(T_agg_overall, agg_overall_filename);
    % disp(['Overall aggregated file written to: ' agg_overall_filename]);
    % 
    % % Category-wise
    % T_agg_cat = varfun(@sum, T_category, 'InputVariables', bin_names, 'GroupingVariables', {'subID','cat'});
    % if ismember('GroupCount', T_agg_cat.Properties.VariableNames)
    %     T_agg_cat.GroupCount = [];
    % end
    % for k = 1:num_bins
    %     T_agg_cat.Properties.VariableNames{end - num_bins + k} = bin_names{k};
    % end
    % agg_cat_filename = fullfile(filepath, [name, '_agg_cat_wise.csv']);
    % writetable(T_agg_cat, agg_cat_filename);
    % disp(['Category-wise aggregated file written to: ' agg_cat_filename]);
    % 
    % % Summed Category-wise 
    % T_agg_summed = varfun(@sum, T_category_sum, 'InputVariables', bin_names, 'GroupingVariables', 'subID');
    % if ismember('GroupCount', T_agg_summed.Properties.VariableNames)
    %     T_agg_summed.GroupCount = [];
    % end
    % for k = 1:num_bins
    %     T_agg_summed.Properties.VariableNames{end - num_bins + k} = bin_names{k};
    % end
    % agg_summed_filename = fullfile(filepath, [name, '_agg_summed.csv']);
    % writetable(T_agg_summed, agg_summed_filename);
    % disp(['Summed aggregated file written to: ' agg_summed_filename]);
end