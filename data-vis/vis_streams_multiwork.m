function vis_streams_multiwork_v2(subexpIDs, vars, streamlabels, directory, args)
% see demo_vis_streams_multiwork for documentation
if ischar(subexpIDs) && contains(subexpIDs, 'demo')
    switch subexpIDs
        case 'demo1'
            subexpIDs = [7206, 7207];
            vars = {'cstream_eye_roi_child', 'cstream_eye_roi_parent'};
            directory = '/desktop/vis_streams_multiwork';
            streamlabels = {'ceye', 'peye'};
    end
end

if ~exist('args', 'var') || isempty(args)
    args = struct();
end

if ~isfield(args, 'draw_edge')
    args.draw_edge = 1;
end

if ~isfield(args, 'colors')
    args.colors = [];
end

[subs,subtable,subpaths] = cIDs(subexpIDs);

for s = 1:numel(subs)
    try
        filenames = cell(numel(vars), 1);
        for v = 1:numel(vars)
            if ischar(vars{v})
                filenames{v,1} = fullfile(subpaths{s}, [vars{v} '.mat']);
            else
                filenames{v,1} = vars{v};
            end
        end
        if isfield(args, 'window_times_variable')
            if ischar(args.window_times_variable)
                window_times_file = fullfile(subpaths{s}, [args.window_times_variable '.mat']);
            else
                window_times_file = args.window_times_variable;

            end
        elseif ismember(subtable(s,2), [12])
            window_times_file = [];
        else
            window_times_file = fullfile(subpaths{s}, 'cevent_trials.mat');

            % get the time mitrix from this file 
            data = load_data_from_file(window_times_file);
           
            % Quadrature the entire timeline and store it as a 1 x 1 struct
            first_onset = data(1,1);
            last_offset = data(end, 2);
            total_length = last_offset - first_onset;
            avg_length = ceil(total_length / 4);
            sdata = struct('data',[first_onset, first_onset + avg_length, 1;
                    first_onset + avg_length, first_onset + 2*avg_length, 2;
                    first_onset + 2*avg_length, first_onset + 3*avg_length, 3;
                    first_onset + 3*avg_length, first_onset + 4*avg_length, 4;]);

            % save the quartered mitrix as a temporarily file
            save("new_cevent_trials",'sdata');

            window_times_file = 'new_cevent_trials.mat';
        end
        flag_dir = 1;
        if exist('directory', 'var') && ~isempty(directory)
            if exist(directory, 'dir')
                savefilename = fullfile(directory, sprintf('%d.png', subs(s)));
            else
                error('%s does not exist', directory);
            end
        else
            savefilename = [];
            flag_dir = 0;
        end
        
        args.titlelabel = sprintf('%d', subs(s));
        h = vis_streams_files(filenames, window_times_file, savefilename, streamlabels, args);

        % delete the temporarily file
        delete(window_times_file)
        if flag_dir
            close(h);
        end
    catch ME
        format_error_message(ME, sprintf('%d', subs(s)));
        continue;
    end
end
end