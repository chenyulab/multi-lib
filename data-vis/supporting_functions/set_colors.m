function colors = set_colors(n, is_plot_colormap)

NUM_DEFAULT = 150;
PLOT_MAX_ROWS = 30;

multisensory_colors = [
         0         0    1.0000
         0    1.0000         0
    1.0000         0         0
    1.0000         0    1.0000];

is_color_set = false;
num_colors = NUM_DEFAULT;

if nargin >= 1
    if numel(n) == 1
        num_colors = n;
    elseif size(n,2) == 3
        colors = n;
        is_color_set = true;
        num_colors = size(n,2);
    end
end

if ~is_color_set
    predefined_colors = distinguishable_colors(num_colors+1);
    predefined_colors = [
        multisensory_colors
        predefined_colors(6:end, :)];
    colors = predefined_colors;
end

% predefined_colors = [
%          0         0    1.0000
%          0    1.0000         0
%     1.0000         0         0
%     1.0000         0    1.0000
%     1.0000    0.8276         0
%          0    0.3448         0
%     0.5172    0.5172    1.0000
%     0.6207    0.3103    0.2759
%          0    1.0000    0.7586
%          0    0.5172    0.5862
%          0         0    0.4828
%     0.5862    0.8276    0.3103
%     0.9655    0.6207    0.8621
%     0.8276    0.0690    1.0000
%     0.4828    0.1034    0.4138
%     0.9655    0.0690    0.3793
%     1.0000    0.7586    0.5172
%     0.1379    0.1379    0.0345
%     0.5517    0.6552    0.4828
%     0.9655    0.5172    0.0345
%     0.5172    0.4483         0
%     0.4483    0.9655    1.0000
%     0.6207    0.7586    1.0000
%     0.4483    0.3793    0.4828
%     0.6207         0         0
%          0    0.3103    1.0000
%          0    0.2759    0.5862
%     0.8276    1.0000         0
%     0.7241    0.3103    0.8276
%     0.2414         0    0.1034
%     0.9310    1.0000    0.6897
%     1.0000    0.4828    0.3793
%     0.2759    1.0000    0.4828
%     0.0690    0.6552    0.3793
%     0.8276    0.6552    0.6552
%     0.8276    0.3103    0.5172
%     0.4138         0    0.7586
%     0.1724    0.3793    0.2759
%          0    0.5862    0.9655
%     0.0345    0.2414    0.3103
%     0.6552    0.3448    0.0345
%     0.4483    0.3793    0.2414
%     0.0345    0.5862         0
%     0.6207    0.4138    0.7241
%     1.0000    1.0000    0.4483
%     0.6552    0.9655    0.7931
%     0.5862    0.6897    0.7241
%     0.6897    0.6897    0.0345
%     0.1724         0    0.3103
%          0    0.7931    1.0000
%     0.3103    0.1379         0
%          0    0.7241    0.6552
%     0.6207         0    0.2069
%     0.3103    0.4828    0.6897
%     0.1034    0.2759    0.7586
%     0.3448    0.8276         0
%     0.4483    0.5862    0.2069
%     0.8966    0.6552    0.2069
%     0.9655    0.5517    0.5862
%     0.4138    0.0690    0.5517];
% 

if nargin < 2
    is_plot_colormap = false;
end

if is_plot_colormap
    num_total_colors = size(colors, 1);
    num_subplots = ceil(num_total_colors/PLOT_MAX_ROWS);
    h_colormap = figure('Position', [20 20 300*num_subplots 1000]); % , 'Visible', 'off'
    size_unit = 20;
    
    for plotidx = 1:num_subplots
        subplot(1, num_subplots, plotidx);
        if plotidx < num_subplots
            num_colors = PLOT_MAX_ROWS;
        else
            num_colors = num_total_colors - (plotidx-1)*PLOT_MAX_ROWS;
        end
        hold on;
        for i = 1:num_colors
            coloridx = i+(plotidx-1)*PLOT_MAX_ROWS;
            colorone = colors(coloridx, :);
            plot_x = [3 3 7 7];
            upper_y = (num_colors-i+1) * size_unit;
            lower_y = (num_colors-i) * size_unit+size_unit/10;
            plot_y = [lower_y upper_y upper_y lower_y];
            fill(plot_x, plot_y, colorone, 'EdgeColor', 'k');
            text(mean(plot_x), mean(plot_y), sprintf('%d', coloridx), 'HorizontalAlignment', 'center');
        end
        xlim([2 8]);
        ylim([0 (num_colors+1)*size_unit]);
        % set(gca, 'XTick',[]);
        % set(gca, 'YTick',[]);
        set(gca,'Visible','off');
        hold off;
    end
    set(h_colormap,'PaperPositionMode','auto');
    title_str = sprintf('colormap %d colors', num_total_colors);
%     text(mean(plot_x), -size_unit, title_str, 'HorizontalAlignment', 'center');
    saveas(h_colormap, [title_str '.png']);
    fprintf('Colormap saved as %s\n', [title_str '.png']);
end

end