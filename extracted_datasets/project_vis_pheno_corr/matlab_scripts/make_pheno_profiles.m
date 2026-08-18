function make_pheno_profiles(core_dir)

    % builds a table of all given variables for given experiment IDs,
    % aggregating object looks and splitting off face looks for respective
    % variables for general analysis and PCA
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % INPUTS:
    % list of variables of interest
    % var_list ={'cevent_eye_roi_child','cevent_inhand_child','cevent_inhand-eye_child-child', ...
    %     'cevent_inhand-eye_child-parent', 'cevent_eye_roi_parent','cevent_inhand_parent', ...
    %     'cevent_inhand-eye_parent-child',  'cevent_inhand-eye_parent-parent', ...
    %     'cevent_eye_joint-attend_both',  'cevent_speech_naming_local-id', 'cevent_speech_utterance', ...
    %     'cevent_eye_roi_sustained-3s_child', 'cevent_eye_roi_sustained-3s_parent',...
    %     'cevent_inhand_bimanual-same_child', 'cevent_inhand_bimanual-same_parent', ...
    %     'cevent_vision_face_child', 'cevent_eye_roi_no-inhand_child', ...
    %     'cevent_eye_roi_no-inhand_parent'};
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % reading in the core_variable_list.txt
    % 'M:' is the directory input

    core_var_file = fullfile(core_dir, 'core_variable_list.txt');
    
    if ~isfile(core_var_file)
        error('Could not find core variable list: %s', core_var_file);
    end
    
    % One variable name per line
    all_vars = readlines(core_var_file);
    
    % Clean whitespace
    all_vars = strtrim(all_vars);
    
    % Remove blank lines
    all_vars(all_vars == "") = [];
    
    % Keep only cevent variables
    all_vars = all_vars(startsWith(all_vars, "cevent_"));
    
    % Convert to cell array because the rest of this function uses var_list{i}
    var_list = cellstr(all_vars);
    
    fprintf('Found %d cevent variables in core_variable_list.txt\n', ...
        numel(var_list));


    % subject table file
    %'M:\subject_table.txt';
    subject_table_file = 'M:\subject_table.txt';
    
    % exps in which inhand needs to be 0 rather than NaN
    fix_inhand = [58, 353, 361, 362, 363];
    
    % where the pheno_table is saved
    results_dir = ...
        'M:\extracted_datasets\project_vis_pheno_corr\pheno_input';
    
    output_filename = fullfile(results_dir, 'pheno_table.csv');
    exp_summary_filename = fullfile(results_dir, 'exp_summary_table.csv');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % reading in and setting up subject table
    subject_table = readtable(subject_table_file);
    subject_table = subject_table(:, 1:4);
    subject_table.Properties.VariableNames = {'subID', 'expID', 'date', 'kidID'};
    
    % extracting valid experiment IDs from subject table
    exp_ids = unique(subject_table.expID);
    exp_ids = exp_ids(~isnan(exp_ids));
    exp_ids = sort(exp_ids);

    % Determine whether phenotype table needs updating

    all_subIDs = unique(subject_table.subID(~isnan(subject_table.subID)));
    
    if isfile(output_filename)
    
        pheno_table = readtable(output_filename);
    
        % 1. Find new subjects
        missing_subIDs = setdiff(all_subIDs, pheno_table.subID);
   

        % Find variables whose expected output columns do not exist
        vars_needing_update = {};
    
        for i = 1:numel(var_list)
    
            var_name = var_list{i};
            safe_name = matlab.lang.makeValidName(var_name);
    
            has_face = ismember(var_name, { ...
                'cevent_eye_roi_child', ...
                'cevent_eye_roi_parent', ...
                'cevent_eye_joint-attend_both', ...
                'cevent_eye_roi_sustained-3s_child', ...
                'cevent_eye_roi_sustained-3s_parent'});
    
            % Every variable gets these object measures
           required_cols = { ...
                make_pheno_col_name(var_name, '_object_prop'), ...
                make_pheno_col_name(var_name, '_object_duration'), ...
                make_pheno_col_name(var_name, '_object_norm_freq')};
        
            % Selected ROI variables also get face measures
            if has_face

                required_cols = [required_cols, { ...
                    make_pheno_col_name(var_name, '_face_prop'), ...
                    make_pheno_col_name(var_name, '_face_duration'), ...
                    make_pheno_col_name(var_name, '_face_norm_freq')}];
            
            end
    
            if ~all(ismember(required_cols, ...
                    pheno_table.Properties.VariableNames))
    
                vars_needing_update{end+1} = var_name; 
    
            end
        end
    

        % Decide which subjects + variables actually need processing
        if ~isempty(vars_needing_update)
        
            fprintf('New phenotype variables/metrics detected:\n');
            disp(vars_needing_update');
        
            % Missing variables need to be calculated for existing subjects
            subIDs_to_process = all_subIDs;
        
            % But ONLY these variables need extraction
            affected_vars = vars_needing_update;
        
        else
        
            % No new variables: only new subjects need processing
            subIDs_to_process = missing_subIDs;
        
            % New subjects need every requested phenotype variable
            affected_vars = var_list;
        
        end
    
        if isempty(missing_subIDs) && isempty(vars_needing_update)

            fprintf('Phenotype table is already up-to-date.\n');
        
            % Rebuild experiment summary if it is missing
            if ~isfile(exp_summary_filename)
        
                fprintf('Experiment summary missing. Creating it now.\n');
        
                exp_summary = summarize_by_exp(pheno_table);
        
                writetable(exp_summary, exp_summary_filename);
        
            end
    
        else
    
            if ~isempty(missing_subIDs)
                fprintf('Adding new subjects:\n');
                disp(missing_subIDs);
            end
    
            create_pheno_table(missing_subIDs, subIDs_to_process, ...
                affected_vars, pheno_table);
    
        end
    
    else
    
        % First-ever run
        create_pheno_table(all_subIDs, all_subIDs, var_list, table());
    
    end

            
    function create_pheno_table( ...
        subIDs_to_add, subIDs_to_process, affected_vars, existing_table)
         % Only rerun extraction for experiments containing missing subjects

    rows_to_process = ismember(subject_table.subID, subIDs_to_process);

    affected_exp_ids = unique(subject_table.expID(rows_to_process));
    affected_exp_ids = affected_exp_ids(~isnan(affected_exp_ids));
    
    for e = 1:length(affected_exp_ids)

        curr_exp = affected_exp_ids(e);
    
        try
            num_roi = get_num_obj(curr_exp);
            curr_num_roi = num_roi + 1;
        catch ME
            fprintf('Invalid number of ROIs for experiment %d: %s\n', ...
                curr_exp, ME.message);
            continue
        end
    
        for i = 1:numel(affected_vars)
    
            var_name = affected_vars{i};
    
            fprintf('Updating extraction: exp %d, %s\n', ...
                curr_exp, var_name);
    
            try
                extract_basic_stats(var_name, curr_exp, curr_num_roi);
    
            catch ME
                fprintf(['Extraction failed for experiment %d, variable %s:\n' ...
                         '%s\n'], ...
                    curr_exp, var_name, ME.message);
            end
    
        end
    end
        

        
    % Select only subject-table rows that need to be added
    
    rows_to_add = ismember(subject_table.subID, subIDs_to_add);
    
    new_subject_table = subject_table(rows_to_add, :);
    
    % Remove malformed IDs
    new_subject_table = new_subject_table( ...
        ~isnan(new_subject_table.subID), :);
    
    % Keep one row per subject
    [~, unique_idx] = unique(new_subject_table.subID, 'stable');
    new_subject_table = new_subject_table(unique_idx, :);
    
    % Create metadata rows for new subjects
    
    new_rows = table();
    
    new_rows.subID = double(new_subject_table.subID);
    new_rows.expID = double(new_subject_table.expID);
    new_rows.kidID = double(new_subject_table.kidID);
    new_rows.age = nan(height(new_rows), 1);
        
    % Try to calculate age for each subject independently
    
    for s = 1:height(new_rows)

        sid = new_rows.subID(s);

        try
            [ageout, ~, ~, subjout] = get_age_at_exp(sid);
    
            if ~isempty(ageout)
    
                match_idx = find(subjout == sid, 1);
    
                if ~isempty(match_idx)
                    new_rows.age(s) = ageout(match_idx);
                else
                    new_rows.age(s) = ageout(1);
                end
    
            end
    
        catch ME
            fprintf('Age unavailable for subject %d: %s\n', ...
                    sid, ME.message);
        end
    end
        
       

    if isempty(existing_table)

        % First run
        output_table = new_rows;

    else

        output_table = existing_table;
    
        % Add existing phenotype-variable columns to new_rows
        existing_vars = output_table.Properties.VariableNames;
    
        for v = 1:numel(existing_vars)
    
            var_name = existing_vars{v};
    
            if ~ismember(var_name, new_rows.Properties.VariableNames)
    
                example_value = output_table.(var_name);
    
                if isnumeric(example_value)
                    new_rows.(var_name) = nan(height(new_rows), 1);
    
                elseif islogical(example_value)
                    new_rows.(var_name) = false(height(new_rows), 1);
    
                elseif isstring(example_value)
                    new_rows.(var_name) = strings(height(new_rows), 1);
    
                elseif iscell(example_value)
                    new_rows.(var_name) = cell(height(new_rows), 1);
    
                elseif iscategorical(example_value)
                    new_rows.(var_name) = categorical( ...
                        repmat(missing, height(new_rows), 1));
    
                else
                    error('Unsupported column type for %s.', var_name);
                end
    
            end
        end

    % Match existing column order
    new_rows = new_rows(:, existing_vars);

    % Append only missing subjects
    output_table = [output_table; new_rows];

end
        
        
        % reading in tables for each variable of interest
        for e = 1:length(affected_exp_ids)
            curr_exp = affected_exp_ids(e);
        
            num_roi = get_num_obj(curr_exp);
            curr_num_roi = num_roi + 1;
        
            expID = num2str(curr_exp);
        
            for i = 1:length(var_list)
        
        
                % fixing var_name for saving
                var_name = var_list{i};

                object_prop_name = make_pheno_col_name( ...
                    var_name, '_object_prop');
                
                object_freq_name = make_pheno_col_name( ...
                    var_name, '_object_norm_freq');
                
                object_duration_name = make_pheno_col_name( ...
                    var_name, '_object_duration');
                
                has_face = ismember(var_name, { ...
                    'cevent_eye_roi_child', ...
                    'cevent_eye_roi_parent', ...
                    'cevent_eye_joint-attend_both', ...
                    'cevent_eye_roi_sustained-3s_child', ...
                    'cevent_eye_roi_sustained-3s_parent'});
                
                if has_face

                    face_prop_name = make_pheno_col_name( ...
                        var_name, '_face_prop');
                
                    face_freq_name = make_pheno_col_name( ...
                        var_name, '_face_norm_freq');
                
                    face_duration_name = make_pheno_col_name( ...
                        var_name, '_face_duration');
                
                end
        
        
                object_columns_exist = ...
                    ismember(object_prop_name, output_table.Properties.VariableNames) && ...
                    ismember(object_duration_name, output_table.Properties.VariableNames) && ...
                    ismember(object_freq_name, output_table.Properties.VariableNames);
                
                if has_face
                
                    face_columns_exist = ...
                        ismember(face_prop_name, output_table.Properties.VariableNames) && ...
                        ismember(face_duration_name, output_table.Properties.VariableNames) && ...
                        ismember(face_freq_name, output_table.Properties.VariableNames);
                
                else
                
                    face_columns_exist = true;
                
                end

            
                exp_rows = output_table.expID == curr_exp;
            
                object_values_exist = false;
                face_values_exist = false;
                
                if object_columns_exist && any(exp_rows)
                
                    object_values_exist = ...
                        any(~isnan(output_table.(object_prop_name)(exp_rows))) || ...
                        any(~isnan(output_table.(object_freq_name)(exp_rows)));
                
                end
                
                if has_face && face_columns_exist && any(exp_rows)
                
                    face_values_exist = ...
                        any(~isnan(output_table.(face_prop_name)(exp_rows))) || ...
                        any(~isnan(output_table.(face_freq_name)(exp_rows)));
                
                elseif ~has_face
                
                    face_values_exist = true;
                
                end
                
                already_processed = ...
                    object_columns_exist && ...
                    object_values_exist && ...
                    face_values_exist;
            
                if already_processed
            
                fprintf('Already in phenotype table: exp %d, %s\n', ...
                    curr_exp, var_name);
            
                continue
            
                end
        
                
        
        
        
                if ~ismember(object_prop_name, ...
                    output_table.Properties.VariableNames)
            
                    output_table.(object_prop_name) = ...
                    nan(height(output_table), 1);
            
                end
            
                if ~ismember(object_freq_name, ...
                        output_table.Properties.VariableNames)
            
                    output_table.(object_freq_name) = ...
                        nan(height(output_table), 1);
            
                end

                if ~ismember(object_duration_name, ...
                    output_table.Properties.VariableNames)
            
                    output_table.(object_duration_name) = ...
                        nan(height(output_table), 1);
            
                end
            
            
                if has_face
            
                    if ~ismember(face_prop_name, output_table.Properties.VariableNames)
            
                        output_table.(face_prop_name) = nan(height(output_table), 1);
            
                    end

                    if ~ismember(face_duration_name, ...
                        output_table.Properties.VariableNames)
                
                        output_table.(face_duration_name) = ...
                            nan(height(output_table), 1);
                
                    end
            
                    if ~ismember(face_freq_name, output_table.Properties.VariableNames)
                
                        output_table.(face_freq_name) = nan(height(output_table), 1);
                    end
                end
                
                % reading in extracted files
                var_name = var_list{i};
                filename = fullfile('M:\extracted_datasets\extract_single_variable_stats\results\', sprintf('%s_exp%s.xlsx', var_name, expID));
        
                % catching missing vars
                if ~isfile(filename)
        
                    writetable(output_table, output_filename);
                    continue
                end
        
            results_table = readtable(filename, 'Sheet', 1);
            freq_table = readtable(filename, 'Sheet', 2);
        
            % Fix headers if needed
            results_table = fix_bad_headers(filename, 1, results_table);
            freq_table = fix_bad_headers(filename, 2, freq_table);
            
            % Remove invalid subjects
            valid_rows = false(height(results_table), 1);
            
            for k = 1:height(results_table)
            
                try
                    get_subject_dir(results_table.subID(k));
                    valid_rows(k) = true;
            
                catch
                    fprintf('Removing invalid subject %d from %s\n', ...
                        results_table.subID(k), filename);
                end
            end
        
            results_table = results_table(valid_rows, :);
            freq_table = freq_table(valid_rows, :);
        
                
        
                % finding missing subs before calculating vals
                missing = false(height(results_table), 1);
        
                    for k = 1:height(results_table)
        
                        sid = results_table.subID(k);
                        try
                            data = get_variable_by_trial_cat(sid, var_name);
                        catch
                            fprintf('Missing variable %s for subject %d\n', var_name, sid);
                            missing(k) = true;
                            continue
                        end
        
                        if isempty(data)
                            % hard-coding specific missing inhand exps to keep 0s
                            if ~(contains(var_name, 'inhand') && ismember(curr_exp, fix_inhand))
                                missing(k) = true;
                            end
                        end
                    end
        
                % aggregating object columns for duration
                vars = results_table.Properties.VariableNames;
                time_cat_cols = startsWith(vars, 'time_cat_');
                time_cat_names = vars(time_cat_cols);

                time_object_cols = time_cat_names(1:curr_num_roi - 1);

              

            
                 % aggregating object columns for proportion
                vars = results_table.Properties.VariableNames;
                prop_cat_cols = startsWith(vars, 'prop_cat_');
                prop_cat_names = vars(prop_cat_cols);
        
                if numel(prop_cat_names) < curr_num_roi
                    % if the file doesn't exist, stop from breaking
                    writetable(output_table, output_filename);
                    continue
                end
            
                prop_object_cols = prop_cat_names(1:curr_num_roi - 1);
        
        
                % aggregating object columns for normalized freq
                freq_vars = freq_table.Properties.VariableNames;
                norm_freq_cols = startsWith(freq_vars, 'normalizedFreq');
                norm_freq_names = freq_vars(norm_freq_cols);
        
                if numel(norm_freq_names) < curr_num_roi
                    % if the file doesn't exist, stop from breaking
                    writetable(output_table, output_filename);
                    continue
                end
        
                freq_object_cols = norm_freq_names(1:curr_num_roi - 1);
                    
               % overwriting 0s to NaN for missing vars
               results_table{missing, prop_cat_names} = NaN;
               results_table{missing, time_cat_names} = NaN;
               freq_table{missing, norm_freq_names} = NaN;
        
        
        
                % calculating object_prop, duration, and norm_freq
                object_prop = sum(results_table{:,prop_object_cols}, 2);
                norm_freq = sum(freq_table{:,freq_object_cols}, 2);
                object_time = sum(results_table{:,time_object_cols}, 2);
        
        
        
        
        
                % Update every subject that needs processing during this run
                process_result_rows = ...
                    ismember(results_table.subID, subIDs_to_process);
                
                [tf, loc] = ...
                    ismember(results_table.subID, output_table.subID);
                
                tf = tf & process_result_rows;
                
                idx = find(tf);
                out_idx = loc(idx);
                
                output_table.(object_prop_name)(out_idx) = object_prop(idx);
                
                output_table.(object_freq_name)(out_idx) = norm_freq(idx);

                output_table.(object_duration_name)(out_idx) = object_time(idx);
                
            
        
        
                if has_face

                    prop_face_col = prop_cat_names(curr_num_roi);
                    face_prop = results_table{:, prop_face_col};
                
                    freq_face_col = norm_freq_names(curr_num_roi);
                    face_freq = freq_table{:, freq_face_col};
                
                    time_face_col = time_cat_names(curr_num_roi);
                    face_time = results_table{:, time_face_col};
                
                    output_table.(face_prop_name)(out_idx) = ...
                        face_prop(idx);
                
                    output_table.(face_duration_name)(out_idx) = ...
                        face_time(idx);
                
                    output_table.(face_freq_name)(out_idx) = ...
                        face_freq(idx);
                
                end
            end
        end
        
        % saving csv output (reference later or could just use the table for pca)
        writetable(output_table, output_filename);

        % saving experiment-level summary
        exp_summary = summarize_by_exp(output_table);
        
        writetable(exp_summary, exp_summary_filename);
        
    end


    function exp_summary = summarize_by_exp(output_table)

    % categorical data
    metadata_vars = { ...
        'subID', ...
        'expID', ...
        'kidID', ...
        'age'};

    % numerical data
    phenotype_vars = setdiff( ...
        output_table.Properties.VariableNames, ...
        metadata_vars, ...
        'stable');


    % one row per experiment
    exp_ids = unique(output_table.expID);
    exp_ids = exp_ids(~isnan(exp_ids));

    exp_summary = table();
    exp_summary.expID = exp_ids;

    % num of subjects belonging to each experiment
    exp_summary.N = zeros(height(exp_summary), 1);


    % mean value within each experiment
    for e = 1:height(exp_summary)

        curr_exp = exp_summary.expID(e);

        exp_rows = output_table.expID == curr_exp;

        % num of subjects
        exp_summary.N(e) = sum(exp_rows);

        for v = 1:numel(phenotype_vars)

            curr_var = phenotype_vars{v};

            vals = output_table.(curr_var)(exp_rows);

            exp_summary.(curr_var)(e) = ...
                mean(vals, 'omitnan');

        end

    end

end
    


    function T = fix_bad_headers(filename, sheet_num, T)
    
        % check if headers look broken
        if any(strcmp(T.Properties.VariableNames,'Var1')) || ...
           ~any(startsWith(T.Properties.VariableNames, {'prop_cat_','normalizedFreq'}))
    
            fprintf('Fixing headers for %s sheet %d\n', filename, sheet_num)
    
            raw = readcell(filename,'Sheet',sheet_num);
    
            headers = string(raw(1,:));
    
            % remove completely empty columns
            keep_cols = ~all(cellfun(@(x) isempty(x) || ...
                (isstring(x) && x==""), raw),1);
    
            raw = raw(:,keep_cols);
            headers = headers(keep_cols);
    
            % replace empty headers
            empty_headers = headers == "" | ismissing(headers);
            headers(empty_headers) = "Var_" + find(empty_headers);
    
            % make valid + unique MATLAB names
            headers = matlab.lang.makeValidName(headers);
            headers = matlab.lang.makeUniqueStrings(headers);
    
            % rebuild table
            T = cell2table(raw(2:end,:), ...
                'VariableNames', headers);
        end
    end
end


function col_name = make_pheno_col_name(var_name, suffix)

    safe_name = matlab.lang.makeValidName(var_name);

    max_base_length = namelengthmax - length(suffix);

    if length(safe_name) > max_base_length

        % Keep beginning + end of variable name to reduce collision risk
        tail_length = min(12, max_base_length - 2);
        head_length = max_base_length - tail_length - 2;

        safe_name = [ ...
            safe_name(1:head_length), ...
            '__', ...
            safe_name(end-tail_length+1:end)];

    end

    col_name = [safe_name suffix];

end