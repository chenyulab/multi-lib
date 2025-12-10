function [fchunks, fextra, fstats, args] = get_chunks_at_test(var_name, subexpID, args)
% This function will extract the data in var_name during the provided time
% window. By default, the time window is simply all of the trials for that
% subject.
% e.g. Type into the command line the following,
%
% >>[chunks, extra, stats] = get_chunks('cevent_inhand_child', 4301)
%
% the output will be,
% 
%           chunks = 
% 
%               [22x3 double]
%               [26x3 double]
%               [13x3 double]
%               [13x3 double]
% 
% 
%           extra = 
% 
%               individual_ranges: [4x3 double]
%               mask_has_variable: 1
%               sub_list: [4x1 double]
% 
% 
%           stats = 
% 
%               [1x1 struct]
%
% 
% 
% chunks is a cell array of size 4 x 1, each containing inhand data for one
% trial
%
% extra is a structure that gives information about how data was extracted.
% For instance, extra.individual_ranges gives the exact time windows of the
% 4 trials.
%
% stats is a structure returned from the _cal_stats.m functions that shows
% basic statistics of the extracted data
%
% One can define a different time window instead of using the default
% trials. The most common way is to specify a cevent variable.
%
% >>args.cevent_name = 'cevent_speech_naming_local-id';
% >>args.cevent_values = 1:3;
% >>[chunks, extra, stats] = get_chunks('cevent_inhand_child', 4301, args)
%
% the output will be,
% 
%           chunks = 
% 
%               [1x3 double]
%               [2x3 double]
%               [2x3 double]
%                   ...
%                   ...
%               [0x3 double]
%               [0x3 double]
%               [0x3 double]
% 
% 
%           extra = 
% 
%               individual_ranges: [47x3 double]
%               mask_has_variable: 1
%               sub_list: [47x1 double]
% 
% 
%           stats = 
% 
%               [1x1 struct]
%
% Now chunks is a cell array of size 47 x 1, each containing inhand data during
% one of the naming instances.
%
% Below is a list of additional arg paramaters that can be specified. Most
% of the paramters modify the time window in some manner before extracting data.
%
% For instance, using
%   args.cevent_min_dur = 2
% will first eliminate all of the naming instances shorter than 2 seconds,
% and then do the extraction using the remaining instances.
% 
% chunks now outputs a cell array of size 18 x 1
%
%
%
%% LIST OF ARGS FOR GET_VARIABLE_BY_GROUPING (10/12/2015)
%{

args.cevent_name
        -- e.g. 'cevent_speech_naming_local-id'

args.cevent_values
        -- e.g. [1 2 3]

args.cevent_ranges
        -- e.g. {[30 35 1;
                  35 40 2;
                  37 42 2;]};

args.whence
        -- options 'start' or 'end'

args.interval
        -- e.g. [-5 0] or [-2 3]

args.cevent_min_dur
        -- e.g. 2

args.cevent_max_dur
        -- e.g. 5

args.load_from_directory
        -- e.g. 'extra_p/sbf'

args.trial_indices
args.trial_var_name
args.trial_values
args.event_min_dur
args.event_max_dur
args.within_ranges 

args.event_name (See args.cevent_name)
args.event_ranges (See args.cevent_ranges)
args.data_quality_thresh 
args.convert_cstream2cevent
args.cont_cstream_max_gap 
args.convert_event2cevent
args.remove_empty_chunks 
args.merge_thresh 
args.min_dur_thresh
args.max_dur_thresh 
args.is_reassign_categories


%}

%%


if strfind(var_name, 'demo')
    switch var_name
        case 'demo0'
            var_name = 'cont_vision_size_obj#_child';
            subexpID = [4301 4302];
        case 'demo1'
            var_name = 'cont_vision_size_obj#_child';
            subexpID = [4301 4302];
        case 'demo2'
            var_name = 'cevent_inhand_child';
            subexpID = [4301 4302];
        case 'demo3'
            var_name = 'cevent_inhand_child';
            subexpID = [4301 4302];
        case 'demo4'
            var_name = 'cont_vision_size_obj#_child';
            subexpID = [4301 4302];
            args.cevent_name = 'cevent_inhand_child';
            args.cevent_values = 1:3;
            args.label_matrix = [1 2 2; 2 1 2; 2 2 1];
        case 'demo5'
            var_name = 'cevent_inhand_child';
            subexpID = 4301;
            args.cevent_name = 'cevent_speech_naming_local-id';
            args.cevent_values = 1:3;
            args.label_matrix = [1 2 2 3; 2 1 2 3; 2 2 1 3];
        case 'demo6'
            var_name = 'cevent_eye_roi_with-parent_child';
            subexpID = [72];
            args.load_from_directory = 'extra_p/csuarez';
        otherwise
            error('%s was not a valid case option', var_name);
    end
end
if ~exist('args', 'var') || isempty(args)
%     args = [];
    args = struct;
end

if isfield(args, 'label_matrix')
    lmflag = 1;
    width = numel(unique(args.label_matrix));
else
    width = 1;
    lmflag = 0;
end

if ~isempty(strfind(var_name, 'obj#'))
    objflag = 1;
else
    objflag = 0;
end

if isfield(args, 'cevent_name') || isfield(args, 'cevent_ranges')
    grouping = 'trialcevent';
elseif isfield(args, 'event_name') || isfield(args, 'event_ranges')
    grouping = 'trialevent';
else
    grouping = 'trial';
end

fstats = cell(1,width);
fchunks = cell(1,width);
fextra = [];

subs = cIDs(subexpID);

dt = get_data_type(var_name);

fprintf('\n args for %s:\n', var_name);

disp(args);

all_data_chunks = cell(numel(subs), 1);
data_extras = cell(numel(subs), 1);
% allnumobj = get_num_obj(subs);
for s = 1:numel(subs)
    expid = sub2exp(subs(s));
    if ismember(expid, [18 23])
        numobj = 5;
    elseif ismember(expid, 12)
        numobj = 27;
    else
        numobj = 3;
    end
    
    if ~isempty(strfind(var_name, 'obj#'))
        allvars = arrayfun(@(a) strrep(var_name, 'obj#', sprintf('obj%d', a)), 1:numobj, 'un', 0);
        numallvars = numel(allvars);
    elseif ~isempty(strfind(var_name, '#'))
        allvars = arrayfun(@(a) strrep(var_name, '#', sprintf('obj%d', a)), 1:numobj, 'un', 0);
        allvars = cat(2, allvars, {strrep(var_name, '#', 'head')});
        numallvars = numel(allvars);
    else
        allvars = {var_name};
        numallvars = 1;
    end
    
    chunks = cell(numel(allvars),1);
    for v = 1:numel(allvars)
        [chunks{v,1}, extras] = get_variable_by_grouping_at_test('sub', subs(s), allvars{v}, grouping, args);
        if ~iscell(chunks{v,1})
            return
        end
    end
    if strcmp(dt, 'cstream')
        chunks = cellfun(@(a) cellfun(@(b) cstream2cevent(b), a, 'un', 0), chunks, 'un', 0);
        dt = 'cevent';
    end
    chunks = horzcat(chunks{:});
    if ~isempty(chunks)
        if strcmp(grouping, 'trial') && size(extras.individual_ranges, 2) < 3
            extras.individual_ranges(:,3) = 1:size(extras.individual_ranges, 1);
        end
        if lmflag
            if numallvars == 1
                tmp = cell(1,size(args.label_matrix, 2));
                for o = 1:size(args.label_matrix, 2)
                    tmp{1,o} = cellfun(@(a) a(a(:,end) == o, :), chunks, 'un', 0);
                end
                chunks = horzcat(tmp{:});
            end
            
            if isfield(args, 'cevent_name') || isfield(args, 'cevent_ranges')
                if size(extras.individual_ranges, 2) > 2
                    label_matrix = args.label_matrix;
                    targets = extras.individual_ranges;
                    %                 label_matrix = label_matrix(args.cevent_values, :);
                    [chunks, targets] = get_chunks_target(chunks, targets, label_matrix, dt);
                    extras.individual_ranges = targets;
                    extras.individual_range_dur = targets(:,2)-targets(:,1);
                    extras.sub_list = repmat(subs(s), size(targets, 1), 1);
                else
                    error('cevent_name or cevent_ranges data has ben converted to an event due to a specific parameter, the label_matrix cannot be specified in this case');
                end
            else
                error('label matrix should be only be indicated when specifying cevent_name or cevent_ranges');
            end
        elseif objflag
            label_matrix = ones(size(chunks, 1), numallvars);
            targets = ones(size(chunks, 1), 1);
            [chunks, ~] = get_chunks_target(chunks, targets, label_matrix, dt);
            extras.sub_list = repmat(subs(s), size(targets, 1), 1);
        end
        all_data_chunks{s,:} = chunks;
    end
    
    data_extras{s,1} = extras;
end
log = cellfun(@isempty, all_data_chunks);
all_data_chunks(log) = [];
data_extras(log) = [];

if ~isempty(all_data_chunks)
    for w = 1:width
        data_chunks = cellfun(@(a) a(:,w), all_data_chunks, 'un', 0);
        
        tmp_subs = cellfun(@(a) a.sub_list, data_extras, 'un', 0);
        fextra.sub_list = vertcat(tmp_subs{:});
        individual_ranges = cellfun(@(a) a.individual_ranges, data_extras, 'un', 0);
        fextra.individual_ranges = vertcat(individual_ranges{:});
        individual_range_dur = cellfun(@(a) a.individual_range_dur, data_extras, 'un', 0);
        args.individual_range_dur = vertcat(individual_range_dur{:});
        fextra.mask_has_variable = cellfun(@(a) a.mask_has_variable, data_extras);
        trials = cellfun(@(a) a.trials, data_extras, 'un', 0);
        fextra.trials = vertcat(trials{:});
        chunks = vertcat(data_chunks{:});
        
        if sum(cellfun(@isempty, chunks)) ~= numel(chunks)
            switch dt
                case 'event'
                    stats = event_cal_stats(chunks, args);
                case 'cevent'
                    stats = cevent_cal_stats(chunks, args);
                case 'cont'
                    stats = cont_cal_stats(chunks, args);
                case 'cstream'
                    cstream_stats = cstream_cal_stats(chunks, args);
                    stats = cstream_cal_stats(chunks, args, [], 1);
                    stats = stats.cevent_stats;
                    stats.cstream_stats = cstream_stats;
            end
            fstats{1,w} = stats;
        end
        fchunks{1,w} = chunks;
        fextra = orderfields(fextra);
    end
    fchunks = horzcat(fchunks{:});
end
end