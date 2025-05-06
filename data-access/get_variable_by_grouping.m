function [chunks, extra_outputs]= get_variable_by_grouping(expsub, expsub_ids, var_name, grouping, grouping_args)

%GET_VARIABLE_BY_GROUPING Get only the valid portion of a variable's data
%according to different grouping method and parameters. For now, there are
%ten different ways of grouping: subject, trial, event, cevent,
%trialevent, trialcevent, subevent_cat, trialevent_cat, subcevent_cat,
%trialcevent_cat; This functions is only for multi-sensory experiments.
%
% USAGE:
% get_variable_by_grouping(EXPSUB, EXPSUB_IDS, VAR_NAME, GROUPING,
%   GROUPING_ARGS)
% 
% INPUT:
%   EXPSUB: a string, indicating whether the following ID list is a
%   experiment IDs list or subject IDs list. Input value can only be 
%   'exp' or 'sub';
% 
%   EXPSUB_IDS: a list of subject IDs or experiment IDs. If user input is a
%   experiment ID list, function LIST_SUBJECTS will be called to convert
%   the experiment ID list into a subject ID list. See also: 
%   LIST_SUBJECTS, FIND_SUBJECTS.
%       
%   VAR_NAME: name of a variable.
% 
%   GROUPING: a string, indicating the method of grouping, eight methods
%   are implemented in this function: subject, trial, event, subjectevent,
%   trialevent, cevent, subjectcevent and trialcevent (see below for 
%   further information);
%
%   GROUPING_ARGS (optional argument): a struct. Certain fields are 
%   requried according to different methods of grouping:
%     GROUPING == 'trial_cat': extract variable based on trial level, then concatenate 
%       the variable chunks together within one subject. 
%       No required fields; Optional field: TRIAL_VALUES (see below for 
%       the meaning and value type of TRIAL_VALUES)
%     GROUPING == 'trial': extract variable based on trial level. 
%       No required fields; Optional field: TRIAL_VALUES (see below for 
%       the meaning and value type of TRIAL_VALUES)
%     GROUPING == 'subject': extract variable based on subject level. 
%       No required fields.
%     GROUPING == 'event': extract variable based on event level for each
%       subject.
%       Required field: EVENT_NAME; Optional fields: WHENCE and INTERVAL 
%       (see below for the meaning and value type of WHENCE and INTERVAL).
%     GROUPING == 'cevent': extract variable based on cevent level with
%       specified cevent values.
%       Required field: CEVENT_NAME, CEVENT_VALUES; 
%       Optional fields: WHENCE, INTERVAL(see below for the meanings 
%       and value types of WHENCE and TRIAL_VALUES).
%     GROUPING == 'trialevent': extract variable based on event level 
%       within each specified trial. *This differs from 'event' in the
%       situation where user only want to extract a subset of trials from
%       each participant.*
%       Required field: EVENT_NAME; Optional fields: WHENCE, INTERVAL and
%       TRIAL_VALUES (see below for the meanings and value types of WHENCE
%       WHENCE and TRIAL_VALUES)
%     GROUPING == 'trialcevent': similar to GROUPING == 'trialevent'.
%     GROUPING == 'subevent_cat': first extract variable based on event
%       level within each subject. And for every subject, concatenate the
%       extracted data into one stream. So the output will be one chunk per
%       subject.
%       Required field: EVENT_NAME; Optional fields: WHENCE and INTERVAL
%       (see below for the meaning and value type of WHENCE and INTERVAL).
%     GROUPING == 'trialevent_cat': first extract variable based on event
%       level within each trial. And for every trial, concatenate the
%       extracted data into one stream. So the output will be one chunk per
%       trial.
%       Required field: EVENT_NAME; Optional fields: WHENCE, INTERVAL and
%       TRIAL_VALUES (see below for the meanings and value types of WHENCE
%       WHENCE and TRIAL_VALUES)
%     GROUPING == 'subcevent_cat': similar to GROUPING == 'subjectevent_cat'.
%     GROUPING == 'trialcevent_cat': similar to GROUPING == 'trialevent_cat'.
% 
%   TRIAL_VALUES 
%       Sometimes there were multiple trials for one subject, by specifying
%       the value of TRIAL_VALUES, user can only output the selected trials
%       for the subject, instead of all trials. The input value can be a 
%       single vector (the same value for all subject), or a cell of 
%       vectors (one vector per each subject).
%       See also: GET_VARIABLE_BY_TRIAL.
%   WHENCE and INTERVAL
%       Value of WHENCE can either be 'start' or 'end'. For example, if
%       WHENCE is 'start' and interval is [-5 0], this means extract data
%       from 5 seconds before the onset to the onset of each event; if
%       WHENCE is 'end' and interval is [-1 3], this mean extract data from
%       1 second before the offset to 3 seconds after the offset of each
%       event. See also: GET_VARIABLE_BY_EVENT, GET_VARIABLE_BY_CEVENT.
% 
%   If type of the target variable is cevent, then two optional parameters
%   can be specified in GROUPING_ARGS:
%   MERGE_THRESH
%       The max gap for merging two cevents, in seconds. See also: 
%       CEVENT_MERGE_SEGMENTS.
%   MIN_DUR_THRESH
%       Cevents whose duration is smaller than this value will be removed.
%       See also: CEVENT_REMOVE_SMALL_SEGMENTS.
%   MAX_DUR_THRESH
%       Cevents whose duration is longer than this value will be removed.
%       See also: CEVENT_REMOVE_LONG_SEGMENTS.
%
%   LOAD_FROM_DIRECTORY
%       The name of a directory, relative to parent subject folder, that
%       contains var_name.
%       E.g. grouping_args.load_from_directory = 'extra_p/sbf';
% 
% OUTPUT:
%   The return value is a cell array of data.
% 
% EXAMPLE:
%   sub_list = list_subjects(18);
%   var_name = 'cont_cam1_all_obj';
%   grouping = 'event';
%   input.event_name = 'event_obj1_inhand_child';
%   input.whence = 'start';
%   input.interval = [-2 0];
%   chunks = get_variable_by_grouping('sub', sub_list, var_name, ...
%       grouping, input)
% Example results:
%   chunks = 
%     [20x2 double]
%       ...
%     [20x2 double] (107*1 cell)
% 
%
%   See also: EXTRACT_RANGES, CELLFUN

if nargin < 4
    error('Not enough input arguments.  See help get_variable_by_grouping.');    
end

if exist('grouping_args', 'var')
    if ~isstruct(grouping_args)
        error(['Argument ''grouping_args'' should be a struct, not ' ...
            class(grouping_args) '.']);
    end
else
    % this line of code is just to prevent from generating errors when
    % script checks whether a certain field exists.
    grouping_args.none_field = 'No information here';
end

% get sub_list according to user input
if strcmp(expsub, 'exp')
    sub_list = [];
    for expidx = 1:length(expsub_ids)
        sub_list = [sub_list; list_subjects(expsub_ids(expidx))];
    end
elseif strcmp(expsub, 'sub')
    sub_list = expsub_ids;
else
    error('Only ''exp'' or ''sub'' are accepted');
end

% if isfield(grouping_args, 'check_var_exist') && grouping_args.check_var_exist
if ~isfield(grouping_args, 'load_from_directory')
    x_has_variable = arrayfun( ...
        @(sub_id) ...
        has_variable(sub_id, var_name), ...
        sub_list, ...
        'UniformOutput', 0);
    x_has_variable_var = vertcat(x_has_variable{:});
else
    x_has_variable_var = arrayfun(@(sub_id) exist(sprintf('%s/%s/%s.mat', get_subject_dir(sub_id), grouping_args.load_from_directory, var_name), 'file') > 0, sub_list);
end

if sum(~x_has_variable_var) > 0
    missvar_sub_list = num2str(sub_list(~x_has_variable_var)');
    fprintf('Variable %s does not exist for subject(s) %s\n', var_name, missvar_sub_list);
end

mask_has_variable = x_has_variable_var;

if ~isempty(strfind(grouping, 'event')) && ~isfield(grouping_args, 'cevent_ranges') && ~isfield(grouping_args, 'event_ranges')
    if isfield(grouping_args, 'cevent_name')
        chunking_var = grouping_args.cevent_name;
    elseif isfield(grouping_args, 'event_name')
        chunking_var = grouping_args.event_name;
    end

    x_has_variable_chunking = arrayfun( ...
        @(sub_id) ...
        has_variable(sub_id, chunking_var), ...
        sub_list, ...
        'UniformOutput', 0);
    x_has_variable_chunking = vertcat(x_has_variable_chunking{:});

    if sum(~x_has_variable_chunking) > 0
        missvar_sub_list = num2str(sub_list(~x_has_variable_chunking)');
        fprintf('Variable %s does not exist for subject(s) %s\n', chunking_var, missvar_sub_list);
    end
    
    mask_has_variable = x_has_variable_var & x_has_variable_chunking;
end

% sub_list_origin = sub_list;
sub_list = sub_list(mask_has_variable);
if isfield(grouping_args, 'event_ranges')
    grouping_args.event_ranges = grouping_args.event_ranges(mask_has_variable);
end
if isfield(grouping_args, 'cevent_ranges')
    grouping_args.cevent_ranges = grouping_args.cevent_ranges(mask_has_variable);
end

extra_outputs.mask_has_variable = mask_has_variable;

% check if fields 'whence' and 'interval' are in pair
if strcmp(grouping, 'event') || strcmp(grouping, 'cevent')
    if ~isfield(grouping_args, 'whence') && isfield(grouping_args, 'interval') || ...
        isfield(grouping_args, 'whence') && ~isfield(grouping_args, 'interval')
        error(['Error! Input should either have both fields of ' ...
            '''whence'' and ''interval'' or neither of them']);
    end
end

% if ~(strcmp(var_data_type, 'cstream') && ...
%         strcmp(grouping, 'cevent'))
%     if isfield(grouping_args, 'cevent_target_matrix')
%         error(['Error! ''cevent_target_matrix'' can only exist when the ' ...
%             'variable type is cstream and to be extracted based on cevents']);
%     end
% end

% grouping methods are changed to equivalent grouping methods
% in order to avoid code redundancy
% if strcmp(grouping, 'subject')
%     grouping = 'trial_cat';
if strcmp(grouping, 'event')
    grouping = 'trialevent';
elseif strcmp(grouping, 'cevent')
    grouping = 'trialcevent';
% elseif strcmp(grouping, 'subevent_cat')
%     grouping = 'trialevent_cat';
% elseif strcmp(grouping, 'subcevent_cat')
%     grouping = 'trialcevent_cat';
end

% % check if trial related fields are set correctly
% if strfind(grouping, 'trial') > 0
%     if (isfield(grouping_args, 'trial_indices') && ...
%             isfield(grouping_args, 'trial_var_name'))
%         error(['The two fields - trial_indices or trial_var_name' ...
%             ' cannot be both set. Only one of them can be set in one extraction']);
%     end
% else
%     if isfield(grouping_args, 'trial_indices')
%         grouping_args = rmfield(grouping_args, 'trial_indices');
%     elseif isfield(grouping_args, 'trial_var_name')
%         grouping_args = rmfield(grouping_args, 'trial_var_name');
%     elseif isfield(grouping_args, 'trial_values')
%         grouping_args = rmfield(grouping_args, 'trial_values');
%     end
% end

if isfield(grouping_args, 'grouping')
    grouping_args.grouping = grouping;
end

var_data_type = get_data_type(var_name);
    
%% extract data into chunks according to different grouping type
switch grouping
    
% GROUPING == 'subject'
% WARNING: this is a special case of extracting data, when people
% want to get original form of data, that may be in danger of extracting
% data outside of trials.
case 'subject'
    warning(['When grouping method is %s, data can be out of trials, ' ...
        'and individual_ranges will still be the trial times'], grouping);
    
    chunks = cell(length(sub_list), 1);
    individual_ranges = cell(length(sub_list), 1);
    individual_range_dur = nan(length(sub_list), 1);
    
%     chunks = get_variable_by_subject(sub_list, var_name);
    
    for sidx = 1:length(sub_list)
        sub_id = sub_list(sidx);
        
        trials_one = get_trial_times(sub_id);
        var_data = get_variable(sub_id, var_name);
        
%         chunk_one = extract_ranges(var_data, ...
%             var_data_type, {trials_one});        
%         chunks{sidx,1} = cell2mat(chunk_one);

        chunks{sidx,1} = var_data;
        individual_ranges{sidx,1} = trials_one;
        individual_range_dur(sidx, 1) = sum(trials_one(:,2) - trials_one(:,1));
    end
    
    extra_outputs.sub_list = sub_list;
    extra_outputs.individual_ranges = individual_ranges;
    extra_outputs.individual_range_dur = individual_range_dur;
    
% GROUPING == 'trial'
case 'trial'    
    chunks = cell(length(sub_list), 1);
    alltrials = cell(length(sub_list), 1);
    csub_list = cell(length(sub_list), 1);
    individual_ranges = cell(length(sub_list), 1);
    individual_range_dur = cell(length(sub_list), 1);
    
    for sidx = 1:length(sub_list)
        sub_id = sub_list(sidx);
        
        trials_one = get_variable(sub_id, 'cevent_trials');
        if isfield(grouping_args, 'trial_values')
            trials_one = cevent_category_equals(...
                trials_one, grouping_args.trial_values);
        end
        
        %         if isfield(grouping_args, 'trial_var_name')
        %             trials_one = get_variable(sub_id, grouping_args.trial_var_name);
        %             if isfield(grouping_args, 'trial_values')
        %                 trials_one = cevent_category_equals(...
        %                     trials_one, grouping_args.trial_values);
        %             end
        %         else
        %             trials_one = get_trial_times(sub_id);
        %
        %             if isfield(grouping_args, 'trial_indices')
        %                 if iscell(grouping_args.trial_indices)
        %                     trials_one = trials_one(grouping_args.trial_indices{sidx}, :);
        %                     trials_one(:,3) = grouping_args.trial_indices{sidx};
        %                 else
        %                     trials_one = trials_one(grouping_args.trial_indices, :);
        %                     trials_one(:,3) = grouping_args.trial_indices;
        %                 end
        %             else
        %                 trials_one(:,3) = 1:size(trials_one, 1);
        %             end
        %         end
        
        root = get_subject_dir(sub_id);
        if isfield(grouping_args, 'load_from_directory')
            filename = sprintf('%s/%s/%s.mat', root, grouping_args.load_from_directory, var_name);
            if exist(filename, 'file')
                load(filename);
                var_data = sdata.data;
            end
        else
            var_data = get_variable(sub_id, var_name);
        end
        chunk_one = extract_ranges(var_data, ...
            var_data_type, {trials_one});
        
        alltrials{sidx,1} = trials_one;
        
        chunks{sidx,1} = chunk_one;
        csub_list{sidx,1} = repmat(sub_id, size(trials_one, 1), 1);
        individual_ranges{sidx,1} = trials_one;
        individual_range_dur{sidx, 1} = trials_one(:,2) - trials_one(:,1);
    end
    
    chunks = vertcat(chunks{:});
    extra_outputs.sub_list = vertcat(csub_list{:});
    extra_outputs.trials = vertcat(alltrials{:});
    extra_outputs.individual_ranges = vertcat(individual_ranges{:});
    extra_outputs.individual_range_dur = vertcat(individual_range_dur{:});
    
    % GROUPING == 'trial_cat'
    case 'trial_cat'
        chunks = cell(length(sub_list), 1);
        individual_ranges = cell(length(sub_list), 1);
        individual_range_dur = nan(length(sub_list), 1);
        
        for sidx = 1:length(sub_list)
            sub_id = sub_list(sidx);
            
            trials_one = get_variable(sub_id, 'cevent_trials');
            if isfield(grouping_args, 'trial_values')
                trials_one = cevent_category_equals(...
                    trials_one, grouping_args.trial_values);
            end
            %
            %         if isfield(grouping_args, 'trial_var_name')
            %             trials_one = get_variable(sub_id, grouping_args.trial_var_name);
            %             if isfield(grouping_args, 'trial_values')
            %                 trials_one = cevent_category_equals(...
            %                     trials_one, grouping_args.trial_values);
            %             end
            %         else
            %             trials_one = get_trial_times(sub_id);
            %
            %             if isfield(grouping_args, 'trial_indices')
            %                 if iscell(grouping_args.trial_indices)
            %                     trials_one = trials_one(grouping_args.trial_indices{sidx}, :);
            %                 else
            %                     trials_one = trials_one(grouping_args.trial_indices, :);
            %                 end
            %             end
            %         end
            
            var_data = get_variable(sub_id, var_name);
            chunk_one = extract_ranges(var_data, ...
                var_data_type, {trials_one});
            chunks{sidx,1} = cell2mat(chunk_one);
            individual_ranges{sidx,1} = trials_one;
            individual_range_dur(sidx) = sum(trials_one(:,2) - trials_one(:,1));
        end
        
        extra_outputs.sub_list = sub_list;
        extra_outputs.individual_ranges = individual_ranges;
        extra_outputs.individual_range_dur = individual_range_dur;
        
        % GROUPING == 'event'
% case 'event'
%     equivalent to 'trialevent' without any trial args

% GROUPING == 'cevent'
% case 'cevent'
%     equivalent to 'trialcevent' without any trial args
    
% GROUPING == 'trialevent'
case 'trialevent'
    chunks = cell(length(sub_list), 1);
    alltrials = cell(length(sub_list), 1);
    csub_list = cell(length(sub_list), 1);
    individual_ranges = cell(length(sub_list), 1);
    individual_range_dur = cell(length(sub_list), 1);
        
    for sidx = 1:length(sub_list)
        sub_id = sub_list(sidx);
        root = get_subject_dir(sub_id);
        if isfield(grouping_args, 'load_from_directory')
            filename = sprintf('%s/%s/%s.mat', root, grouping_args.load_from_directory, var_name);
            if exist(filename, 'file')
                load(filename);
                var_data = sdata.data;
            end
        else
            var_data = get_variable(sub_id, var_name);
        end
        
        trials_one = get_variable(sub_id, 'cevent_trials');
        if isfield(grouping_args, 'trial_values')
            trials_one = cevent_category_equals(...
                trials_one, grouping_args.trial_values);
        end
        
%         if isfield(grouping_args, 'trial_var_name')
%             trials_one = get_variable(sub_id, grouping_args.trial_var_name);
%             if isfield(grouping_args, 'trial_values')
%                 trials_one = cevent_category_equals(...
%                     trials_one, grouping_args.trial_values);
%             end
%         else
%             trials_one = get_trial_times(sub_id);
%             
%             if isfield(grouping_args, 'trial_indices')
%                 if iscell(grouping_args.trial_indices)
%                     trials_one = trials_one(grouping_args.trial_indices{sidx}, :);
%                     trials_one(:,3) = grouping_args.trial_indices{sidx};
%                 else
%                     trials_one = trials_one(grouping_args.trial_indices, :);
%                     trials_one(:,3) = grouping_args.trial_indices;
%                 end
%             else
%                 trials_one(:,3) = 1:size(trials_one, 1);
%             end
%         end
        alltrials{sidx,1} = trials_one;
        if isfield(grouping_args, 'event_name')
            event_data = get_variable(sub_id, grouping_args.event_name);
        elseif isfield(grouping_args, 'event_ranges')
            event_ranges = grouping_args.event_ranges;
            
            if iscell(event_ranges)
                if length(event_ranges) == length(sub_list)
                    event_data = event_ranges{sidx};
                else
                    error(['Input event_ranges and sub_list must have the' ...
                        'length when event_ranges is a cell.']);
                end
            else
                event_data = event_ranges;
            end
        else
            error('Either event_name or event_ranges have to be specified!');
        end
        
        event_data = event_extract_ranges(event_data, trials_one);
        event_data = vertcat(event_data{:});
        
        if ~isempty(event_data)
            if isfield(grouping_args, 'event_min_dur')
                event_dur = event_data(:,2) - event_data(:,1); 
                x_dur_mask = event_dur >= grouping_args.event_min_dur;
                event_data = event_data(x_dur_mask, :);
            end

            if isfield(grouping_args, 'event_max_dur')
                event_dur = event_data(:,2) - event_data(:,1); 
                x_dur_mask = event_dur <= grouping_args.event_max_dur;
                event_data = event_data(x_dur_mask, :);
            end
        
            if isfield(grouping_args, 'whence') && isfield(grouping_args, 'interval')
                event_data = event_relative_intervals(...
                    event_data, grouping_args.whence, grouping_args.interval);
            end
        end
            
        if isfield(grouping_args, 'within_ranges') && ~grouping_args.within_ranges
            event_data = get_event_opposite(sub_id, event_data, trials_one);
        end
        
        if ~isempty(event_data)
            chunks{sidx, 1} = extract_ranges(var_data, ...
                var_data_type, {event_data});
            csub_list{sidx, 1} = repmat(sub_id, size(event_data, 1), 1);
            individual_ranges{sidx, 1} = event_data;
            individual_range_dur{sidx, 1} = event_data(:,2)-event_data(:,1);
        end
    end
    
    chunks = vertcat(chunks{:});
    extra_outputs.trials = vertcat(alltrials{:});
    extra_outputs.sub_list = vertcat(csub_list{:});
    extra_outputs.individual_ranges = vertcat(individual_ranges{:});
    extra_outputs.individual_range_dur = vertcat(individual_range_dur{:});
    
% GROUPING == 'trialcevent'
case 'trialcevent'
    chunks = cell(length(sub_list), 1);
    csub_list = cell(length(sub_list), 1);
    alltrials = cell(length(sub_list), 1);
    individual_ranges = cell(length(sub_list), 1);
    individual_range_dur = cell(length(sub_list), 1);
        
    for sidx = 1:length(sub_list)
        sub_id = sub_list(sidx);
        root = get_subject_dir(sub_id);
        if isfield(grouping_args, 'load_from_directory')
            filename = sprintf('%s/%s/%s.mat', root, grouping_args.load_from_directory, var_name);
            if exist(filename, 'file')
                load(filename);
                var_data = sdata.data;
            end
        else
            var_data = get_variable(sub_id, var_name);
        end
        
        trials_one = get_variable(sub_id, 'cevent_trials');
        if isfield(grouping_args, 'trial_values')
            trials_one = cevent_category_equals(...
                trials_one, grouping_args.trial_values);
        end
        
%         if isfield(grouping_args, 'trial_var_name')
%             trials_one = get_variable(sub_id, grouping_args.trial_var_name);
%             if isfield(grouping_args, 'trial_values')
%                 trials_one = cevent_category_equals(...
%                     trials_one, grouping_args.trial_values);
%             end
%         else
%             trials_one = get_trial_times(sub_id);
%             
%             if isfield(grouping_args, 'trial_indices')
%                 if iscell(grouping_args.trial_indices)
%                     trials_one = trials_one(grouping_args.trial_indices{sidx}, :);
%                     trials_one(:,3) = grouping_args.trial_indices{sidx};
%                 else
%                     trials_one = trials_one(grouping_args.trial_indices, :);
%                     trials_one(:,3) = grouping_args.trial_indices;
%                 end
%             else
%                 trials_one(:,3) = 1:size(trials_one, 1);
%             end
%         end
        alltrials{sidx, 1} = trials_one;
        if isfield(grouping_args, 'cevent_name')
            cevent_data = get_variable(sub_id, grouping_args.cevent_name);
        elseif isfield(grouping_args, 'cevent_ranges')
            cevent_ranges = grouping_args.cevent_ranges;
            
            if iscell(cevent_ranges)
                if size(cevent_ranges, 1) == length(sub_list)
                    cevent_data = cevent_ranges{sidx};
                else
                    error(['Input cevent_ranges and sub_list must have the ' ...
                        'same length when cevent_ranges is a cell.']);
                end
            else
                cevent_data = cevent_ranges;
            end
        else
            error('Either cevent_name or cevent_ranges have to be specified!');
        end

        cevent_data = event_extract_ranges(cevent_data, trials_one);
        cevent_data = vertcat(cevent_data{:});
        
        if ~isempty(cevent_data)
            cevent_data = cevent_category_equals(...
                cevent_data, grouping_args.cevent_values);
            
            if isfield(grouping_args, 'cevent_min_dur')
                cevent_dur = cevent_data(:,2) - cevent_data(:,1);
                x_dur_mask = cevent_dur >= grouping_args.cevent_min_dur;
                cevent_data = cevent_data(x_dur_mask, :);
            end
            
            if isfield(grouping_args, 'cevent_max_dur')
                cevent_dur = cevent_data(:,2) - cevent_data(:,1);
                x_dur_mask = cevent_dur <= grouping_args.cevent_max_dur;
                cevent_data = cevent_data(x_dur_mask, :);
            end
        end
        
        if ~isempty(cevent_data)
            if isfield(grouping_args, 'whence') && isfield(grouping_args, 'interval')
                % when we shift time windows, make sure cevent_data
                % does not split across trials or occurs out of trial.
                % The following code will track indices of cevent as we get just the valid
                % portion. After the time shift, re-extract during
                % trials_one, and filter out cevents with incorrect trial
                % tags (column 4).
                cevent_data_ind = event_extract_ranges(cevent_data, trials_one);
                % trial id tags in columns 4
                cevent_data_ind = cellfun(@(a,b) [a repmat(b, size(a,1), 1)], cevent_data_ind, num2cell(trials_one(:,3)), 'un', 0);
                cevent_data_ind = vertcat(cevent_data_ind{:});
                
                % apply the time shift
                cevent_data_ind = cevent_relative_intervals(...
                    cevent_data_ind, grouping_args.whence, grouping_args.interval);
                % re-extract during trials
                cevent_data_ind = event_extract_ranges(cevent_data_ind, trials_one);
                % find when trial id tag does not match up with trial cell
                % and filter these out
                cevent_data_ind = cellfun(@(a,b) a(a(:,4) == b, [1 2 3]), cevent_data_ind, num2cell(trials_one(:,3)), 'un', 0);
                % recombine all data
                cevent_data = vertcat(cevent_data_ind{:});
            end
            
            if isfield(grouping_args, 'within_ranges') && ~grouping_args.within_ranges
                cevent_data = get_cevent_opposite(sub_id, cevent_data, trials_one);
            end
           
            if ~isempty(var_data)
                chunks{sidx, 1} = extract_ranges(var_data, ...
                    var_data_type, {cevent_data});
                csub_list{sidx, 1} = repmat(sub_id, size(cevent_data, 1), 1);
                individual_ranges{sidx, 1} = cevent_data;
                individual_range_dur{sidx, 1} = cevent_data(:,2)-cevent_data(:,1);
            end
        end
    end
    
    chunks = vertcat(chunks{:});
    extra_outputs.trials = vertcat(alltrials{:});
    extra_outputs.sub_list = vertcat(csub_list{:});
    extra_outputs.individual_ranges = vertcat(individual_ranges{:});
    extra_outputs.individual_range_dur = vertcat(individual_range_dur{:});
    
% GROUPING == 'subevent_cat'
case 'subevent_cat'
    chunks = cell(length(sub_list), 1);
    individual_ranges = cell(length(sub_list), 1);
    individual_range_dur = nan(length(sub_list), 1);
        
    for sidx = 1:length(sub_list)
        sub_id = sub_list(sidx);
        var_data = get_variable(sub_id, var_name);
        
        trials_one = get_variable(sub_id, 'cevent_trials');
        if isfield(grouping_args, 'trial_values')
            trials_one = cevent_category_equals(...
                trials_one, grouping_args.trial_values);
        end
        
%         if isfield(grouping_args, 'trial_var_name')
%             trials_one = get_variable(sub_id, grouping_args.trial_var_name);
%             if isfield(grouping_args, 'trial_values')
%                 trials_one = cevent_category_equals(...
%                     trials_one, grouping_args.trial_values);
%             end
%         else
%             trials_one = get_trial_times(sub_id);
%             
%             if isfield(grouping_args, 'trial_indices')
%                 if iscell(grouping_args.trial_indices)
%                     trials_one = trials_one(grouping_args.trial_indices{sidx}, :);
%                 else
%                     trials_one = trials_one(grouping_args.trial_indices, :);
%                 end
%             end
%         end
        
        if isfield(grouping_args, 'event_name')
            event_data = get_variable(sub_id, grouping_args.event_name);
        elseif isfield(grouping_args, 'event_ranges')
            event_ranges = grouping_args.event_ranges;
            
            if iscell(event_ranges)
                if length(event_ranges) == length(sub_list)
                    event_data = event_ranges{sidx};
                else
                    error(['Input event_ranges and sub_list must have the' ...
                        'length when event_ranges is a cell.']);
                end
            else
                event_data = event_ranges;
            end
        else
            error('Either event_name or event_ranges have to be specified!');
        end
        
        if isfield(grouping_args, 'event_min_dur')
            event_dur = event_data(:,2) - event_data(:,1); 
            x_dur_mask = event_dur >= grouping_args.event_min_dur;
            event_data = event_data(x_dur_mask, :);
        end
        
        if isfield(grouping_args, 'event_max_dur')
            event_dur = event_data(:,2) - event_data(:,1); 
            x_dur_mask = event_dur <= grouping_args.event_max_dur;
            event_data = event_data(x_dur_mask, :);
        end
        
        event_data = event_extract_ranges(event_data, trials_one);
        event_data = vertcat(event_data{:});

        if isfield(grouping_args, 'whence') && isfield(grouping_args, 'interval')
            event_data = event_relative_intervals(...
                event_data, grouping_args.whence, grouping_args.interval);
        end
        
        if isfield(grouping_args, 'within_ranges') && ~grouping_args.within_ranges
            event_data = get_event_opposite(sub_id, event_data, trials_one);
        end

        chunk_tmp = extract_ranges(var_data, ...
            var_data_type, {event_data});
        chunks{sidx, 1} = vertcat(chunk_tmp{:});
        individual_ranges{sidx, 1} = event_data;
        if isempty(event_data)
            individual_range_dur(sidx, 1) = 0;
        else
            individual_range_dur(sidx, 1) = sum(event_data(:,2)-event_data(:,1));
        end
    end
    
    extra_outputs.sub_list = sub_list;
    extra_outputs.individual_ranges = individual_ranges;
    extra_outputs.individual_range_dur = individual_range_dur;
    
% GROUPING == 'trialevent_cat'
case 'trialevent_cat'
    chunks = cell(length(sub_list), 1);
    csub_list = cell(length(sub_list), 1);
    individual_ranges = cell(length(sub_list), 1);
    individual_range_dur = cell(length(sub_list), 1);
        
    for sidx = 1:length(sub_list)
        sub_id = sub_list(sidx);
        var_data = get_variable(sub_id, var_name);
        
        trials_one = get_variable(sub_id, 'cevent_trials');
        if isfield(grouping_args, 'trial_values')
            trials_one = cevent_category_equals(...
                trials_one, grouping_args.trial_values);
        end
        
%         if isfield(grouping_args, 'trial_var_name')
%             trials_one = get_variable(sub_id, grouping_args.trial_var_name);
%             if isfield(grouping_args, 'trial_values')
%                 trials_one = cevent_category_equals(...
%                     trials_one, grouping_args.trial_values);
%             end
%         else
%             trials_one = get_trial_times(sub_id);
%             
%             if isfield(grouping_args, 'trial_indices')
%                 if iscell(grouping_args.trial_indices)
%                     trials_one = trials_one(grouping_args.trial_indices{sidx}, :);
%                 else
%                     trials_one = trials_one(grouping_args.trial_indices, :);
%                 end
%             end
%         end
        
        if isfield(grouping_args, 'event_name')
            event_data = get_variable(sub_id, grouping_args.event_name);
        elseif isfield(grouping_args, 'event_ranges')
            event_ranges = grouping_args.event_ranges;
            
            if iscell(event_ranges)
                if length(event_ranges) == length(sub_list)
                    event_data = event_ranges{sidx};
                else
                    error(['Input event_ranges and sub_list must have the' ...
                        'length when event_ranges is a cell.']);
                end
            else
                event_data = event_ranges;
            end
        else
            error('Either event_name or event_ranges have to be specified!');
        end
        
        if isfield(grouping_args, 'event_min_dur')
            event_dur = event_data(:,2) - event_data(:,1); 
            x_dur_mask = event_dur >= grouping_args.event_min_dur;
            event_data = event_data(x_dur_mask, :);
        end
        
        if isfield(grouping_args, 'event_max_dur')
            event_dur = event_data(:,2) - event_data(:,1); 
            x_dur_mask = event_dur <= grouping_args.event_max_dur;
            event_data = event_data(x_dur_mask, :);
        end
        
        event_data = event_extract_ranges(event_data, trials_one);
        chunk_one = cell(size(trials_one, 1), 1);
        event_dur_one = nan(size(trials_one, 1), 1);

        for tidx = 1:size(trials_one, 1)
            event_data_one = event_data{tidx};

            if isfield(grouping_args, 'whence') && isfield(grouping_args, 'interval')
                event_data_one = event_relative_intervals(...
                    event_data_one, grouping_args.whence, grouping_args.interval);
            end
            
            if isfield(grouping_args, 'within_ranges') && ~grouping_args.within_ranges
                event_data_one = get_event_opposite(sub_id, event_data_one, trials_one(tidx, :));
            end

            chunk_tmp = extract_ranges(var_data, ...
                var_data_type, {event_data_one});
            chunk_one{tidx, 1} = vertcat(chunk_tmp{:});
            if isempty(event_data_one)
                event_dur_one(tidx, 1) = 0;
            else
                event_dur_one(tidx, 1) = sum(event_data_one(:,2)-event_data_one(:,1));
            end
        end
        chunks{sidx, 1} = chunk_one;
        csub_list{sidx, 1} = repmat(sub_id, size(trials_one, 1), 1);
        individual_ranges{sidx, 1} = event_data;
        individual_range_dur{sidx, 1} = event_dur_one;
    end
    
    chunks = vertcat(chunks{:});
    extra_outputs.sub_list = vertcat(csub_list{:});
    extra_outputs.individual_ranges = vertcat(individual_ranges{:});
    extra_outputs.individual_range_dur = vertcat(individual_range_dur{:});

% GROUPING == 'subcevent_cat'
case 'subcevent_cat'
    chunks = cell(length(sub_list), 1);
    individual_ranges = cell(length(sub_list), 1);
    individual_range_dur = nan(length(sub_list), 1);
    chunks_length = cell(length(sub_list), 1);
    for sidx = 1:length(sub_list)
        sub_id = sub_list(sidx);
        var_data = get_variable(sub_id, var_name);
        
        trials_one = get_variable(sub_id, 'cevent_trials');
        if isfield(grouping_args, 'trial_values')
            trials_one = cevent_category_equals(...
                trials_one, grouping_args.trial_values);
        end
        
        if isfield(grouping_args, 'cevent_name')
            cevent_data = get_variable(sub_id, grouping_args.cevent_name);            
        elseif isfield(grouping_args, 'cevent_ranges')
            cevent_ranges = grouping_args.cevent_ranges;
            
            if iscell(cevent_ranges)
                if size(cevent_ranges, 1) == length(sub_list)
                    cevent_data = cevent_ranges{sidx};
                else
                    disp([numel(cevent_ranges) numel(sub_list)]);
                    error(['Input cevent_ranges and sub_list must have the' ...
                        'length when cevent_ranges is a cell.']);
                end
            else
                cevent_data = cevent_ranges;
            end
        else
            error('Either cevent_name or cevent_ranges have to be specified!');
        end
             
        cevent_data = cevent_category_equals(...
            cevent_data, grouping_args.cevent_values);
        
        if isfield(grouping_args, 'cevent_min_dur')
            cevent_dur = cevent_data(:,2) - cevent_data(:,1); 
            x_dur_mask = cevent_dur >= grouping_args.cevent_min_dur;
            cevent_data = cevent_data(x_dur_mask, :);
        end
        
        if isfield(grouping_args, 'cevent_max_dur')
            cevent_dur = cevent_data(:,2) - cevent_data(:,1); 
            x_dur_mask = cevent_dur <= grouping_args.cevent_max_dur;
            cevent_data = cevent_data(x_dur_mask, :);
        end
        
        cevent_data = event_extract_ranges(cevent_data, trials_one);
        cevent_data = vertcat(cevent_data{:});

        if isfield(grouping_args, 'whence') && isfield(grouping_args, 'interval')
            cevent_data = event_relative_intervals(...
                cevent_data, grouping_args.whence, grouping_args.interval);
        end
            
        if isfield(grouping_args, 'within_ranges') && ~grouping_args.within_ranges
            cevent_data = get_cevent_opposite(sub_id, cevent_data, trials_one);
        end

        chunk_tmp = extract_ranges(var_data, var_data_type, {cevent_data}); 
        chunks_length{sidx,1} = chunk_tmp;
        chunks{sidx, 1} = vertcat(chunk_tmp{:});
        individual_ranges{sidx, 1} = cevent_data;
        individual_range_dur(sidx, 1) = sum(cevent_data(:,2)-cevent_data(:,1));
    end
    
    extra_outputs.sub_list = sub_list;
    extra_outputs.individual_ranges = individual_ranges;
    extra_outputs.individual_range_dur = individual_range_dur;
    extra_outputs.chunks_pre_cat = chunks_length;
    
% GROUPING == 'trialcevent_cat'
case 'trialcevent_cat'
    chunks = cell(length(sub_list), 1);
    csub_list = cell(length(sub_list), 1);
    individual_ranges = cell(length(sub_list), 1);
    individual_range_dur = cell(length(sub_list), 1);
    for sidx = 1:length(sub_list)
        sub_id = sub_list(sidx);
        var_data = get_variable(sub_id, var_name);
        
        trials_one = get_variable(sub_id, 'cevent_trials');
        if isfield(grouping_args, 'trial_values')
            trials_one = cevent_category_equals(...
                trials_one, grouping_args.trial_values);
        end
        
%         if isfield(grouping_args, 'trial_var_name')
%             trials_one = get_variable(sub_id, grouping_args.trial_var_name);
%             if isfield(grouping_args, 'trial_values')
%                 trials_one = cevent_category_equals(...
%                     trials_one, grouping_args.trial_values);
%             end
%         else
%             trials_one = get_trial_times(sub_id);
%             
%             if isfield(grouping_args, 'trial_indices')
%                 if iscell(grouping_args.trial_indices)
%                     trials_one = trials_one(grouping_args.trial_indices{sidx}, :);
%                 else
%                     trials_one = trials_one(grouping_args.trial_indices, :);
%                 end
%             end
%         end
        
        if isfield(grouping_args, 'cevent_name')
            cevent_data = get_variable(sub_id, grouping_args.cevent_name);            
        elseif isfield(grouping_args, 'cevent_ranges')
            cevent_ranges = grouping_args.cevent_ranges;
            
            if iscell(cevent_ranges)
                if size(cevent_ranges, 1) == length(sub_list)
                    cevent_data = cevent_ranges{sidx};
                else
                    error(['Input cevent_ranges and sub_list must have the' ...
                        'length when cevent_ranges is a cell.']);
                end
            else
                cevent_data = cevent_ranges;
            end
        else
            error('Either cevent_name or cevent_ranges have to be specified!');
        end
             
        cevent_data = cevent_category_equals(...
            cevent_data, grouping_args.cevent_values);
        
        if isfield(grouping_args, 'cevent_min_dur')
            cevent_dur = cevent_data(:,2) - cevent_data(:,1); 
            x_dur_mask = cevent_dur >= grouping_args.cevent_min_dur;
            cevent_data = cevent_data(x_dur_mask, :);
        end
        
        if isfield(grouping_args, 'cevent_max_dur')
            cevent_dur = cevent_data(:,2) - cevent_data(:,1); 
            x_dur_mask = cevent_dur <= grouping_args.cevent_max_dur;
            cevent_data = cevent_data(x_dur_mask, :);
        end
        
        cevent_data = event_extract_ranges(cevent_data, trials_one);
        chunk_one = cell(size(trials_one, 1), 1);
        cevent_dur_one = nan(size(trials_one, 1), 1);

        for tidx = 1:size(trials_one, 1)
            cevent_data_one = cevent_data{tidx};

            if isfield(grouping_args, 'whence') && isfield(grouping_args, 'interval')
                cevent_data_one = event_relative_intervals(...
                    cevent_data_one, grouping_args.whence, grouping_args.interval);
            end
            
            if isfield(grouping_args, 'within_ranges') && ~grouping_args.within_ranges
                cevent_data_one = get_cevent_opposite(sub_id, cevent_data_one, trials_one(tidx, :));
            end

            chunk_tmp = extract_ranges(var_data, ...
                var_data_type, {cevent_data_one});
            chunk_one{tidx, 1} = vertcat(chunk_tmp{:});
            cevent_dur_one(tidx, 1) = sum(cevent_data_one(:,2)-cevent_data_one(:,1));
        end
        chunks{sidx, 1} = chunk_one;
        csub_list{sidx, 1} = repmat(sub_id, size(trials_one, 1), 1);
        individual_ranges{sidx, 1} = cevent_data;
        individual_range_dur{sidx, 1} = cevent_dur_one;
    end
    
    chunks = vertcat(chunks{:});
    extra_outputs.sub_list = vertcat(csub_list{:});
    extra_outputs.individual_ranges = vertcat(individual_ranges{:});
    extra_outputs.individual_range_dur = vertcat(individual_range_dur{:});
    
% otherwise...
otherwise
    error(['Error! Grouping type can only be: ''subject'', ''trial'',' ...
        ' ''trial_cat'', ''event'', ''cevent'', ''trialevent'', ''trialcevent'',' ...
        ' ''subevent_cat'', ''subcevent_cat'', '...
        ' ''trialcevent_cat'', or ''trialcevent_cat''']);
end

%% filtering after extraction

if (strcmp(var_data_type, 'cont') || strcmp(var_data_type, 'cstream')) && ...
        isfield(grouping_args, 'data_quality_thresh')
    x_data_quality_thresh = true(size(chunks), 1);
    for cidx = 1:length(chunks)
        chunk_one = chunks{cidx};
        if size(chunk_one, 1) > 0
            validity = ~isnan(chunk_one(:,2));
            if validity < grouping_args.data_quality_thresh
                chunk_one = zeros(0,2);
                x_data_quality_thresh(cidx) = false;
            end
        end
        chunks{cidx} = chunk_one;
    end
    
    chunks = chunks(x_data_quality_thresh, :);
    extra_outputs.sub_list = extra_outputs.sub_list(x_data_quality_thresh, :);
    extra_outputs.individual_ranges = ...
        extra_outputs.individual_ranges(x_data_quality_thresh, :);
    extra_outputs.individual_range_dur = ...
        extra_outputs.individual_range_dur(x_data_quality_thresh, :);
end

if (strcmp(var_data_type, 'cstream') && isfield(grouping_args, 'convert_cstream2cevent')) ...
        && grouping_args.convert_cstream2cevent
    if isfield(grouping_args, 'convert_cstream_max_gap')
        cstream_max_gap = grouping_args.convert_cstream_max_gap;
    else
        cstream_max_gap = 0.5;
    end
    chunks_new = cell(size(chunks));
    for cidx = 1:length(chunks)
        chunk_one = cstream2cevent(chunks{cidx}, cstream_max_gap);
        chunks_new{cidx} = chunk_one;
    end
    chunks = chunks_new;
end

if (strcmp(var_data_type, 'event') && isfield(grouping_args, 'convert_event2cevent')) ...
        && grouping_args.convert_event2cevent
    event_value = grouping_args.event2cevent_value;
    chunks_new = cell(size(chunks));
    for cidx = 1:length(chunks)
        chunk_one = chunks{cidx};
        chunks_new{cidx} = [chunk_one repmat(event_value, size(chunk_one, 1), 1)];
    end
    chunks = chunks_new;
end

% If user doesn't want the empty chunks
if isfield(grouping_args, 'remove_empty_chunks') && grouping_args.remove_empty_chunks ...
        && ~isempty(chunks)
    x_empty_chunks = cellfun( ...
        @(chunk_one) isempty(chunk_one), chunks, ...
        'UniformOutput', 0);
    x_empty_chunks = cell2mat(x_empty_chunks);
    
    chunks = chunks(~x_empty_chunks, :);
    extra_outputs.sub_list = extra_outputs.sub_list(~x_empty_chunks, :);
    extra_outputs.individual_ranges = ...
        extra_outputs.individual_ranges(~x_empty_chunks, :);
    extra_outputs.individual_range_dur = ...
        extra_outputs.individual_range_dur(~x_empty_chunks, :);
end

% if isfield(grouping_args, 'fill_empty_with_nan') && grouping_args.fill_empty_with_nan
%     pause
%     chunks
%     extra_outputs
% end

% If type of the target variable is cevent, then the extracted chunks can 
% be further filtered according to MERGE_THRESH and MIN_DUR_THRESH
if (strcmp(var_data_type, 'cevent') || strcmp(var_data_type, 'event')) && ...
    (isfield(grouping_args, 'merge_thresh') || ...
     isfield(grouping_args, 'min_dur_thresh') || isfield(grouping_args, 'max_dur_thresh'))
 
    for cidx = 1:length(chunks)
        chunk_one = chunks{cidx};
        if isfield(extra_outputs, 'chunks_pre_cat')
            chunk_two = extra_outputs.chunks_pre_cat{cidx};
            if size(chunk_two) > 0
                if isfield(grouping_args, 'merge_thresh')
                    chunk_two = cellfun(@(a) cevent_merge_segments(...
                        a, grouping_args.merge_thresh,unique(a(:,3))'), chunk_two, 'un', 0);
                end
                if isfield(grouping_args, 'min_dur_thresh')
                    chunk_two = cellfun(@(a) cevent_remove_small_segments(...
                        a, grouping_args.min_dur_thresh), chunk_two, 'un', 0);
                end
                if isfield(grouping_args, 'max_dur_thresh')
                    chunk_two = cellfun(@(a) cevent_remove_long_segments(...
                        a, grouping_args.max_dur_thresh), chunk_two, 'un', 0);
                end
                extra_outputs.chunks_pre_cat{cidx} = chunk_two;
            end
        end
        if size(chunk_one, 1) > 0
            if isfield(grouping_args, 'merge_thresh')
                chunk_one = cevent_merge_segments(...
                    chunk_one, grouping_args.merge_thresh, unique(chunk_one(:,3))');
            end
            if isfield(grouping_args, 'min_dur_thresh')
                chunk_one = cevent_remove_small_segments(...
                    chunk_one, grouping_args.min_dur_thresh);
            end
            if isfield(grouping_args, 'max_dur_thresh')
                chunk_one = cevent_remove_long_segments(...
                    chunk_one, grouping_args.max_dur_thresh);
            end
        end
        chunks{cidx} = chunk_one;
    end
end

if isfield(grouping_args, 'is_reassign_categories') && grouping_args.is_reassign_categories
    chunks_new = cell(size(chunks));
    if strcmp(var_data_type, 'cevent')
        for cidx = 1:length(chunks)
            chunk_one = chunks{cidx};
            chunk_one = cevent_reassign_categories(chunk_one, grouping_args.old_roi_list, grouping_args.new_roi_list);
            chunks_new{cidx} = chunk_one;
        end
    end
    chunks = chunks_new;
end