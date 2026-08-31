function run_vis_streams_timeseries(subexpIDs)
%   timeseries_1: eye roi, child and parent
%   timeseries_2: joint attention
%   timeseries_3: naming
%   timeseries_4: inhand, child left and right
%   timeseries_5: inhand, parent left and right

vis_savepath = get_dir_vis();

var_list = {
    {'cevent_eye_roi_child', 'cevent_eye_roi_parent'}
    'cevent_eye_joint-attend_both'
    'cevent_speech_naming_local-id'
    {'cevent_inhand_left-hand_obj-all_child', 'cevent_inhand_right-hand_obj-all_child'}
    {'cevent_inhand_left-hand_obj-all_parent', 'cevent_inhand_right-hand_obj-all_parent'}
    };
names = {'roi', 'roi_dyad', 'naming', 'inhand_child', 'inhand_parent'};

[~, table] = cIDs(subexpIDs);
exps = unique(table(:,2));

for v = 1:numel(var_list)
    directory = fullfile(vis_savepath, sprintf('timeseries_%d', v));
    if ~exist(directory, 'dir')
        mkdir(directory);
    end

    for e = 1:numel(exps)
        try
            args = struct();
            args.save_name = sprintf('%d', exps(e));
            args.title = sprintf('exp %d: %s', exps(e), names{v});
            vis_streams_timeseries(exps(e), var_list{v}, directory, args);
        catch ME
            format_error_message(ME, sprintf('%d %s', exps(e), names{v}));
        end
        close all
    end
end
end
