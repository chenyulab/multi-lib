function vis_hist_v2(subexpIDs, varname, edges, directory, nametag, flag_savefig)
% see demo_vis_hist.m for documentation

subs = cIDs(subexpIDs);

if ~exist('flag_savefig', 'var') || isempty(flag_savefig)
    flag_savefig = 0;
end

if ~exist('directory', 'var') || isempty(directory)
    directory = '.'; % current directory
end

if size(edges, 2) == 1
    edges = edges';
end
if edges(end) ~= Inf
    edges = cat(2, edges, Inf);
end

allx = cell(numel(subs), 1);
hsubs = [];
for s = 1:numel(subs)
    fprintf('%d\n', subs(s));
    try
        if has_variable(subs(s), varname)
            try
                hsubs = cat(1, hsubs, subs(s));
                data = get_variable_by_trial_cat(subs(s), varname);
                dim2 = size(data,2);
                switch dim2
                    case 2
                        % raw values
                        values = data(:,2);
                    case 3
                        % durations
                        values = data(:,2)-data(:,1);
                end
                
                x = histcounts(values, edges);
                
                allx{s,1} = x';
            catch ME
                disp(ME.message)
                values = NaN;
                x = histcounts(values, edges);
                x(:) = NaN;
                allx{s,1} = x';
                continue
            end
        end
    catch ME
        disp(ME.message)
        continue
    end
end

subs = hsubs;
allx = horzcat(allx{:});
edges = edges(1:end-1)';

headers = sprintf('%d,', subs);
headers = cat(2, 'binedges,', headers, 'all,');
towrite = cat(2, edges, allx, nansum(allx, 2));
write2csv(towrite, sprintf('%s/%s_count.csv', directory, nametag), headers);
countdata = towrite(:,2:end);
normdata = countdata;
totals = nansum(normdata, 1);
normdata = normdata ./ repmat(totals, size(normdata, 1), 1);

ymax = max(max(countdata(:, 1:end-1)));
if flag_savefig
    figure;
    set(gcf, 'position', [100 100 1280 720]);
    if contains(varname, 'cont')
        countdata = normdata;
        ymax = 1;
    end
    for c = 1:size(countdata, 2)-1
        if mod(c,10) == 0
            fprintf('%d / %d\n\t%s\n', c, size(countdata, 2)-1, varname);
        end
        probx = countdata(:,c);

        bar(1:length(edges), probx);
        set(gca, 'xtick', 1:2:length(edges));
        set(gca, 'xticklabel', edges(1:2:end));
        xlabel('duration (sec)');
        ylabel('raw count');
        ylim([0 ymax]);
        title(sprintf('%d', subs(c)));
        
        dirname = sprintf('%s/%s_individual/', directory, nametag);
        if ~exist(dirname, 'dir')
            mkdir(dirname);
        end
        try
            export_fig(gcf, sprintf('%s/%s_individual/%d', directory, nametag, subs(c)), '-jpg', '-nocrop');
        catch ME
            disp(ME.message)
        end
        clf(gcf);
    end
    
    probx = normdata(:,end);

    bar(1:length(edges), probx);
    set(gca, 'xtick', 1:2:length(edges));
    set(gca, 'xticklabel', edges(1:2:end));
    xlabel('duration (sec)');
    ylabel('raw count');
    % if the variable name is cont_motion_dist_head-head_child-parent (e.g.
    % for exp 15), change teh x lable to distances
    if strcmp(varname, 'cont_motion_dist_head-head_child-parent')
        xlabel('distances (millimeters)');
    end
    ylim([0 1]);
    title('all');
    
    export_fig(gcf, sprintf('%s/%s_all', directory, nametag), '-jpg', '-nocrop');
    
    close(gcf);
end