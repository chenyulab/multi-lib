function run_rot_speed_imu(subID,agent)

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
    
    idx = find(subID == grey_screen_subject);

    if isempty(idx)
        grey_screen_offset = 0;
    elseif strcmp(agent,'child')
        grey_screen_offset = grey_screen_child(idx);
    elseif strcmp(agent,'parent')
        grey_screen_offset = grey_screen_parent(idx);
    end
    
    %% read IMU file and generate variables 
    % system start time
    system_start = 30;

    % get Datavyu input_filename from supporting file folder of each
    % subject
    root = get_subject_dir(subID);
    input_filename = fullfile(root,'supporting_files',sprintf('%s_imu.csv',agent));

    % get the time offset based on the first onset in extract range
    % input_range_filename = fullfile(root,'supporting_files','extract_range.txt');
    % rangeID = fopen(input_range_filename, 'r');
    % range_onset = fgetl(rangeID);
    % range_onset = str2double(range_onset(2:end-1));
    % fclose(rangeID);
    % time_offset = range_onset/30;

    % read summary input data file
    data = readtable(input_filename);

    % get column data
    timestamp = data.timestamp_ns_;
    gyro_x = data.gyroX_deg_s_;
    gyro_y = data.gyroY_deg_s_;
    gyro_z = data.gyroZ_deg_s_;

    roll = mod(data.roll_deg_, 360);
    pitch = mod(data.pitch_deg_, 360);
    yaw = mod(data.yaw_deg_, 360);

    % converted_timestamp = timestamp/1000 - time_offset + system_start - grey_screen_offset/1000;
    converted_timestamp = timestamp/1000 + system_start;

    %% Save variables in derived folder in Multiwork experiment folder
    gyro = sqrt(gyro_x.^2 + gyro_y.^2 + gyro_z.^2);
    gyro_data_raw = [converted_timestamp,gyro];


    % convert data to 30 hz, align with system sample rate
    target_rate = 30;
    dt = 1/target_rate;
    
    % Build a 30 Hz timeline aligned to 30 fps grid
    start_time = ceil(converted_timestamp(1) * target_rate) / target_rate;
    end_time   = floor(converted_timestamp(end) * target_rate) / target_rate;
    new_timestamp = (start_time:dt:end_time)';
    
    % Preallocate
    gyro_x_30 = nan(size(new_timestamp));
    gyro_y_30 = nan(size(new_timestamp));
    gyro_z_30 = nan(size(new_timestamp));
    gyro_30   = nan(size(new_timestamp));

    roll_30 = nan(size(new_timestamp));
    pitch_30 = nan(size(new_timestamp));
    yaw_30 = nan(size(new_timestamp));
    
    % Bin edges: [t, t+dt)
    for i = 1:length(new_timestamp)
        t0 = new_timestamp(i);
        t1 = t0 + dt;
    
        idx_bin = (converted_timestamp >= t0) & (converted_timestamp < t1);
    
        if any(idx_bin)
            gyro_x_30(i) = median(gyro_x(idx_bin), 'omitnan');
            gyro_y_30(i) = median(gyro_y(idx_bin), 'omitnan');
            gyro_z_30(i) = median(gyro_z(idx_bin), 'omitnan');
            gyro_30(i)   = median(gyro(idx_bin),   'omitnan');

            roll_30(i) = median(roll(idx_bin), 'omitnan');
            pitch_30(i) = median(pitch(idx_bin), 'omitnan');
            yaw_30(i) = median(yaw(idx_bin), 'omitnan');
        end
    end
    
    % Pack as cont variables: [timestamp value]
    gyro_data_30   = [new_timestamp, gyro_30];

    roll_data_30 = [new_timestamp,roll_30];
    pitch_data_30 = [new_timestamp,pitch_30];
    yaw_data_30 = [new_timestamp,yaw_30];
    
    % Save (use a consistent naming scheme) 
    var_name = sprintf('motion_heading_head_%s', agent);
    record_additional_variable(subID, ['cont_' char(var_name)], yaw_data_30);

    var_name = sprintf('motion_roll_head_%s', agent);
    record_additional_variable(subID, ['cont_' char(var_name)], roll_data_30);

    var_name = sprintf('motion_pitch_head_%s', agent);
    record_additional_variable(subID, ['cont_' char(var_name)], pitch_data_30);

    var_name = sprintf('motion_rot-speed_head_%s', agent);
    record_variable(subID, ['cont_' char(var_name)], gyro_data_30);


end
