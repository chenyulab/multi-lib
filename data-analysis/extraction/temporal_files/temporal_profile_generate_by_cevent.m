function [profile_data] = temporal_profile_generate_by_cevent(input)
% This function generates temporal profile of a group of continue variables
% or one cstream profile chunked by one cevent variable.
%
% For detailed user guide one this function, please go to demo script at:
%   demo_generate_temporal_profile_by_cevent.m
% 
% Last update by Jingwen, 12/05/2024

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sub_list = input.sub_list;
% expsub_ids = input.sub_list;
% if size(expsub_ids, 1) < size(expsub_ids, 2)
%     expsub_ids = expsub_ids';
% end
% 
% mask_expid = expsub_ids < 1000;
% mask_subid = expsub_ids > 1000;
% 
% sub_list = expsub_ids(mask_subid);
% 
% if sum(mask_expid) > 0
%     exp_list = expsub_ids(mask_expid);
%     sub_list = [sub_list; list_subjects(exp_list)];
%     exp_list = unique(floor(sub_list / 100));
% end

if ~(isfield(input, 'whence') && isfield(input, 'interval'))
    error(['Error. This functions only works ''whence'' and ''interval'' are both specified. ' ...
        'For example, one wants to generate gaze profile 10 seconds before to the onset of ' ...
        'naming instances. In this case, whence is ''start'', interval is [-10 0].']);
else
    whence = input.whence;
    interval = input.interval;
end

if ~isfield(input, 'cevent_category')
    error(['When data are regrouped by cevents, the field ' ...
        'CEVENT_CATEGORY must be specified.']);
else
    cevent_category = input.cevent_category;
end
if ~isfield(input, 'var_category')
    error(['Under all situations, the field ' ...
        'VAR_CATEGORY must be specified.']);
else
    var_category = input.var_category;
end

% if strcmp(whence, 'start')
%     ref_column = 1;
%     str_align = 'onset';
% elseif strcmp(whence, 'end')
%     ref_column = 2;
%     str_align = 'offset';
% end

cevent_name = input.cevent_name;
var_name = input.var_name;

x_has_var_cevent = arrayfun( ...
    @(sub_id) ...
    has_variable(sub_id, cevent_name), ...
    sub_list, ...
    'UniformOutput', 0);
x_has_var_cevent = vertcat(x_has_var_cevent{:});

if sum(~x_has_var_cevent) > 0
    missvar_sub_list = num2str(sub_list(~x_has_var_cevent)');
    fprintf('Cevent variable %s does not exist for subject(s) %s\n', cevent_name, missvar_sub_list);
end
mask_has_variable = x_has_var_cevent;

groupid_matrix = input.groupid_matrix;
groupid_list = unique(groupid_matrix);
num_groupids = length(groupid_list);

if iscell(input.var_name)
    example_var_name = var_name{1};
    is_var_cell = true;
    num_vars = length(var_name);
    
    if size(groupid_matrix, 1) ~= num_vars
        error(['In ''groupid_matrix'', each row corresponding to a cstream ROI value or the order of cont type ' ...
            'variable, and each column corresponding to a cevent value. So, if you input a cell list of ' ...
            'cont variables in the grouping variable list, the number and order of the variables ' ...
            'should match with the rows in groupid_matrix.']);
    end
    str_var_type = get_data_type(example_var_name);
    
    if ~strcmp(str_var_type, 'cont')
        error('Only a list of continue variables or one cstream variable are accepted as input.')
    end
    
    for vidx = 1:num_vars
        x_var_one = arrayfun( ...
            @(sub_id) ...
            has_variable(sub_id, var_name{vidx}), ...
            sub_list, ...
            'UniformOutput', 0);
        x_var_one = vertcat(x_var_one{:});

        if sum(~x_var_one) > 0
            missvar_sub_list = num2str(sub_list(~x_var_one)');
            fprintf('Continue variable %s does not exist for subject(s) %s\n', var_name{vidx}, missvar_sub_list);
        end
        mask_has_variable = mask_has_variable & x_var_one;
    end
else
    example_var_name = var_name;
    is_var_cell = false; % meaning the input variable only has one cstream
    num_vars = 1;
    str_var_type = get_data_type(example_var_name);
    
    if ~strcmp(str_var_type, 'cstream')
        error('Only a list of continue variables or one cstream variable are accepted as input.')
    end

    x_var_one = arrayfun( ...
        @(sub_id) ...
        has_variable(sub_id, var_name), ...
        sub_list, ...
        'UniformOutput', 0);
    x_var_one = vertcat(x_var_one{:});

    if sum(~x_var_one) > 0
        missvar_sub_list = num2str(sub_list(~x_var_one)');
        fprintf('Cstream variable %s does not exist for subject(s) %s\n', var_name, missvar_sub_list);
    end
    mask_has_variable = mask_has_variable & x_var_one;
end

if size(groupid_matrix, 1) ~= length(var_category)
    error(['In ''groupid_matrix'', each row corresponding to a cstream ROI value or the order of cont type ' ...
        'variables, and each column corresponding to a cevent value. So, the number of values in ' ...
        '''var_category'' should match with the number of rows in groupid_matrix.']);
end

if size(groupid_matrix, 2) ~= length(cevent_category)
    error(['In ''groupid_matrix'', each row corresponding to a cstream value/variable, and ' ...
        'each column corresponding to a cevent value. So, the number of values in ' ...
        '''cevent_category'' should match with the number of columns in groupid_matrix.']);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for eidx = 1:length(exp_list)
%     exp_id = exp_list(eidx);

% mask_sub_list = sub_list > exp_id*100 & sub_list < (exp_id+1)*100;
% sub_list = sub_list(mask_sub_list);
sub_list = sub_list(mask_has_variable);

result_chunks = cell(length(sub_list), num_groupids);
result_sub_list = cell(length(sub_list), 1);
result_ranges = cell(length(sub_list), 1);
result_cevent = cell(length(sub_list), 1);
result_cevent_index = cell(length(sub_list), 1);
result_cevent_trialid = cell(length(sub_list), 1);
result_probs_mean = cell(length(sub_list), 1);

for sidx = 1:length(sub_list)
    sub_id = sub_list(sidx);
    if is_var_cell
        var_data = cell(1, num_vars);
        for vidx = 1:num_vars
            var_data{vidx} = get_variable_by_trial_cat(sub_id, var_name{vidx});
        end
    else
        var_data = get_variable_by_trial_cat(sub_id, var_name);
    end

    if isfield(input, 'sample_rate')
        sample_rate = input.sample_rate;
    else
        sub_timing = get_timing(sub_id);
        sample_rate = 1/sub_timing.camRate;
    end
    time_base = interval(1):sample_rate:(interval(2)-+0.0001);
    length_profile = length(time_base);
    duration_profile = interval(2) - interval(1);
    time_base_ts = 0:sample_rate:(duration_profile-0.0001);

    if isfield(input, 'trial_var_name')
        trials_one = get_variable_by_trial_cat(sub_id, input.trial_var_name);
        if isfield(input, 'trial_values')
            trials_one = cevent_category_equals(...
                trials_one, input.trial_values);
        end
    else
        trials_one = get_trial_times(sub_id);

        if isfield(input, 'trial_indices')
            if iscell(input.trial_indices)
                trials_one = trials_one(input.trial_indices{sidx}, :);
            else
                trials_one = trials_one(input.trial_indices, :);
            end
        end
    end

    cevent_data = get_variable_by_trial_cat(sub_id, cevent_name);

    chunks_cevents = cell(size(trials_one, 1), 1);
    chunks_trialid = cell(size(trials_one, 1), 1);

    for tidx = 1:size(trials_one, 1)
        range = trials_one(tidx, :); % range(1) is start, range(2) is end
        chunk_one = get_event_in_scope(cevent_data, range);
        len_chunks = size(chunk_one, 1);

        chunks_cevents{tidx} = chunk_one;
        chunks_trialid{tidx} = repmat(tidx, len_chunks, 1);
    end

    cevent_data = vertcat(chunks_cevents{:});
    cevent_trialid = vertcat(chunks_trialid{:});

    if isfield(input, 'cevent_min_dur')
        cevent_dur = cevent_data(:,2) - cevent_data(:,1); 
        x_dur_mask = cevent_dur >= input.cevent_min_dur;
        cevent_data = cevent_data(x_dur_mask, :);
        cevent_trialid = cevent_trialid(x_dur_mask, :);
    end

    if isfield(input, 'cevent_max_dur')
        cevent_dur = cevent_data(:,2) - cevent_data(:,1); 
        x_dur_mask = cevent_dur <= input.cevent_max_dur;
        cevent_data = cevent_data(x_dur_mask, :);
        cevent_trialid = cevent_trialid(x_dur_mask, :);
    end

    if isempty(cevent_data)
        fprintf('Subject %d has zero instances of %s that met criteria.\n', sub_id, cevent_name);
        continue
    end

    % After retrieving cevent data, start getting cont/cstream
    % variables
    num_cevents = size(cevent_data, 1);
    result_sub_list{sidx, 1} = repmat(sub_id, num_cevents, 1);
    result_cevent{sidx, 1} = cevent_data;
    result_cevent_index{sidx, 1} = (1:num_cevents)'; 
    result_cevent_trialid{sidx, 1} = cevent_trialid;
    probs_mean_sub = nan(num_cevents, num_groupids);

    temporal_ranges = cevent_relative_intervals(...
        cevent_data, input.whence, input.interval);

    if isfield(input, 'within_ranges') && ~input.within_ranges
        temporal_ranges = get_cevent_opposite(sub_id, cevent_data, trials_one);
    end

    result_ranges{sidx, 1} = temporal_ranges;

    chunks_profile_sub = cell(1, num_groupids);
    for coidx = 1:num_groupids
        chunks_profile_sub{coidx} = nan(num_cevents, length_profile);
    end

    if is_var_cell % when user input a list of continue variables
        % chunks_var_origin stores the variable extracted from the dataset
        chunks_var_origin = cell(num_cevents, num_vars);
        mat_var_profile = nan(num_cevents, length_profile, num_vars);
        cont_sum_sub = zeros(num_cevents, length_profile, num_groupids);
        cont_count_sub = zeros(num_cevents, length_profile, num_groupids);
        
        % fetch and format continue variable data
        for vidx = 1:num_vars
            chunks_var_one  = extract_ranges(var_data{vidx}, ...
                str_var_type, {temporal_ranges});
            mat_profile_one = nan(num_cevents, length_profile);
            
            for cnidx = 1:num_cevents
                try
                    range_one = temporal_ranges(cnidx, :);
    
                    chunks_one_new = chunks_var_one{cnidx};
                    chunks_one_new(:, 1) = chunks_one_new(:, 1) - range_one(1);
                    length_one = size(chunks_one_new, 1);
    
                    if length_one ~= length_profile
                        chunk_ts = timeseries(chunks_one_new(:, 2:end), chunks_one_new(:, 1));
                        chunk_ts = resample(chunk_ts, time_base_ts, 'zoh');
                        chunks_one_new = horzcat(get(chunk_ts, 'Time'), get(chunk_ts, 'Data'));
                    end
    
                    chunks_one_new(isnan(chunks_one_new(:,2)),2) = 0;
                    mat_profile_one(cnidx, :) = chunks_one_new(:, 2)';
                catch
                    warning('timestamp %.3f might not exist in %s',range_one,input.var_name);
                    continue
                end
            end
            
            mat_var_profile(:, :, vidx) = mat_profile_one;
        end
        
        for ceventidx = 1 : length(cevent_category)
            cevent_values = cevent_category(ceventidx);
            label_column = groupid_matrix(:, ceventidx);
            label_column_list = unique(label_column);

            mask_cvalues = ismember(cevent_data(:, 3), cevent_values);
%             chunks_var_by_cvalue = chunks_var_origin(mask_cvalues);
%             chunks_ranges = temporal_ranges(mask_cvalues);
%             num_cevents_value = sum(mask_cvalues);
            
            for lidx = 1:length(label_column_list)
                label_one = label_column_list(lidx);
                target_categories = var_category(label_column == label_one);
                
                tmp_profile = cont_sum_sub(mask_cvalues, :, label_one);
                tmp_count = cont_count_sub(mask_cvalues, :, label_one);
                cont_sum_sub(mask_cvalues, :, label_one) = ...
                    cont_sum_sub(mask_cvalues, :, label_one) + ...
                    sum(mat_var_profile(mask_cvalues, :, target_categories), 3);
                cont_count_sub(mask_cvalues, :, label_one) = ...
                    cont_count_sub(mask_cvalues, :, label_one) + ...
                    sum(mat_var_profile(mask_cvalues, :, target_categories)>0, 3);
            end
        end % end of going through all cevents
        
        for gidx = 1:num_groupids
            label_one = groupid_list(gidx);
            tmp_count = cont_count_sub(:, :, gidx);
            probs_mean_sub(:, gidx) = sum(cont_sum_sub(:, :, gidx), 2) ./ sum(tmp_count, 2);
            tmp_count(tmp_count < 1) = 1;
            chunks_profile_sub{gidx} = cont_sum_sub(:, :, gidx) ./ tmp_count;
        end
    else
        % chunks_var_origin stores the variable extracted from the dataset
        chunks_var_origin = extract_ranges(var_data, ...
            str_var_type, {temporal_ranges});
        % chunks_var_mat stores the variables that were reassigned
        chunks_var_mat = nan(num_cevents, length_profile);
        chunks_check_mat = nan(num_cevents, length_profile);

        for ceventidx = 1 : length(cevent_category)
            cevent_values = cevent_category(ceventidx);
            label_column = groupid_matrix(:, ceventidx);
            label_column_list = unique(label_column);

            mask_cvalues = ismember(cevent_data(:, 3), cevent_values);
            chunks_var_by_cvalue = chunks_var_origin(mask_cvalues);
            chunks_ranges = temporal_ranges(mask_cvalues);
            num_cevents_value = sum(mask_cvalues);

            mat_var_profile = nan(num_cevents_value, length_profile);

            for cnidx = 1:size(chunks_ranges, 1)
                try
                    range_one = chunks_ranges(cnidx, :);
    
                    chunks_one_new = chunks_var_by_cvalue{cnidx};
                    chunks_one_new(:, 1) = chunks_one_new(:, 1) - range_one(1);
                    length_one = size(chunks_one_new, 1);
    
                    if length_one ~= length_profile
                        chunk_ts = timeseries(chunks_one_new(:, 2:end), chunks_one_new(:, 1));
                        chunk_ts = resample(chunk_ts, time_base_ts, 'zoh');
                        chunks_one_new = horzcat(get(chunk_ts, 'Time'), get(chunk_ts, 'Data'));
                    end
    
                    mat_var_profile(cnidx, :) = chunks_one_new(:, 2)';
                catch
                    warning('timestamp %.3f might not exist in %s',range_one,input.var_name);
                    continue
                end
            end

            mat_origin_profile = mat_var_profile;
            for lidx = 1:length(label_column_list)
                label_one = label_column_list(lidx);
                target_categories = var_category(label_column == label_one);

                mask_reassign = ismember(mat_origin_profile, target_categories);
                mat_var_profile(mask_reassign) = label_one;
            end

            chunks_check_mat(mask_cvalues, :) = mat_origin_profile;
            chunks_var_mat(mask_cvalues, :) = mat_var_profile;
        end % end of going through cevent categorical values

        for gidx = 1 : num_groupids
            label_target = groupid_list(gidx);
            label_other = setdiff(groupid_list, label_target);

            % Each cell contains the matrix that holds data for one group label
            tmp_chunk = chunks_profile_sub{gidx};

            mask_group = ismember(chunks_var_mat, label_target);
            tmp_chunk(mask_group) = 1;
            mask_other = ismember(chunks_var_mat, label_other);
            tmp_chunk(mask_other) = 0;
            mask_zeros = chunks_var_mat < 1;
            tmp_chunk(mask_zeros) = 0;
            chunks_profile_sub{gidx} = tmp_chunk;

            num_valid_data = sum(~isnan(tmp_chunk), 2);
            num_matches = sum(mask_group, 2);
            probs_mean_sub(:, gidx) = num_matches ./ num_valid_data;
        end
    end
    
    result_chunks(sidx, :) = chunks_profile_sub;
    result_probs_mean{sidx, :} = probs_mean_sub;
end % end of sidx
 
% result_chunks = vertcat(result_chunks{:});
result_probs_mean = vertcat(result_probs_mean{:});

% subID	expID	onset	offset	category	trialsID	instanceID
profile_data.sub_list = vertcat(result_sub_list{:});
profile_data.exp_list = floor(profile_data.sub_list / 100);
profile_data.cevents = vertcat(result_cevent{:});
profile_data.cevent_trialid = vertcat(result_cevent_trialid{:});
profile_data.cevent_instanceid = vertcat(result_cevent_index{:});
profile_data.probs_mean_per_instance = result_probs_mean;

if isfield(input, 'groupid_label')
    profile_data.groupid_label = input.groupid_label;
else
    profile_data.groupid_label = {'target', 'non-target', 'other'};
    profile_data.groupid_label = profile_data.groupid_label(groupid_list);
end
profile_data.group_list = groupid_list';
profile_data_mat = cell(1, num_groupids);
for gidx = 1:num_groupids
    profile_data_mat{gidx} = vertcat(result_chunks{:, gidx});
end
profile_data.profile_data_mat = profile_data_mat;
profile_data.sample_rate = sample_rate;
profile_data.time_base = time_base;
profile_data.cevent_name = cevent_name;
profile_data.var_name = var_name;
