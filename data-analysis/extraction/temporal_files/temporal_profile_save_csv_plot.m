function temporal_profile_save_csv_plot(profile_data, save_dir)

if nargin < 2
    save_dir = '.';
end

expr_module = 'eye_roi|inhand|naming|vision_size|joint|ballrolling|gyro';
cevent_name = profile_data.cevent_name;
var_name = profile_data.var_name;

if iscell(var_name)
    example_var_name = var_name{1};
    is_var_cell = true;
    num_vars = length(var_name);
    str_var_type = get_data_type(example_var_name);
else
    example_var_name = var_name;
    is_var_cell = false; % meaning the profile_data variable only has one cstream
    num_vars = 1;
    str_var_type = get_data_type(example_var_name);
end

str_module_cevent = regexp(cevent_name, expr_module, 'match');
if ~isempty(str_module_cevent)
    str_module_cevent = str_module_cevent{1};
else
    str_module_cevent = 'cevent_module';
end
str_module_var = regexp(example_var_name, expr_module, 'match');
if ~isempty(str_module_cevent)
    str_module_var = str_module_var{1};
else
    str_module_var = 'var_module';
end

time_base = profile_data.time_base;
num_groupids = length(profile_data.group_list);

csv_header = {'sub ID', 'exp ID', 'onset', 'offset', 'category', ...
     'trial ID', 'instance ID'};
 csv_header_group = cell(1, num_groupids);
 if isfield(profile_data, 'groupid_label')
     csv_header_group = profile_data.groupid_label;
 else
     for cgidx = 1:num_groupids
         csv_header_group{cgidx} = ['group#' num2str(profile_data.group_list(cgidx))];
     end
 end
 figure_legend = csv_header_group;
 length_time = length(time_base);
 length_profile_chunk = length_time*num_groupids;

csv_len_header = length(csv_header);
csv_column_profile = csv_len_header+num_groupids;

csv_header_row = cell(4, length_profile_chunk+csv_column_profile);
mask_fill =cellfun('isempty', csv_header_row);
csv_header_row(mask_fill) = {' '};
csv_header_row{1, 3} = cevent_name;

csv_column_var = csv_len_header+1;
if strcmp(str_var_type, 'cont')
    str_probs_mean = sprintf('average %s', str_module_var);
elseif strcmp(str_var_type, 'cstream')
   str_probs_mean = sprintf('probabilities of %s', str_module_var);
end

if is_var_cell
    csv_header_row(1, csv_column_var:csv_column_var+num_vars-1) = var_name;
else
    csv_header_row{1, csv_column_var} = var_name;
end

csv_header_row{3, csv_column_var} = [str_probs_mean ' per instance'];
tmp_idx = csv_column_profile+1;
for gidx = 1:num_groupids
    csv_header_row{3, tmp_idx+length_time*(gidx-1)} = ['temporal profile of ' str_probs_mean ' of ' figure_legend{gidx}];
end
csv_header_row(4, 1:length(csv_header)) = csv_header;
csv_header_row(4, length(csv_header)+1:csv_column_profile) = csv_header_group;
csv_header_row(4, csv_column_profile+1:end) = num2cell(repmat(time_base, 1, num_groupids));

csv_chunks = horzcat(profile_data.profile_data_mat{:});

% subID	expID	onset	offset	category	trialsID	instanceID
csv_data_sub = [profile_data.sub_list profile_data.exp_list profile_data.cevents ...
    profile_data.cevent_trialid profile_data.cevent_instanceid ...
    profile_data.probs_mean_per_instance csv_chunks];

result_csv_name_start = sprintf('temporal_profile_of_%s_group_by_%s', str_module_var, str_module_cevent);

% cstream_results = cstream_cal_stats(csv_chunks, profile_data, 1);
% cstream_count = cstream_results.temporal_count
%%%% start plotting, one line per subject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% start plotting
% profile_data.figure_legend = {'target', 'non-target', 'face'}; 
% profile_data.xlabel = str_module_cevent;
% profile_data.ylabel = str_module_var;
% profile_data.xlim = [profile_data.interval(1) profile_data.interval(2)-1];
vert_line = [0];
sub_list = unique(profile_data.sub_list);
exp_list = unique(profile_data.exp_list);

% profile_line_sub = nan(length(sub_list), length_time);

colormap = {[0 0 1]; [1 0 1]; [1 0 0]; [0 1 1]; [0 1 0]; [1 1 0]; ...
    [0 0 0]; [0 0 0.7]; [0.7 0 0.7]; [0 0.7 0.7]; [0.7 0 0]; [0 0.7 0]};

for eidx = 1:length(exp_list)
    exp_id = exp_list(eidx);
    title_str = sprintf('%s_exp%d', result_csv_name_start, exp_id);
    max_y = 0;
    h = figure('Position', [50 50 1200 900], 'Visible', 'off');
    hold on;

    for gidx = 1:num_groupids

        profile_mat = profile_data.profile_data_mat{gidx};
        mask_select = profile_data.exp_list == exp_id;
        profile_mat_exp = profile_mat(mask_select, :);

        if strcmp(str_var_type, 'cont')
            profile_line_plot = mean(profile_mat_exp, 1,'omitnan');
        else
            num_valid_data = sum(~isnan(profile_mat_exp), 1);
            num_matches = sum(profile_mat_exp > 0 & profile_mat_exp < 2, 1);
            profile_line_plot = num_matches ./ num_valid_data;
        end

        plot(time_base, profile_line_plot, 'Color', colormap{gidx});
        
        max_y = max(max(profile_line_plot,[],'omitnan'), max_y,'omitnan');
    end

    hold off;
    legend(figure_legend, 'Location', 'bestoutside');
    title(no_underline(title_str));
    % xlim([profile_data.interval(1) profile_data.interval(2)-1]);
    ylim([0 max_y+0.005]);
% 
%     for vidx = 1:length(vert_line)
%         x = [vert_line(vidx), vert_line(vidx), vert_line(vidx)+0.01, vert_line(vidx)+0.01];
%         y = [0, max_y, max_y, 0];
%         color = [1 0 0];
%         fill(x, y, 'r', 'EdgeColor', color);
%     end

    saveas(h, fullfile(save_dir, [title_str '.png']));
    close(h);
end

% saving the data using cell2csv function, extremely slow...
csv_save_path = fullfile(save_dir, sprintf('%s.csv', result_csv_name_start));
cell2csv(csv_save_path, [csv_header_row; num2cell(csv_data_sub)]);
fprintf('Profile results saved under %s\n', csv_save_path);

