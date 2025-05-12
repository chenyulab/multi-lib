% Author: Ruchi Shah
 % Summary
    % This function outputs a file (of type specified by user in the
    % output_file argument (.csv) containing a list of
    % subjects with instances of a specified variable and the gap duration
    % between them per category
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
    %       -- struct with two optional fields: cats and gap_def
    %       -- args.cats: a list of categories
    %       -- args.gap_def: definition of gap, between offset of current and
    %       onset of next or onset of current and onset of next
    %
    % NOTE: look at demo_get_gap_instance for more help
    

function get_gap_instance(subexpid, num_cats, var_name, output_filename, args)
    % set defaults
    if nargin < 5 || isempty(args)
        args = struct();
    end

    if isfield(args, 'cats')
        rois = args.cats;
        num_cats = length(rois);
    else
        rois = {-1};  
    end

    
    if isfield(args, 'gap_def') && isequal(args.gap_def, ['onset','onset'])
        gap_def = [1, 1];  
    else
        gap_def = [2, 1];  % Default: offset-onset.
    end

    subIDs = cIDs(subexpid);
    if isempty(subIDs)
        error('No subjects found.');
    end

    instance_rows_roi = {};  % For ROIoutput.
    instance_rows_all = {};  % For aggregated output.

    for i = 1:length(subIDs)
        subID = subIDs(i);
        try
            sub_var_data = get_variable_by_trial_cat(subID, var_name, 1);
            trials = unique(sub_var_data(:, end));
        catch
            disp(['ERROR: subject ' num2str(subID) ' does not have the variable.']);
            continue;
        end

        
        for t = 1:length(trials)
            trial_val = trials(t);
            % Filter the data by trial.
            trial_data = sub_var_data(sub_var_data(:, end) == trial_val, :);

            % Aggregated output
            trial_data_sorted = sortrows(trial_data, 1);
            num_events = size(trial_data_sorted, 1);
            % we need at least two events for a gap.
            if num_events >= 2
                for j = 1:(num_events - 1)
                    inst1_on = trial_data_sorted(j, 1);
                    inst1_off = trial_data_sorted(j, 2);
                    inst2_on = trial_data_sorted(j+1, 1);
                    inst2_off = trial_data_sorted(j+1, 2);
                    inst1_cat = trial_data_sorted(j, 3);
                    inst2_cat = trial_data_sorted(j+1, 3);
                    if gap_def(1) == 2
                        t1 = inst1_off;
                    else
                        t1 = inst1_on;
                    end
                    if gap_def(2) == 1
                        t2 = inst2_on;
                    else
                        t2 = inst2_off;
                    end
                    gap_duration = t2 - t1;
                    instance_rows_all = [instance_rows_all; ...
                        {subID, trial_val, inst1_cat, inst2_cat, inst1_on, inst1_off, inst2_on, inst2_off, gap_duration}];
                end
            end

            % ROI output
            for cat = 1:num_cats
                if rois{1} == -1
                    roi_val = cat;
                    category = {cat};
                else
                    roi_val = rois{cat};
                    category = {rois{cat}};
                end
                % Filter data for ROI.
                data_cat = key_roi_data(trial_data, category);
                if isempty(data_cat)
                    continue;
                end
                data_cat_sorted = sortrows(data_cat, 1);
                num_events_cat = size(data_cat_sorted, 1);
                if num_events_cat >= 2
                    for j = 1:(num_events_cat - 1)
                        inst1_on = data_cat_sorted(j, 1);
                        inst1_off = data_cat_sorted(j, 2);
                        inst2_on = data_cat_sorted(j+1, 1);
                        inst2_off = data_cat_sorted(j+1, 2);
                        if gap_def(1) == 2
                            t1 = inst1_off;
                        else
                            t1 = inst1_on;
                        end
                        if gap_def(2) == 1
                            t2 = inst2_on;
                        else
                            t2 = inst2_off;
                        end
                        gap_duration = t2 - t1;
                        instance_rows_roi = [instance_rows_roi; {subID, trial_val, roi_val, inst1_on, inst1_off, inst2_on, inst2_off, gap_duration}]; 
                    end
                end
            end  
        end
    end 

    % Output
    [filepath, name, ~] = fileparts(output_filename);

    % aggregated
    T_all = cell2table(instance_rows_all, 'VariableNames', ...
        {'subID','trial','inst1_cat','inst2_cat','inst1_onset','inst1_offset','inst2_onset','inst2_offset','gap_duration'});

    % ROI
    T_roi = cell2table(instance_rows_roi, 'VariableNames', ...
        {'subID','trial','cat','inst1_onset','inst1_offset','inst2_onset','inst2_offset','gap_duration'});

    roi_filename = fullfile(filepath, [name, '_cat.csv']);
    writetable(T_roi, roi_filename);
    disp(['cat file written to: ' roi_filename]);

    all_filename = fullfile(filepath, [name, '_all.csv']);
    writetable(T_all, all_filename);
    disp(['Aggregated file written to: ' all_filename]);
end
