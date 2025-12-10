function master_make_learning_outcome(subexpIDs,args)

    if ~exist('args', 'var') || isempty(args)
        args = struct();
    end

    if isfield(args, 'valid_gaze_time_threshold')
        valid_gaze_time_threshold = args.valid_gaze_time_threshold; % target prop + distractor prop
    else
        valid_gaze_time_threshold = 0.5;   % default
    end

    if isfield(args, 'valid_target_time_prop')
        valid_target_time_prop = args.valid_target_time_prop;  % target prop / valid gaze time prop
    else
        valid_target_time_prop = 0.5;     % default
    end

    if isfield(args, 'test_version_file')
        test_version_file = args.test_version_file; % mapping subject with learning test version
    else
        test_version_file = 'subject_test-type_mapping.xlsx';
    end


    if isfield(args, 'learning_data')
        learning_data = args.learning_data;  % child looking data path
    else
        learning_data = 'supporting_files\lowcam\lowcam_synced.csv';
    end

    subIDs = cIDs(subexpIDs);
    for s = 1:length(subIDs)
        subID = subIDs(s);
        expID = sub2exp(subID);
        convert_mapping_file(subID, test_version_file);
        convert_testing_result(subID, learning_data);
        
    end

    write_learning_score_table(expID, valid_gaze_time_threshold, valid_target_time_prop);


end

function convert_mapping_file(subID, test_version_file)
    start_time = 30;
    
    expID = sub2exp(subID);
    obj_ids = 1:get_num_obj(expID);
    version_data = readtable(fullfile(get_experiment_dir(expID),test_version_file));
    M_v = containers.Map(version_data.subid,version_data.test_type);
    version_n = M_v(subID);
    
    filename = sprintf('v%d_trialInfo.csv',version_n);
    
    fullPath = fullfile(get_experiment_dir(expID), filename);
    
    data = readtable(fullPath);
    labels = get_object_label(expID,obj_ids);
    M_obj = containers.Map(labels',obj_ids);
    
    onset = data.onset + start_time;
    offset = data.offset + start_time;
    target = cellfun(@(k) M_obj(k), data.target);
    distractor = cellfun(@(k) M_obj(k), data.distractor);
    targetSide = data.targetSide;
    
    obj_mtrx = [];
    
    for i = 1:length(target)
        if strcmp(targetSide{i},'left')
            obj_mtrx(i, 1) = target(i);
            obj_mtrx(i, 2) = distractor(i);
        elseif strcmp(targetSide{i},'right')
            obj_mtrx(i, 2) = target(i);
            obj_mtrx(i, 1) = distractor(i);
        end
    end
    
    target_data = [onset,offset,target];
    varname = 'cevent_test-trial_word';
    record_additional_variable(subID,varname,target_data);
    
    left_data = [onset,offset,obj_mtrx(:,1)];
    varname = 'cevent_test-trial_left-object';
    record_additional_variable(subID,varname,left_data);
    
    right_data = [onset,offset,obj_mtrx(:,2)];
    varname = 'cevent_test-trial_right-object';
    record_additional_variable(subID,varname,right_data);

end

function convert_testing_result(subID, learning_data)
    start_time = 30;
    rate = 30;
    
    file = fullfile(get_subject_dir(subID),learning_data);
    
    M_direction = containers.Map({'Left','Right','away','right'},[1,2,0,2]);
    
    data = readtable(file);

    disp(unique(data.Tag));
    
    tag = cellfun(@(k) M_direction(k),data.Tag);
    timestamp = data.Time/1000 + start_time;
    
    cstream = [timestamp,tag];
    varname = 'cstream_eye-at-test_child';
    record_additional_variable(subID,varname,cstream);
    
    cevent = cstream2cevent(cstream);
    varname = 'cevent_eye-at-test_child';
    record_additional_variable(subID,varname,cevent);
    
    % get the trial object variable
    data_l = get_variable(subID,'cevent_test-trial_left-object');
    data_r = get_variable(subID,'cevent_test-trial_right-object');
    
    begin_time = cstream(1,1);
    end_time = cstream(end,1);
    
    data_l_cs = cevent2cstream(data_l,begin_time,1/rate,0,end_time);
    data_r_cs = cevent2cstream(data_r,begin_time,1/rate,0,end_time);
    
    % Combine left and right data streams for mapping
    combined_data = [data_l_cs(:,2), data_r_cs(:,2)];
    
    f = @(a, b) arrayfun(@(i) ...
        (b(i)==1)*a(i,1) + (b(i)==2)*a(i,2) + (b(i)==0)*0, ...
        (1:numel(b))');
    
    mapped_obj = f(combined_data,cstream(:,2));
    cstream_obj = [cstream(:,1),mapped_obj];
    
    cevent_obj = cstream2cevent(cstream_obj);
    varname = 'cevent_eye-at-test_obj_child';
    record_additional_variable(subID,varname,cevent_obj);


end

function write_learning_score_table(expID, valid_gaze_time_threshold, valid_target_time_prop)
    filename_label = sprintf('_targetGE%d',valid_target_time_prop * 100); % GE:greater or equal to
    
    % learning score mapping file
    mapping_file = 'learning_score_mapping.xlsx';
    
    % extract multi measure column number
    sub_col = 1;
    target_col = 5;
    cat_target_col = 8; % target prop
    cat_distractor_col = 9; % distractor prop
    cat_all_col = 10; % valid gaze time prop
    
    % extract multi measure parameters
    var_list = {'cevent_eye-at-test_obj_child'}; % child attended object
    args.cevent_name = 'cevent_test-trial_word'; % target object name child heared
    obj_num = get_num_obj(expID);
    args.cevent_values = 1:obj_num; % all objects
    args.cevent_measures = {'individual_prop_by_cat'};
    args.label_names = {'target', 'other'};
    args.label_matrix = ones(obj_num) * 2 + diag(-ones(obj_num,1));
    
    % extract data
    [data, ~] = extract_multi_measures_at_test(var_list, expID, '', args);
    
    % append total valid gaze time (target + distractor) at the end
    cat_all = data(:,cat_target_col) + data(:,cat_distractor_col);
    data = [data cat_all];
    
    % count score and valid trial number from extracted data
    subIDs = cIDs(expID);
    score_data = [];
    trial_data = [];
    for s = 1:length(subIDs) % subject level 
        subID = subIDs(s);
        sub_data = data(data(:,sub_col) == subID,:);
        score_data(s,1) = subID;
        trial_data(s,1) = subID;
    
        for o = 1:obj_num % subject-object level
            sub_obj_data = sub_data(sub_data(:,target_col) == o,:);
            score_data(s, o + 1) = 0;
            trial_data(s, o + 1) = 0;
            if ~isempty(sub_obj_data)
                for i = 1:size(sub_obj_data,1) % individual instance level
                    total_prop = sub_obj_data(i,cat_all_col);
                    target_time = sub_obj_data(i,cat_target_col);
                    distractor_time = sub_obj_data(i,cat_distractor_col);
                    if total_prop >= valid_gaze_time_threshold
                        trial_data(s,o + 1) = trial_data(s,o + 1) + 1; % Increment score for valid trial
                        target_prop = target_time/(target_time+distractor_time);
                        if target_prop >= valid_target_time_prop
                            score_data(s, o + 1) = score_data(s, o + 1) + 1; % Increment score for valid target proportion
                        end
                    end
                end
            end
        end
    end
    
    
    obj_labels = cellfun(@(x,y) sprintf('obj%d_%s', x, y), ...
                         num2cell(1:obj_num), ...
                         get_object_label(expID, 1:obj_num), ...
                         'UniformOutput', false);
    header = [{'subID'}, obj_labels];
    
    % get mapping data
    mapping_path = fullfile(get_experiment_dir(expID), mapping_file);
    mapping_data = readtable(mapping_path);
    
    % get learning outcome matrix: 1 - learned, 0 - not learned
    learning_mat = arrayfun(@(s,t) get_learning_score(s, t, mapping_data), ...
                            score_data(:,2:end), trial_data(:,2:end));
    
    % assemble tables
    learning_data = [subIDs, learning_mat];
    
    T_learning = array2table(learning_data, "VariableNames", header);
    T_score    = array2table(score_data,   "VariableNames", header);
    T_trial    = array2table(trial_data,   "VariableNames", header);
    
    % base name
    base_name   = sprintf('exp%d_scoretable%s', expID, filename_label);
    exp_dir     = get_experiment_dir(expID);
    
    % save csv file for learning outcome
    csv_file = fullfile(exp_dir, base_name + ".csv");
    writetable(T_learning, csv_file);  % overwrites by default
    
    % save excel file
    xlsx_file = fullfile(exp_dir, base_name + ".xlsx");
    
    % delete existing Excel file to avoid overwrite issue
    if isfile(xlsx_file)
        delete(xlsx_file);
    end
    writetable(T_learning, xlsx_file, 'Sheet', 'Learning_outcome');
    writetable(T_score,    xlsx_file, 'Sheet', 'Learning_score');
    writetable(T_trial,    xlsx_file, 'Sheet', 'Valid_trial');

end

function outcome = get_learning_score(score,trial, mapping_data)
    idx = mapping_data.score == score & mapping_data.trial == trial;
    outcome = mapping_data.learning_outcome(idx);
end
