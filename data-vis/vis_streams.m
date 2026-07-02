function h = vis_streams(subexpIDs, vars, labels, directory, setcolors, flag_edge, h)
% Plots visualized cstream or cevent data
%
% subexpIDs : array of subject IDs or experiment IDs
% vars : cell array of variable names, cstreams, cevents and events only. Each element of this array is a row
% in the visualization plot.
% vars can also be a structure, for more control of how the data is represented.
%
%       data.sub_list : array of subjects that correspond to data.data cell array
%       data.data : cell array, 1 per subject, with each cell being Nx3 cevents
%       data.colors : Nx3 matrix giving custom colormap for the cevent data
%       data.edge : 1 or 0 indicating whether a solid black line borders the
%           visualized cevents; 0 is recommended for continuous data that has
%           been converted to cevents.
%       data.box : 1 or 0 indicating whether to draw a larger box for the
%           given data. This box will cover the entire subplot and is intended
%           to represent meta-data.

if nargin == 1 && ischar(subexpIDs)
    switch subexpIDs
        case 'demo1'
            close all;
            subexpIDs = [7207];
            vars = {
                'cstream_inhand_left-hand_obj-all_child'
                'cstream_inhand_right-hand_obj-all_child'
                'cstream_inhand_left-hand_obj-all_parent'
                'cstream_inhand_right-hand_obj-all_parent'
                'cstream_eye_roi_child'
                'cstream_eye_roi_parent'
                };
            labels = {'cl', 'cr', 'pl', 'pr', 'ceye', 'peye'};
            enableGUI = 1;
        case 'demo2'
            close all;
            subexpIDs = [7207];
            vars = {
                'cstream_inhand_left-hand_obj-all_child'
                'cstream_inhand_right-hand_obj-all_child'
                'cstream_inhand_left-hand_obj-all_parent'
                'cstream_inhand_right-hand_obj-all_parent'
                'cstream_eye_roi_child'
                'cstream_eye_roi_parent'
                };
            labels = {'cl', 'cr', 'pl', 'pr', 'ceye', 'peye'};
            enableGUI = 1;
            camIDs = [];
    end
end

if ~exist('labels', 'var') || isempty(labels)
    labels = cell(1, numel(vars));
    for l = 1:numel(vars)
        labels{1,l} = num2str(l);
    end
end

if ~exist('flag_edge', 'var') || isempty(flag_edge)
    flag_edge = 1;
end

% if ~exist('enableGUI', 'var') || isempty(enableGUI)
%     enableGUI = 0;
% end

vars = vars(end:-1:1);
labels = labels(end:-1:1);

height = 1;
space = 0.03;

% setcolors can be an Nx3 matrix, like colors above, or a scalar indicating
% how many different colors you need
if exist('setcolors', 'var') && ~isempty(setcolors)
    colors = set_colors(setcolors);
else
    colors = set_colors();
end

labels = cellfun(@(a) strrep(a, '_', '\_'), labels, 'un', 0);

subs = cIDs(subexpIDs);

if ~exist('h', 'var') || isempty(h)
    h = figure('visible', 'on', 'position', [50 100 960 540]);
end
for s = 1:numel(subs)
    if ishghandle(h)
        figure(h);
        clf;
        bottom = 0;
        label_pos = [];
        numvars = numel(vars);
        for v = 1:numel(vars)
            if isstruct(vars{v})
                if isfield(vars{v}, 'box') && vars{v}.box
                    numvars = numvars - 1;
                end
            end
        end
        ex.individual_ranges = get_variable(subs(s), 'cevent_trials');
        for v = 1:numel(vars)
            % defaults
            tmpcolors = colors;
            flag_box = 0;
            
            if ischar(vars{v})
                data = get_variable(subs(s), vars{v}, 1);
                if isequal(data, false)
                    fprintf('%d : %s does not exist\n', subs(s), vars{v});
                end
                if vars{v}(1) == 'e'
                    data = cellfun(@(a) [a ones(size(a,1), 1)], data, 'un', 0);
                end
            else % data was supplied, make sure it is partitioned into trials
                datastr = vars{v};
                if ischar(datastr.data)
                    data = get_variable(subs(s), datastr.data);
                    if datastr.data(1) == 'e'
                        data = cellfun(@(a) [a ones(size(a,1), 1)], data, 'un', 0);
                    end
                else
                    log = datastr.sub_list == subs(s);
                    data = datastr.data{log};
                end
                if isfield(datastr, 'colors')
                    tmpcolors = datastr.colors;
                end
                if isfield(datastr, 'edge')
                    flag_edge = datastr.edge;
                end
                if isfield(datastr, 'box')
                    flag_box = datastr.box;
                end
            end
            if ~isempty(data)
                if ~iscell(data)
                    if size(data, 2) < 3
                        data = extract_ranges(data, 'cstream', ex.individual_ranges);
                    else
                        data = extract_ranges(data, 'cevent', ex.individual_ranges);
                    end
                end
            end
            MAX_COLOR = size(tmpcolors, 1);
            
            for c = 1:numel(data)
                if ~isempty(data{c})
                    if size(data{c}, 2) < 3
                        cev = cstream2cevent(data{c});
                    else
                        cev = data{c};
                    end
                    
                    subplot(numel(data),1,c);
                    if ~isempty(cev)
                        xlim([ex.individual_ranges(c,1) ex.individual_ranges(c,2)]);
                        
                        for i = 1:size(cev, 1)
                            if ~isnan(cev(i,3))
                                tmp = cev(i,:);
                                width = tmp(2) - tmp(1);
                                if width > 0
                                    if tmp(3) > 0
                                        coloridx = mod(tmp(3), MAX_COLOR);
                                        if coloridx == 0
                                            coloridx = MAX_COLOR;
                                        end
                                        thiscolor = tmpcolors(coloridx,:);
                                    elseif tmp(3) == 0
                                        thiscolor = [1 1 1];
                                    else
                                        error('Function cannot visualize cevents with negative values.')
                                    end
                                    r = rectangle('Position', [tmp(1), bottom, width, height], 'facecolor', thiscolor, 'edgecolor', 'none');
                                    if flag_edge
                                        set(r, 'edgecolor', 'black', 'linewidth', 0.5);
                                    end
                                    if flag_box
                                        set(r, 'Position', [tmp(1), 0, width, (numvars + numvars*space)], 'facecolor', 'none', 'linewidth', 2.5, 'clipping', 'off');
                                    end
                                end
                            end
                        end
 
                    end
                end
            end
            if ~flag_box
                label_pos = cat(2, label_pos, bottom + height/2);
                bottom = bottom + 1 + space;
            end
            
        end
        
        for p = 1:numel(data)
            subplot(numel(data),1,p);
            if p == 1
                title(subs(s));
            end
            set(gca, 'position', [0.05, 0.75-.24*(p-1), 0.92, 0.21]);
            ylim([0, numvars + numvars*space]);
            set(gca, 'ytick', label_pos);
            set(gca, 'yticklabel', labels);
            set(gca, 'ticklength', [0 0])
        end
        
%         mainpos = h.Position;
%         b = figure('visible', 'on', 'position', [mainpos(1)+mainpos(3)+10 mainpos(2) 300 420]);
%         m = figure('visible', 'on');
%         if ~exist('camIDs', 'var')
%             camIDs = [1 2];
%         end
%         load_frame_ui(h, b, m, subs(s), camIDs); % b is handle to frame figure
        
        if exist('directory', 'var') && ~isempty(directory)
            if ~exist(directory, 'dir')
                error('%s does not exist as a directory\n', directory);
            end
            set(h, 'position', [100 100 1280 720]);
            export_fig(h, sprintf('%s/%d', directory, subs(s)), '-png', '-r90', '-a1', '-nocrop');
        else
            set(h, 'visible', 'on');
            if numel(subs) > 1
                fprintf('Press any key to view next figure\n');
                pause;
            end
        end
    end
end
