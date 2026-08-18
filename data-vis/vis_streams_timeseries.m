function vis_streams_timeseries(subexpIDs, var_name, output_dir, args) 
%% Summary: 
% vis_streams_timeseries plots a variable's time series across multiple subjects and concatenates trials to remove inactive time
% + supplements existing vis_streams functions 

%% Required arguments 
% subexpIDs
%     vector of subject IDs or experiment IDs
% var_name
%     string or cell array of 1-2 variable names. When 2 variables are
%     given, each occupies half the row height per subject
% output_dir
%     directory where matlab figure will be saved
%% Optional arguments
% args.duration
%     max time window (seconds). Default: [] 
% args.colors
%     color matrix ([category R G B]). Default: set_colors
% args.title 
%     figure title string 
% args.save_name
%     if provided, saves figure to this path 
% args.filetype
%     file type for visualization. Default: png
% args.ylabel
%      default: 'Participants'
% args.subIDlabels
%      logical indicating whether subject labels will be used on y-axis. Default: true
% args.single_color
%      skips category lookup entirely and uses just one color for all events([R B G]). Default: []

%% Example calls
% args = struct();
% args.duration = 300;
% vis_streams_timeseries(310, 'cevent_speech_naming_local-id', ...
% 'Z:\ashley\vis_streams_timeseries\vis_examples', args) 

% Two variables:
% vis_streams_timeseries(310, {'cevent_eye_roi_child', 'cevent_eye_roi_parent'}, ... 
% 'Z:\ashley\vis_streams_timeseries\vis_examples', args)

% two variables max
if ~exist('args', 'var'), args = struct(); end
if ischar(var_name)
    var_name = {var_name};
end 
if numel(var_name) > 2
    error('This function supports a maximum of 2 variables!');
end 

num_vars = numel(var_name);

if ~isfield(args, 'duration'), args.duration = []; end 
if ~isfield(args, 'colors')
    args.colors = set_colors([]);
% Optional color overrides:
elseif size(args.colors,2) == 4
    color_overrides = args.colors;
    args.colors = set_colors([]);
    for c = 1:size(color_overrides,1)
        category = color_overrides(c,1);
        if category >= 1 && category <= size(args.colors,1)
            args.colors(category,:) = color_overrides(c,2:4);
        end
    end
end 
if ~isfield(args, 'title'), args.title = sprintf('Time Series: %s', strjoin(var_name, ' & ')); end
if ~isfield(args, 'save_name'), args.save_name = sprintf('time_series_%s', strjoin(var_name, '_')); end
if ~isfield(args, 'file_type'), args.file_type = 'png'; end
if ~isfield(args, 'ylabel'), args.ylabel = 'Participants'; end
if ~isfield(args, 'subIDlabels'), args.subIDlabels = true; end
if ~isfield(args, 'single_color'), args.single_color = []; end  

subs = cIDs(subexpIDs);

% Figure setup
fig = figure('Color', 'w');
hold on;

% Define styling
bar_height = 0.6; 
sub_bar_height = bar_height / num_vars; % full height for 1 variable, half for 2
grey_color = [0.85, 0.85, 0.85]; 
colormap_active = args.colors; 
max_trial_time = 0; % Keep track of max trial time for x-axis

% Temporary arrays to gather valid subjects before plotting
valid_subs = [];
valid_data = {};
valid_durations = [];

for s = 1:numel(subs)
    % Attempt to grab variable data safely
    sub_data = {};
    skip = false;
    trial_times = get_trial_times(subs(s));

    for v = 1:num_vars
        try 
            data = get_variable_by_trial_stitch(subs(s), var_name{v});
        catch
            warning('Could not retrieve %s for subject %d. Skipping', var_name{v}, subs(s));
            skip = true;
            break; 
        end

        if isempty(data)
            warning('No data found for "%s" for subject %d. Skipping.', var_name{v}, subs(s));
            skip = true;
            break;
        end
        sub_data{v} = data;
        % Update data based on trial time
        sub_data{v}(:,1:2) = sub_data{v}(:,1:2) - trial_times(1,1);
    end
    
    if skip, continue; end 
    
    % Calculate trial duration
    duration = sum(trial_times(:,2) - trial_times(:,1));
    if ~isempty(args.duration)
            duration = min(duration, args.duration);
    end

    % Store valid data
    valid_subs(end+1) = subs(s);
    valid_data{end+1} = sub_data;
    valid_durations(end+1) = duration;
end

num_valid = numel(valid_subs);

% Sorting logic: longest active duration at the bottom 
[~, sort_idx] = sort(valid_durations, 'descend');

% Reorder our variables based on the sorted index
valid_subs = valid_subs(sort_idx);
valid_data = valid_data(sort_idx);
valid_durations = valid_durations(sort_idx);

y_pos = 0;          % Track how many subjects we actually plot
plotted_subs = [];  % Store IDs of subjects successfully plotted (for Y-tick labels)

% Edit this plotting loop to draw each variable in its sub-row 
for s = 1:num_valid
    y_pos = y_pos + 1; 
    plotted_subs(end+1) = valid_subs(s); 
    current_duration = valid_durations(s);
    
    % Truncate the grey base bar if it overshoots the global cap
    if ~isempty(args.duration)
        current_duration = min(current_duration, args.duration);
    end
    
    % Track max total time across all sessions for xlim
    max_trial_time = max(max_trial_time, current_duration);
    
    % Base grey bar
    rectangle('Position', [0, y_pos - bar_height/2, current_duration, bar_height], ...
              'FaceColor', grey_color, 'EdgeColor', 'none');

    % Draw each variable in its sub-row
    % variable 1 = top half (or full row if only one variable), variable 2
    % = bottom half
    % Overlap handling: variable 2 draws on top where they overlap
    for v = 1:num_vars
        data_v = valid_data{s}{v};
    
        if num_vars == 1
            % Fill the entire gray rectangle
            sub_bottom = y_pos - bar_height/2;
            plot_bar_height = bar_height;
        else
            % Variable 1 top, variable 2 bottom
            if v == 1
                sub_bottom = y_pos;
            else
                sub_bottom = y_pos - bar_height/2;
            end
    
            plot_bar_height = sub_bar_height;
        end
    
        for d = 1:size(data_v,1)
            seg_start = data_v(d,1);
            seg_end = data_v(d,2);
    
            if ~isempty(args.duration)
                if seg_start >= args.duration
                    continue;
                end
                seg_end = min(seg_end, args.duration);
            end
    
            seg_duration = seg_end - seg_start;
    
            if seg_duration <= 0
                continue;
            end
    
            category = data_v(d,3);
    
            if ~isempty(args.single_color)
                seg_color = args.single_color;
            else
                if category > 0 && category <= size(colormap_active,1)
                    seg_color = colormap_active(category,:);
                elseif category == 0
                    seg_color = [1 1 1];
                else
                    warning(['Category %g is outside the valid range ' ...
                        '[0,%d]! Event skipped'], ...
                        category, size(colormap_active,1));
                    continue;
                end
            end
    
            rectangle('Position', ...
                [seg_start, sub_bottom, seg_duration, plot_bar_height], ...
                'FaceColor', seg_color, ...
                'EdgeColor', 'none');
        end
    end
    % Draw separator line
    if num_vars > 1
        x = linspace(0,current_duration);
        y = ones(size(x)) * y_pos;
        line(x,y,'LineWidth',.01,'Color','w');
    end
end

% Formatting the Plot
hold off;
if y_pos > 0
    ax = gca;
    ax.FontName = 'Arial';
    set(gca,'fontsize',14);
    ylim([0, y_pos + 1]);
    
    % Enforce axis limits precisely matching duration if requested
    if ~isempty(args.duration)
        xlim([0, args.duration]);
    else
        xlim([0, max_trial_time * 1.05]); 
    end
    
    ylabel(args.ylabel);
    xlabel('Active Trial Time');
    title(args.title, 'Interpreter','none'); 
    % Only label the Y-ticks with the subjects that actually had data
    if args.subIDlabels
        yticks(1:y_pos);
        yticklabels(cellstr(num2str(plotted_subs(:))));
    else
        set(gca,'ytick',[]);
    end
    
    box off;
    grid off;
    ax.TickLength = [0 0];
    % if exist('output_dir','var') && ~isempty(output_dir)
    filepath = fullfile(output_dir, sprintf('%s.%s', args.save_name,args.file_type));
    saveas(fig,filepath);
else
    close(gcf);
    warning('No subjects had valid data. Figure closed.');
end
end