%%%
% Author: Bryanna Katherine Boone
% Modifier: Jingwen Pang
% Last modified: 12/05/2024
% 
% This function generates visualizations of specified cevent variables for short clips from query
%
% example call: 
%   vars = {'cevent_eye_roi_child', 'cevent_eye_roi_parent', 'cevent_eye_joint-attend_both', 'cevent_inhand_parent'};
%   streamlabels = {'ceye', 'peye', 'ja', 'parent inhand'};
%   output_dir = 'Z:\bryanna\small_vis_streams'
%   input_file = "Z:\CORE\scheduled_tasks\multi-lib_backup_2024_11_07\demo_results\speech_analysis\example8.csv"
%   make_small_vis_streams(input_file, vars, streamlabels, output_dir)
%   see more demos in demo_make_small_vis_streams
%%%

function make_small_vis_streams(input_file, vars, streamlabels, output_dir, panels, cutoff)
    if ~exist('panels', 'var')
        panels = 0;
    end

    if ~exist('cutoff', 'var')
        cutoff = false;
    end

    if length(vars) >5
        disp('cannot input more than 5 variables')
        return
    end

    data = readtable(input_file);

    page_num = 1;

    if panels ~= 0
        fig = figure('Position',[0,0,2000,1200]);
        tiledlayout("flow");
    end

    for i = 1:height(data)

        subID = table2array(data(i,1));

        word = cell2mat(table2array(data(i, 9)));
       
        onset = table2array(data(i, 4));

        real_offset= table2array(data(i,7));

        if cutoff 
            cutoff_offset = onset + cutoff;

            if real_offset < cutoff_offset
                offset = real_offset;
            else
                offset = cutoff_offset;
            end

        else
            offset = real_offset;
                   
        end

        window_times = [onset offset];

        

        

        all_data = cell(numel(vars),1);
        for f = 1:numel(vars)
            if has_variable(subID, vars{f})
                temp_data = get_variable(subID, vars{f});
                all_data{f} = temp_data;
            else
                all_data{f} = struct([]);
            end       
        end

        

        
        
        if panels ~=0

            ax = nexttile;
            small_vis_data(all_data, window_times, streamlabels,ax);
            title(sprintf('%d %.4f %s', subID, onset, word))

            if mod(i, 25) ==0 || i == height(data)                
                if i ~= 1
                    savefilename = fullfile(output_dir, sprintf('page%d.png', page_num));
                    args.titlelabel = sprintf('page%d.png', page_num);
                    export_fig(fig, savefilename, '-png', '-a1', '-nocrop');
                    close(fig)
                    page_num = page_num + 1;   
                end

                if i ~= height(data)
                    fig = figure('Position',[0,0,2000,1200]);
                    tiledlayout("flow");
                end

                
                
            end


           
        else

            flag_dir = 1;
            if exist('output_dir', 'var') && ~isempty(output_dir)
                if exist(output_dir, 'dir')
                    savefilename = fullfile(output_dir, sprintf('%d_%.4f_%s.png', subID, onset, word));
                else
                    error('%s does not exist', output_dir);
                end
            else
                savefilename = [];
                flag_dir = 0;
            end

            h = figure('position', [50 500 1280 480]);
            small_vis_data(all_data, window_times, streamlabels);
            title(sprintf('%d %.4f %s', subID, onset, word))

            export_fig(h, savefilename, '-png', '-a1', '-nocrop');

           if flag_dir
            close(h);
           end
        end

    end

end

function h = small_vis_data(celldata, window_times, streamlabels,axh, args)
    % each element of celldata is a cstream or cevent data
    % {cev1, cev2, cev3}
    
    
    if ~exist('args', 'var')
        args = struct();
    end
    
    if ~isfield(args, 'titlelabel')
        args.titlelabel = [];
    end
    
    if ~isfield(args, 'colors')
        args.colors = set_colors([]);
    end
    
    if ~isfield(args, 'draw_edge')
        args.draw_edge = 1;
    end
    
    if ~isfield(args, 'isCont')
        args.isCont = 0;
    end
    
    if ~exist('streamlabels', 'var') || isempty(streamlabels)
        for c = 1:numel(celldata)
            streamlabels{1,c} = sprintf('%d', c);
        end
    end
    
    if ~exist('window_times', 'var')
        window_times = [];
    end
    if ~exist('axh', 'var')
        axh = axes();
    end
    
    
    streamlabels = cellfun(@(a) strrep(a, '_', '\_'), streamlabels, 'un', 0);
    streamlabels = streamlabels(end:-1:1);
    celldata = celldata(end:-1:1);
    
    space = 0.03;
    height = 1;
    bottom = 0;
    
    numdata = numel(celldata);
    
    for d = 1:numel(celldata)
        cevorcst = celldata{d};
        if ~isstruct(cevorcst)
            if size(cevorcst,2) == 2
                cev = cstream2cevent(cevorcst);
            else
                cev = cevorcst;
            end
            celldata{d} = cev;
        end
    end
    
    
    numplots = size(window_times,1);
    
    
    
    %axh.Position = [0.05, 0.75-.24*(1-1), 0.92, 0.21];
    ylim([0, numdata + numdata*space]);
    xlim([window_times(1,1) window_times(1,2)]);
    
    if ~isempty(args.titlelabel)
        title(strrep(args.titlelabel, '_', '\_'));
    end
    
    
    label_pos = [];
    cont_colormap = [];
    for d = 1:numel(celldata)
        this_args = args;
        MAX_COLOR = size(this_args.colors, 1);
        
        cev = celldata{d}; % cevent or cstream
        if ~isempty(cev)
            if isstruct(cev) && ~isempty(cev.data)
                this_args = cev.args;
                cev = cev.data;
            end
            if this_args.isCont
                cellcev = cont_extract_ranges(cev, window_times);
            else
                cellcev = event_extract_ranges(cev, window_times);
            end
            for c = 1:numel(cellcev)
                %h.CurrentAxes = axh;
                cevpart = cellcev{c};
                if ~isempty(cevpart)
                    if this_args.isCont
                        cm_size = size(cont_colormap, 1);
                        cont_colormap = cat(1, cont_colormap, this_args.colors);
                        im = imagesc('CData', cevpart(:,2)'+cm_size, 'XData', cevpart(:,1), 'YData', bottom+.5);
                        im.CDataMapping = 'direct';
                    else
                        for i = 1:size(cevpart, 1)
                            tmp = cevpart(i,:);
                            width = tmp(2) - tmp(1);
                            if width > 0
                                if tmp(3) > 0
                                    coloridx = mod(tmp(3), MAX_COLOR);
                                    if coloridx == 0
                                        coloridx = MAX_COLOR;
                                    end
                                    thiscolor = this_args.colors(coloridx,:);
                                elseif tmp(3) == 0
                                    thiscolor = [1 1 1];
                                else
                                    error('Function cannot visualize cevents with negative values.')
                                end
                                r = rectangle('Position', [tmp(1), bottom, width, 1], 'facecolor', thiscolor, 'edgecolor', 'none');
                                if this_args.draw_edge
                                    set(r, 'edgecolor', 'black', 'linewidth', 0.5);
                                end
                            end
                        end
                    end
                end
            end
        end
        
        label_pos = cat(2, label_pos, bottom + height/2);
        bottom = bottom + 1 + space;
    
    end
    colormap(cont_colormap);
    for n = 1:numplots
        h.CurrentAxes = axh;
        set(gca, 'ytick', label_pos);
        set(gca, 'yticklabel', streamlabels);
        set(gca, 'ticklength', [0 0])
    end

end
