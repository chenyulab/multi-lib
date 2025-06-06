%%%
% Author: Jingwen Pang
% last edited: 06/04/2025
% this function reads the child/parent_eye.csv from raw neon recording data,
% extract the time based on extract_range.txt and transfer the extracted
% data into multi-work.
% grey_screen_offset: for the subjects has grey screen issue 
% (if the world video was token from Native Recording Data directly, which did not align with the timestamps in exported data)
% Example function call: make_saccades(35321,'child')
%%%
function record_eyegaze_datavyu(subID,agent)


    %% check if the subjects contains grey screen
    % grey screen issue subjects' data
    grey_screen_subject = [35131,35130,35132,35134,35135,35136,35137,35138,35141,...
    35328,35330,35332,35333,35334,35335,35337,35341,36126,36132,36133,36140 ...
    36228,36230,36232,36236,36240,36332,36333,36340 ...
    36428,36430,36432,36433,36435,36436,36440];
    grey_screen_child = [2261.4,1345.08,1657,2139.407,1677.697,2530.64,1701.31,2896.58,...
    0,707.36,1657,2759.73,1677.697,2530.64,1701.31,2357.044,0,0,2139.41,1677.7,0 ...
    707.36,1657,2139.41,2896.58,0,2139.41,1677.7,0 ... 
    707.36,1657,2139.41,1677.7,1701.31,2896.58,0];
    grey_screen_parent = [2944.046,1039.138,2895.587,2259.588,1879.582,2084.99,912.882,...
    0,2198.345,2498,2895.587,2259.588,1879.582,2084.99,912.882,1185.83,2198.345,40.013,2259.588,1879.582,2198.345...
    2498,2895.587,2259.588,0,2198.345,2259.588,1879.582,2198.345 ...
    2498,2895.587,2259.588,1879.582,912.882,0,2198.345];

    sample_rate_raw = 200;
    
    idx = find (subID == grey_screen_subject);

    if isempty(idx)
        grey_screen_offset = 0;
    elseif strcmp(agent,'child')
        grey_screen_offset = grey_screen_child(idx);
    elseif strcmp(agent,'parent')
        grey_screen_offset = grey_screen_parent(idx);
    end
    
    %% reading sccades file and generate variables
    % system start time
    system_start = 30;

    % get Datavyu input_filename from supporting file folder of each
    % subject
    root = get_subject_dir(subID);
    input_filename = fullfile(root,'supporting_files',sprintf('%s_eye.csv',agent));

    % get the time offset based on the first onset in extract range
    input_range_filename = fullfile(root,'supporting_files','extract_range.txt');
    rangeID = fopen(input_range_filename, 'r');
    range_onset = fgetl(rangeID);
    range_onset = str2double(range_onset(2:end-1));
    fclose(rangeID);
    time_offset = range_onset/30;

    % read summary input data file
    data = readtable(input_filename);

    % get column data
    timestamp = data.timestamp;
    fixation = data.fixation;
    pos_x = data.gazex;
    pos_y = data.gazey;


   % get rid of trailing NaN values
    timestamp = timestamp(~isnan(timestamp));
    fixation = fixation(~isnan(fixation));
    pos_x = pos_x(~isnan(pos_x));
    pos_y = pos_y(~isnan(pos_y));

    pos_x = round(pos_x);
    pos_y = round(pos_y);

    converted_timestamp = timestamp/1000 - time_offset + system_start - grey_screen_offset/1000;
    


    %% Save variables in derived folder in Multiwork experiment folder
    % save cont var
    % cevent_x = [new_onset new_offset pos_x];
    % cevent_y = [new_onset new_offset pos_y];
    % rate = get_rate(subID);
    % cont_mtr_x = cevent2cont(cevent_x,floor(cevent_x(1,1)),1/rate,0);
    % cont_mtr_y = cevent2cont(cevent_y,floor(cevent_y(1,1)),1/rate,0);
    % 
    % cont2_mtr = [cont_mtr_x cont_mtr_y(:,2)];

    % record raw sample rate eye gaze data
    cont2_raw = [converted_timestamp pos_x pos_y];

    var_name = sprintf('eye_xy_%dhz_%s',sample_rate_raw, agent);

    % record_additional_variable(subID,['cont2_' char(var_name)],cont2_raw);


    % convert data to 30 hz, align with system sample rate
    target_rate = 30;
    dt = 1/target_rate;
    start_time = round(converted_timestamp(1) * target_rate) / target_rate;
    end_time = round(converted_timestamp(end) * target_rate) / target_rate;

    new_timestamp = (start_time:dt:end_time);

    new_pos_x = zeros(size(new_timestamp));
    new_pos_y = zeros(size(new_timestamp));

    for i = 1:length(new_timestamp)
        t0 = new_timestamp(i);
        t1 = t0 + dt;
        idx = converted_timestamp >= t0 & converted_timestamp < t1;

        if any(idx)
            x_diff = max(pos_x(idx)) - min(pos_x(idx));
            disp(x_diff)
            new_pos_x(i) = mean(pos_x(idx));
            new_pos_y(i) = mean(pos_y(idx));
        else
            new_pos_x(i) = NaN;
            new_pos_y(i) = NaN;
        end
    end

    cont2 = [new_timestamp' new_pos_x' new_pos_y'];

    var_name = sprintf('eye_xy_%s',agent);

    % record_variable(subID,['cont2_' char(var_name)],cont2);

    %disp(cont2);


    % convert data into event base, using fixation
    change_idx = [1; find(diff(fixation) ~= 0) + 1; length(fixation) + 1];

    fixation_events = [];

    for i = 1:length(change_idx)-1
        start_idx = change_idx(i);
        end_idx = change_idx(i+1) - 1;

        if fixation(start_idx) == 1
            onset = converted_timestamp(start_idx);
            offset = converted_timestamp(end_idx);
            avg_pos_x = round(mean(pos_x(start_idx:end_idx)));
            avg_pos_y = round(mean(pos_y(start_idx:end_idx)));

            fixation_events = [fixation_events; onset, offset, avg_pos_x, avg_pos_y];
        end
    end

    var_name = sprintf('eye_fixation_xy_%s',agent);

    % record_additional_variable(subID,['cevent2_' char(var_name)],fixation_events);

end