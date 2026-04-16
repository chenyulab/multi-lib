function output = make_all_type_variables(subID, varargin)
% make_all_type_variables
%
% General function for generating one overall type variable and multiple
% type-specific cevent variables from a coding file.
%
% -------------------------------------------------------------------------
% OUTPUT VARIABLE RULE
% -------------------------------------------------------------------------
% This function uses one variable name template:
%
%   variable_name_template = 'cevent_speech_%s_parent'
%
% Then:
%   %s = 'enter-type'   -> overall type variable
%   %s = 'cat-1'        -> type-specific variable for type ID 1
%   %s = 'cat-2'        -> type-specific variable for type ID 2
%   ...
%
% Example generated variables:
%   cevent_speech_enter-type_parent
%   cevent_speech_cat-1_parent
%   cevent_speech_cat-2_parent
%
% -------------------------------------------------------------------------
% DATA FORMAT
% -------------------------------------------------------------------------
% Overall variable:
%   [onset offset typeID]
%
% Type-specific variables:
%   [onset offset objectID]
%
% All outputs are numeric 3-column cevent matrices.
%
% -------------------------------------------------------------------------
% MULTIPLE OBJECT COLUMNS
% -------------------------------------------------------------------------
% If one row in the coding file contains multiple object columns, for example:
%
%   [30, 35, typeA, obj1, obj2]
%
% then the type-specific variable will store:
%
%   [30, 35, obj1;
%    30, 35, obj2]
%
% -------------------------------------------------------------------------
% REQUIRED EXTERNAL FUNCTIONS
% -------------------------------------------------------------------------
%   get_subject_dir(subID)
%   get_experiment_dir(subID)
%   record_additional_variable(subID, varName, data)
%
% -------------------------------------------------------------------------
% REQUIRED INPUTS (name-value)
% -------------------------------------------------------------------------
%   'coding_file_pattern'         : file name under subject/supporting_files
%   'type_mapping_file_name'   : file name under experiment directory
%   'variable_name_template'   : e.g. 'cevent_speech_%s_parent'
%
% -------------------------------------------------------------------------
% OPTIONAL INPUTS
% -------------------------------------------------------------------------
%   'object_mapping_file_name' : file name under experiment directory
%
%   'coding_readtable_args'    : cell, extra args for readtable
%   'type_mapping_readtable_args'
%   'object_mapping_readtable_args'
%
% Coding file columns:
%   'onset_col'    default 1
%   'offset_col'   default 2
%   'type_col'     default 3
%   'obj_cols'     default [4 5]
%
% Type mapping file columns:
%   'type_label_col' default 1
%   'type_id_col'    default 2
%
% Object mapping file columns:
%   'object_label_col' default 1
%   'object_id_col'    default 2
%
% Naming:
%   'enter_type_suffix' default 'enter-type'
%   'cat_prefix'        default 'cat-%d'
%
% Behavior:
%   'skip_missing_type'      default false
%   'skip_missing_object'    default true
%   'record_empty_variable'  default true

    %% parse inputs
    p = inputParser;
    p.FunctionName = mfilename;

    addRequired(p, 'subID', @(x) isnumeric(x) && isscalar(x));

    % file names
    addParameter(p, 'coding_dir_candidates', {'supporting_files'}, @iscell);
    addParameter(p, 'coding_file_pattern', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'type_mapping_file_name', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'object_mapping_file_name', '', @(x) isempty(x) || ischar(x) || isstring(x));

    % variable naming
    addParameter(p, 'variable_name_template', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'enter_type_suffix', 'enter-type', @(x) ischar(x) || isstring(x));
    addParameter(p, 'cat_prefix', 'cat-%d', @(x) ischar(x) || isstring(x));

    % readtable args
    addParameter(p, 'coding_readtable_args', {}, @iscell);
    addParameter(p, 'type_mapping_readtable_args', {}, @iscell);
    addParameter(p, 'object_mapping_readtable_args', {}, @iscell);

    % coding file columns
    addParameter(p, 'onset_col', 1, @(x) isnumeric(x) && isscalar(x));
    addParameter(p, 'offset_col', 2, @(x) isnumeric(x) && isscalar(x));
    addParameter(p, 'type_col', 4, @(x) isnumeric(x) && isscalar(x));
    addParameter(p, 'obj_cols', [5 6], @(x) isnumeric(x) && ~isempty(x));
    addParameter(p, 'time_unit_scale', 1, @(x) isnumeric(x) && isscalar(x));

    % type mapping file columns
    addParameter(p, 'type_label_col', 1, @(x) isnumeric(x) && isscalar(x));
    addParameter(p, 'type_id_col', 2, @(x) isnumeric(x) && isscalar(x));

    % object mapping file columns
    addParameter(p, 'object_label_col', 1, @(x) isnumeric(x) && isscalar(x));
    addParameter(p, 'object_id_col', 2, @(x) isnumeric(x) && isscalar(x));

    % behavior
    addParameter(p, 'skip_missing_type', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'skip_missing_object', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'record_empty_variable', true, @(x) islogical(x) || isnumeric(x));

    parse(p, subID, varargin{:});
    opt = p.Results;

    %% basic checks
    if strlength(string(opt.coding_file_pattern)) == 0
        error('coding_file_pattern is required.');
    end

    if strlength(string(opt.type_mapping_file_name)) == 0
        error('type_mapping_file_name is required.');
    end

    if strlength(string(opt.variable_name_template)) == 0
        error('variable_name_template is required.');
    end

    if ~contains(char(opt.variable_name_template), '%s')
        error('variable_name_template must contain one %%s.');
    end

    %% build paths
    subject_dir = get_subject_dir(subID);

    timing = get_timing(subID);
    trial_offset = timing.speechTime;

    file_found = false;
    coding_file_path = '';
    
    for i = 1:length(opt.coding_dir_candidates)
    
        current_dir = fullfile(subject_dir, opt.coding_dir_candidates{i});
    
        if ~exist(current_dir, 'dir')
            continue;
        end
    
        file_list = dir(fullfile(current_dir, char(opt.coding_file_pattern)));
    
        if ~isempty(file_list)
    
            if length(file_list) > 1
                warning('Multiple files found in %s, using the first one: %s', ...
                    current_dir, file_list(1).name);
            end
    
            coding_file_name = file_list(1).name;
            coding_file_path = fullfile(current_dir, coding_file_name);
    
            file_found = true;
            break;
        end
    end
    
    if ~file_found
        error('No coding file found matching pattern: %s in any candidate directories.', ...
            opt.coding_file_pattern);
    end

    type_mapping_file_path = fullfile(get_experiment_dir(subID), char(opt.type_mapping_file_name));

    hasObjectMapping = strlength(string(opt.object_mapping_file_name)) > 0;
    if hasObjectMapping
        object_mapping_file_path = fullfile(get_experiment_dir(subID), char(opt.object_mapping_file_name));
    else
        object_mapping_file_path = '';
    end

    %% read tables
    codingTable = readtable(coding_file_path, opt.coding_readtable_args{:});
    typeMapTable = readtable(type_mapping_file_path, opt.type_mapping_readtable_args{:});

    if hasObjectMapping
        objectMapTable = readtable(object_mapping_file_path, opt.object_mapping_readtable_args{:});
    else
        objectMapTable = table();
    end

    %% build type mapping info
    nTypes = height(typeMapTable);

    typeInfo = struct( ...
        'label_raw', cell(nTypes,1), ...
        'label_key', cell(nTypes,1), ...
        'id', cell(nTypes,1), ...
        'suffix', cell(nTypes,1), ...
        'var_name', cell(nTypes,1), ...
        'field_name', cell(nTypes,1));

    for i = 1:nTypes
        rawLabel = typeMapTable{i, opt.type_label_col};
        rawID = typeMapTable{i, opt.type_id_col};
        typeID = double(rawID);

        suffix = sprintf(char(opt.cat_prefix), typeID);
        varName = sprintf(char(opt.variable_name_template), suffix);
        fieldName = matlab.lang.makeValidName(suffix);

        typeInfo(i).label_raw = rawLabel;
        typeInfo(i).label_key = normalize_key(rawLabel);
        typeInfo(i).id = typeID;
        typeInfo(i).suffix = suffix;
        typeInfo(i).var_name = varName;
        typeInfo(i).field_name = fieldName;
    end

    %% build object mapping
    if hasObjectMapping
        objectLabels = objectMapTable{:, opt.object_label_col};
        objectIDs = objectMapTable{:, opt.object_id_col};
    end

    %% initialize outputs
    overallData = [];
    perTypeData = struct();

    for i = 1:nTypes
        perTypeData.(typeInfo(i).field_name) = [];
    end

    %% main loop
    for r = 1:height(codingTable)

        onset = codingTable{r, opt.onset_col};
        offset = codingTable{r, opt.offset_col};

        if ~is_valid_numeric_scalar(onset) || ~is_valid_numeric_scalar(offset)
            continue;
        end

        onset = double(onset)*opt.time_unit_scale + trial_offset;
        offset = double(offset)*opt.time_unit_scale + trial_offset;

        rawType = codingTable{r, opt.type_col};
        [typeID, typeIdx, foundType] = resolve_type_id(rawType, typeInfo);

        if ~foundType
            msg = sprintf('Type not found at row %d. Raw value = %s', ...
                r, value_to_string(rawType));
            if opt.skip_missing_type
                warning(msg);
                continue;
            else
                error(msg);
            end
        end

        % record overall type variable
        overallData = [overallData; onset, offset, typeID]; %#ok<AGROW>

        % resolve object IDs from all object columns
        rowObjectIDs = [];

        for c = opt.obj_cols
            rawObj = codingTable{r, c};

            if is_empty_value(rawObj)
                continue;
            end

            [objID, foundObj] = resolve_object_id(rawObj, hasObjectMapping);

            if ~foundObj
                msg = sprintf('Object not found at row %d, col %d. Raw value = %s', ...
                    r, c, value_to_string(rawObj));
                if opt.skip_missing_object
                    warning(msg);
                    continue;
                else
                    error(msg);
                end
            end

            rowObjectIDs = [rowObjectIDs; objID]; %#ok<AGROW>
        end

        % remove duplicates while keeping order
        rowObjectIDs = unique(rowObjectIDs, 'stable');

        % record to the type-specific variable
        thisField = typeInfo(typeIdx).field_name;
        for k = 1:numel(rowObjectIDs)
            perTypeData.(thisField) = [perTypeData.(thisField); onset, offset, rowObjectIDs(k)];
        end
    end

    %% record variables
    overall_var_name = sprintf(char(opt.variable_name_template), char(opt.enter_type_suffix));

    if opt.record_empty_variable || ~isempty(overallData)
        record_additional_variable(subID, overall_var_name, overallData);
    end

    for i = 1:nTypes
        thisVarName = typeInfo(i).var_name;
        thisField = typeInfo(i).field_name;
        thisData = perTypeData.(thisField);

        if opt.record_empty_variable || ~isempty(thisData)
            record_additional_variable(subID, thisVarName, thisData);
        end
    end

    %% output summary
    output = struct();
    output.overall_var_name = overall_var_name;
    output.overall_data = overallData;
    output.per_type_data = perTypeData;
    output.type_info = typeInfo;
    output.coding_file_path = coding_file_path;
    output.type_mapping_file_path = type_mapping_file_path;
    output.object_mapping_file_path = object_mapping_file_path;

    %% helper functions
    function [typeID, idx, found] = resolve_type_id(rawValue, info)
        found = false;
        idx = NaN;
        typeID = NaN;
    
        % normalize input once
        raw_word = strtrim(string(rawValue{1}));
    
        for ii = 1:numel(info)
            w = strtrim(string(info(ii).label_raw{1}));
    
            if strcmpi(raw_word, w)
                idx = ii;
                typeID = info(ii).id;
                found = true;
                return;
            end
        end
    end

    function [objID, found] = resolve_object_id(rawValue, useMap)
        found = false;
        objID = NaN;

        % numeric object directly
        if is_valid_numeric_scalar(rawValue)
            rawNum = double(rawValue);

            if ~useMap
                objID = rawNum;
                found = true;
                return;
            end

            if any(double(objectIDs) == rawNum)
                objID = rawNum;
                found = true;
                return;
            end
        end

        if ~useMap
            return;
        end

        rawKey = rawValue;

        for ii = 1:numel(objectIDs)
            if strcmp(rawKey, objectLabels(ii))
                objID = double(objectIDs(ii));
                found = true;
                return;
            end
        end
    end

    function tf = is_valid_numeric_scalar(v)
        tf = isnumeric(v) && isscalar(v) && ~isnan(v);
    end

    function tf = is_empty_value(v)
        if isempty(v)
            tf = true;
        elseif isnumeric(v) && isscalar(v) && isnan(v)
            tf = true;
        elseif ismissing(v)
            tf = true;
        elseif ischar(v) || isstring(v)
            tf = strlength(strtrim(string(v))) == 0;
        else
            tf = false;
        end
    end

    function key = normalize_key(v)
        key = lower(strtrim(string(v)));
        key = regexprep(key, '\s+', ' ');
        key = char(key);
    end

    function s = value_to_string(v)
        if isnumeric(v)
            s = mat2str(v);
        else
            s = char(string(v));
        end
    end
end