function [datamatrix, hd] = extract_multi_measures_ar_test(var_list, subexpID, filename, args)
%{
Check demo_extract_multi_measures.m for usage of these parameters

args.label_matrix
args.label_names
args.cevent_measures
args.cont_measures
args.measures
args.persubject

Any argument that is supported by get_chunks (thus,
get_variable_by_grouping) is also supported here.

%}



if ~exist('args', 'var') || isempty(args)
    args = struct([]);
end

if ~iscell(var_list)
    var_list = {var_list};
end

if exist('filename', 'var') && ~isempty(filename)
    fid = fopen(filename, 'w');
    if ~fid
        error('Cannot open %s\n', filename);
    end
    fclose(fid);
end

if isfield(args, 'cevent_ranges')
    ranges = args.cevent_ranges;
elseif isfield(args, 'event_ranges')
    ranges = args.event_ranges;
else
    ranges = [];
end

if ~isfield(args, 'persubject')
    persubject = 0;
else
    persubject = args.persubject;
end


subs = cIDs(subexpID);

numvar = numel(var_list);

datamatrix = cell(1000,100); %preallocate array with up to 1000 subjects and 100 variables
stats = cell(numel(subs), numvar);
prefixdata = cell(numel(subs), 1);

if isfield(args, 'label_names')
    if ~iscell(args.label_names)
        args.label_names = {args.label_names};
    end
    ln = numel(args.label_names);
    label_names = args.label_names;
else
    ln = 1;
    label_names{1} = '';
end

if persubject
    if isfield(args, 'cevent_name')
        h1 = sprintf(',,base:%s,', args.cevent_name);
    else
        h1 = ',,,';
    end
    h2 = ',,,';
    h3 = ',,,';
    h4 = 'subID,expID,instanceID,';
else
    if isfield(args, 'cevent_name')
        h1 = sprintf(',,base:%s,,,,,', args.cevent_name);
    else
        h1 = ',,base_ranges,,,,,';
    end
    h2 = ',,,,,,,';
    h3 = ',,,,,,,';
    h4 = 'subID,expID,onset,offset,category,trialsID,instanceID,';
end

numcol = cell(1,numvar);
numcol = cellfun(@(a) num2cell(zeros(1,100)), numcol, 'un', 0);
for s = 1:numel(subs)
    fprintf('\nProcessing %d\n', subs(s));
    %first passthrough
    if ~isempty(ranges)
        if isfield(args, 'cevent_ranges')
            args.cevent_ranges = ranges(s);
        elseif isfield(args, 'event_ranges')
            args.event_ranges = ranges(s);
        end
    end
    for v = 1:numvar
        [~,extra,thisstat, ~] = get_chunks_at_test(var_list{v}, subs(s), args);
        stats{s,v} = thisstat;
        clear setnumcol;
        for w = 1:numel(thisstat)
            if ~isempty(thisstat{1,w})
                if isfield(thisstat{1,w}, 'categories')
                    if numcol{1,v}{1,w} == 0
                        setnumcol = thisstat{1,w}.categories;
                    else
                        setnumcol = unique(cat(2, numcol{1,v}{1,w}, thisstat{1,w}.categories));
                    end
                end
            end
            if exist('setnumcol', 'var')
                numcol{1,v}{1,w} = setnumcol;
            end
        end
        if isempty(prefixdata{s,1}) && ~isempty(extra)
            if persubject
                prefixdata{s,1} = [subs(s) sub2exp(subs(s)) s];
            else
                irsize = size(extra.individual_ranges);
                ir = zeros(irsize(1), 3);
                ir(:,1:irsize(2)) = extra.individual_ranges;
                % splits up cevent ranges into trials so that we can easily
                % tag the trial number to each cevent
                trials_id = extract_ranges(ir, 'cevent', extra.trials);
                trials_id = cellfun(@(a,b) [a repmat(b, size(a, 1), 1)], trials_id, num2cell(extra.trials(:,end)), 'un', 0);
                ir = vertcat(trials_id{:});
                prefixdata{s,1} = [extra.sub_list sub2exp(extra.sub_list) ir (1:irsize(1))'];
            end
        end
    end
end

for s = 1:numel(subs)
    i = 1;
    datamatrix{s,i} = prefixdata{s,1};
    numrow = size(prefixdata{s,1}, 1);
    i = i + 1;
    
    for v = 1:numvar
        if s == 1
            h1 = strcat(h1, var_list{v});
        end
        datatype = get_data_type(var_list{v});
        
        if isfield(args, 'measures')
            measures = args.measures{v};
        else
            switch datatype
                case {'cevent', 'event', 'cstream'}
                    if isfield(args, 'cevent_measures')
                        measures = args.cevent_measures;
                    else
                        measures = {'individual_prop_by_cat', 'individual_mean_dur_by_cat', 'individual_freq_by_cat'};
                    end
                case 'cont'
                    if isfield(args, 'cont_measures')
                        measures = args.cont_measures;
                    else
                        measures = {'individual_mean', 'individual_median'};
                    end
            end
        end
        
        
        if ~iscell(measures)
            measures = {measures};
        end
        
        % We don't want to get a measure during each trial, then average 4 trials,
        % instead concatenate all data across trials then find the measure.
        % This can be achieved in _cal_stats by not specifying the
        % 'individual_' prefix.
        if persubject && ~isfield(args, 'cevent_ranges') && ~isfield(args, 'event_ranges')
            measures = cellfun(@(a) strrep(a, 'individual_', ''), measures, 'un', 0);
            measures = cellfun(@(a) strrep(a, 'number', 'total_number'), measures, 'un', 0);
        end
        
        if isfield(args, 'label_matrix')
            measures = cellfun(@(a) strrep(a, '_by_cat', ''), measures, 'un', 0);
        end
        
        for m = 1:numel(measures)
            if ~isempty(strfind(measures{m}, '_by_cat'))
                by_cat = 1;
            else
                by_cat = 0;
            end
            
            if s == 1
                h2 = strcat(h2, measures{m});
            end
            
            for w = 1:ln % ln is number of label_names 
                if s == 1
                    if by_cat
                        mc = repmat(',', 1, length(numcol{1,v}{1,w}));
                    else
                        mc = ',';
                    end
                    h1 = strcat(h1, mc);
                    h2 = strcat(h2, mc);
                    h3 = strcat(h3, label_names{w}, mc);
                    if by_cat
                        h4 = strcat(h4, sprintf('cat-%d,', numcol{1,v}{1,w}));
                    else
                        h4 = strcat(h4, 'cat-all,');
                    end
                end
                
                if by_cat
                    prearray = zeros(numrow, length(numcol{1,v}{1,w}));
                else
                    prearray = zeros(numrow, 1);
                end
                
                if isempty(stats{s,v}{w})
                    datamatrix{s,i} = prearray;
                else
                    thisstat = stats{s,v}{w}.(measures{m});
                    thisstat(isnan(thisstat)) = 0;
                    if by_cat
                        if isfield(stats{s,v}{w}, 'categories')
                            log = ismember(numcol{1,v}{1,w},stats{s,v}{w}.categories);
                        else
                            log = ones(1,length(numcol{1,v}{1,w})) == 1;
                        end
                    else
                        log = 1;
                    end

                    if persubject
                        prearray(:,log) = mean(thisstat, 1,'omitnan');
                    else
                        prearray(:,log) = thisstat;
                    end
                    datamatrix{s,i} = prearray;
                end
                i = i + 1;
            end
        end
    end
end

logmat = cellfun(@isempty, datamatrix);
datamatrix(all(logmat, 2),:) = [];
datamatrix(:,all(logmat,1)) = [];

datamatrix = cell2mat(datamatrix);
log = all(isnan(datamatrix), 1);
datamatrix(:,log) = [];
hd = {h1, h2, h3, h4};
for h = 1:4
    head = hd{h};
    head = strrep(head, ',', ' ,');
    head = strsplit(head, ',');
    head = head(1:end-1);
    head(log) = [];
    head = strjoin(head, ',');
    head(isspace(head)) = '';
    hd{h} = head;
end

if exist('filename', 'var') && ~isempty(filename)
    write2csv(datamatrix, filename, hd);
end


end