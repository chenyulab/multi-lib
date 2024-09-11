function results = cont_cal_stats(chunks, input)

%CONT_CAL_STATS Report various stypes of statistics of continue type data 
%chunks according to user input.
% 
% INPUT: 
%   CHUNKS: a cell of data. See also GET_VARIABLE,
%   GET_VARIABLE_BY_GROUPING, GET_VARIABLE_BY_SUBJECT,
%   GET_VARIABLE_BY_TRIAL, GET_VARIABLE_BY_EVENT, GET_VARIABLE_BY_CEVENT.
%   INPUT: (optional parameter) a struct that specifies the types of
%   statistics user wants to calculate. Optional fields are:
%       grouping: the grouping method of data chunks, see 
%       GET_VARIABLE_BY_GROUPING;
%       hist_bins: value bins for generating histogram.
%       high_threshold: for calculating the proportion of time that data
%       has a value larger than a certain value;
%       low_threshold: for calculating the proportion of time that data
%       has a value lower than a certain value;
%       whence: value 'start' or 'end', indicating whether the chunks of
%       data were extracted based on onset/offser of a certain types of
%       events/cevents.
%       interval: used with the parameter WHENCE, indicating the starting 
%       time and ending time when chunks were extracted based on
%       events/cevents.
% OUTPUT:
%   RESULTS: a struct containing all the statistics. Also, individual
%   statistic within one chunk of data will be reported accordingly.
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
% 
%   input.hist_bins = [0 1 2 3 4 5 6 7 8 9 10 100];
%   input.low_threshold = 2;
%   input.high_threshold = 5;
%   results = cont_cal_stats(chunks, input);
% Example results:
%     results = 
% 
%                         mean: 13.3893
%              individual_mean: [107x1 double]
%                       median: 13.7772
%            individual_median: [107x1 double]
%                         hist: [1x12 double]
%              individual_hist: [107x12 double]
%                     low_prop: 0.1533
%          individual_low_prop: [107x1 double]
%                    high_prop: 0.1790
%         individual_high_prop: [107x1 double]
%                temporal_time: [20x1 double]
%                temporal_mean: [20x1 double]
%               temporal_chunk: [20x81 double]
%
%   See also: GET_VARIABLE_BY_GROUPING
% 
% For more example, go to: 
% https://einstein.psych.indiana.edu/trac/browser/projects/txu_remodule/txu_test_stats_cont.m

% check fileds in 'input'
if ~exist('input', 'var')
    % this line of code is just to prevent from generating errors when
    % script checks whether a certain field exists.
    input.none_filed = 'No information here';
end

% if isfield(input, 'var_name')
%     if ~strcmp(get_data_type(input.var_name), 'cont')
%         error('Error! This function can only accept CONT data type');
%     end
% end

if isfield(input, 'sub_list')
    results.sub_list = input.sub_list;
end

if isfield(input, 'grouping')    
    grouping = input.grouping;
else
    grouping = '';
end

chunks(cellfun(@isempty, chunks)) = {[NaN NaN]};
%% calculate statistics
cat_chunks = cat(1,chunks{:});

% mean and median
res_mean = cellfun(@cont_mean,chunks,'UniformOutput', false);
res_std = cellfun(@(chunk) std(chunk(:,2:end),'omitnan'), chunks,'UniformOutput', false);
res_median = cellfun(@cont_median,chunks,'UniformOutput', false);
res_min = cellfun(@cont_min,chunks,'UniformOutput', false);
res_max = cellfun(@cont_max,chunks,'UniformOutput', false);
res_nonnan = cellfun(@(chunk) sum(~isnan(chunk(:,2)))/size(chunk,1), chunks,'UniformOutput', false);
results.mean = cont_mean(cat_chunks);
results.individual_mean = cat(1,res_mean{:});
results.mean_mean = mean(results.individual_mean, 1,'omitnan');
results.std = std(cat_chunks(:,2:end),'omitnan');
results.individual_std = cat(1,res_std{:});
results.mean_std = mean(results.individual_std, 1,'omitnan');
results.median = cont_median(cat_chunks);
results.individual_median = cat(1,res_median{:});
results.mean_median = mean(results.individual_median, 1,'omitnan');
results.min = min(cat_chunks(:,2:end),'omitnan');
results.individual_min = cat(1,res_min{:});
results.mean_min = mean(results.individual_min, 1,'omitnan');
results.max = max(cat_chunks(:,2:end),'omitnan');
results.individual_max = cat(1,res_max{:});
results.mean_max = mean(results.individual_max, 1,'omitnan');


results.max = max(cat_chunks(:,2:end),'omitnan');
results.nonnan = sum(~isnan(cat_chunks(:,2)))/size(cat_chunks,1);
results.individual_nonnan = cat(1,res_nonnan{:});

% hist_bins
if isfield(input, 'hist_bins')
    res_hist = nan(length(chunks), length(input.hist_bins));
    for i = 1: length(chunks)
        res_hist(i,:) = cont_hist(chunks{i}, input.hist_bins, 'separate');
        res_hist(i,:) = res_hist(i,:)/sum(res_hist(i,:));
    end
    
    results.hist_bins = input.hist_bins;
    results.hist = cont_hist(cat_chunks, input.hist_bins, 'separate');
    results.hist = results.hist/sum(results.hist);
    results.individual_hist = res_hist;
else
    [results.hist hist_bins] = hist(cat_chunks(:,2));
    results.hist_bins = hist_bins;
    
    res_hist = nan(length(chunks), length(hist_bins));
    for i = 1: length(chunks)
        res_hist(i,:) = cont_hist(chunks{i}, hist_bins, 'separate');
        res_hist(i,:) = res_hist(i,:)/sum(res_hist(i,:));
    end
    
    results.hist = results.hist/sum(results.hist);
    results.individual_hist = res_hist;
end

% low shreshold
if isfield(input, 'low_threshold')
    res_low_prop = nan(length(chunks), 1);    
    for i = 1: length(chunks)
        res_low_prop(i) = cont_below(chunks{i},input.low_threshold);
    end
    
    results.low_prop = cont_below(cat_chunks, input.low_threshold);
    results.individual_low_prop = res_low_prop;
end

% high shreshold
if isfield(input, 'high_threshold')
    res_high_prop = nan(length(chunks), 1);    
    for i = 1: length(chunks)
        res_high_prop(i) = cont_above(chunks{i},input.high_threshold);
    end
    
    results.high_prop =  cont_above(cat_chunks, input.high_threshold);
    results.individual_high_prop = res_high_prop;    
end

% calculate temporal profile
is_cal_temporal = 0;
offset = 0;
chunks_len = cellfun(@(chunk) length(chunk), chunks, 'UniformOutput', 0);
% calculate temporal profile automatically if all the chunks have the same
% length
if length(unique(cell2mat(chunks_len))) == 1
    is_cal_temporal = 1;
    time_base = chunks{1};
    time_base = time_base(:,1);
end
if length(grouping) > 0 && strcmp(grouping(end-4:end), 'event') && ...
    isfield(input, 'whence') && isfield(input, 'interval')
    is_cal_temporal = 1;
    offset = input.interval(1);
    chunks_len_temp = vertcat(chunks_len{:});
    [max_v max_idx] = max(chunks_len_temp);
    time_base = chunks{max_idx};
    time_base = time_base(:,1);
end
    
if is_cal_temporal
    res_temporal = align_streams(time_base, chunks, 'ForceZero');
    results.temporal_time = time_base - time_base(1) + offset;
    results.temporal_mean = mean(res_temporal, 2,'omitnan');
    results.temporal_chunk = res_temporal;
end
