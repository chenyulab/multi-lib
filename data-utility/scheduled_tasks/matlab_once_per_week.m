%%
% the rewritten version of matlab_once_per_week routine visualization script
% general configurations
% add exp [58 59 47 87 91:94 100:154] to all exps

% add three functions: 1) draw_correlation_plots_v2 & 2) get_age_at_exp_v2 & 3) vis_spatial_ja to MATLAB search path
clear
clc
set(0,'DefaultFigureVisible','off')
vis_savepath = get_dir_vis();
% all_subs = [cIDs('all'); cIDs([58 59 47 87 90:94 100:154])];
all_subs = unique(cIDs(list_experiments));

dir_matlab = 'c:';
path_log = fullfile(dir_matlab, 'space', 'CORE', 'scheduled_tasks', 'exception_log.txt');
diary(path_log);

%%
% run script to update basic.tsv file
disp("==============================")
disp('[*] Updating basic.tsv files...')
disp("==============================")
extract_basic_demographic()

%%
% run vis_hist plots
% rewritten version of master_vis_hist
% change from "encounter error-abort" to "ecounter error-skip to next"
% add case 5 generating the 'cont_motion_dist_head-head_child-parent' histogram (todo: the x and y labels' names need to be changed)
disp("==============================")
disp('[*] Running histogram visualization...')
disp("==============================")

% directory = fullfile(vis_savepath, 'vis_hist');
% flag_savefig = 1;
sub = all_subs;

for option = [1:5]
    master_vis_hist(sub, option)
end

%%
% run cross-correlation plots (working on the whole list of subjects basis, if any of them break, the whole thing stops)
% based on the tssting, it works fine with no problem
% copied from the orignal matlab_once_per_week script + error handling
% around the whole script
disp("==============================")
disp('[*] Running cross correlation plots...')
disp("==============================")

subs = all_subs;

run_cross_correlation_plots(subs)

%%
% run cstream visualization plots
% copied from the orignal matlab_once_per_week script
% subs = all_subs;
disp("==============================")
disp('[*] Running cstream visualizations...')
disp("==============================")

subs = all_subs;

try
    for a = [1 2 3 4 5 6 7]
        master_data_vis(subs, a);
        disp(['cstream option: ' num2str(a) ' finished'])
    end
catch ME
    disp(ME.message);
end

%%
% run object_stats plots
% copied from the orignal matlab_once_per_week script
disp("==============================")
disp('[*] Running object stats...')
disp("==============================")

subs = all_subs;

run_visualize_basic_stats_per_object(subs)

%%
% run correlation plots
% adapted from run_correlation plots
% instead of using draw_correlation_plots, calls draw_correlation_plots_v2
%   draw_correlation_plots_v2
%       adapted from the previous draw_correlation_plots
%       rewrite the get_age_at_exp (new name: get_age_at_exp_v2)
%       fixed a typeerror in the original script line_37
%       add exp [58 59 47 87 91:94 100:154] to allsubs var
disp("==============================")
disp('[*] Running correlation plots...')
disp("==============================")

for a = [1 2 3]
    run_correlation_plots(subs, a)
end

%%
% run gaze heatmap for both child and parent views
disp("==============================")
disp('[*] Running gaze xy heatmap plots...')
disp("==============================")

subs = all_subs;

expIDs = unique(sub2exp(subs));
for i = 1:numel(expIDs)
    try
        generate_gaze_data_heatmap_v2(expIDs(i), 'child', 'child_gaze')
    catch ME
        disp(ME.message)
    end
    try
        generate_gaze_data_heatmap_v2(expIDs(i), 'parent', 'parent_gaze')
    catch ME
        disp(ME.message)
    end
end

%%
% generate spactial ja plots (curently only for exp 15)
% to check detailed description of vis_spatial_ja: help vis_spatial_ja
disp("==============================")
disp('[*]Running spatial_JA plots...')
disp("==============================")

directory = fullfile(vis_savepath, 'spatial_ja');
subs = [15];
vis_spatial_ja(subs, 10, directory)
