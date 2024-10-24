%%%
% Author: Jingwen Pang
% last edited: 08/30/2024
% this function reads the saccades.csv from raw neon recording data,
% extract the time based on extract_range.txt and transfer the extracted
% data into multi-work.
% grey_screen_offset: for the subjects has grey screen issue 
% (if the world video was token from Native Recording Data directly, which did not align with the timestamps in exported data)
% Example function call: make_saccades(35321,'child')
%%%
function make_saccades(subID,agent)

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
    input_filename = fullfile(root,'supporting_files',sprintf('%s_saccades.csv',agent));

    % get the time offset based on the first onset in extract range
    input_range_filename = fullfile(root,'supporting_files','extract_range.txt');
    rangeID = fopen(input_range_filename, 'r');
    range_onset = fgetl(rangeID);
    range_onset = str2double(range_onset(2));
    fclose(rangeID);
    time_offset = range_onset/30;

    % read summary input data file
    data = readtable(input_filename);

    % get column data
    onset = data.onset;
    offset = data.offset;
    label = data.rotate_angles;


   % get rid of trailing NaN values
    onset = onset(~isnan(onset));
    offset = offset(~isnan(offset));
    label = label(~isnan(label));

    new_onset = zeros(size(onset));
    new_offset = zeros(size(offset));
    label = round(label);

    for j = 1:size(label,1)
        % convert raw timestamps to system time
        new_onset(j) = onset(j)/1000;
        new_offset(j) = offset(j)/1000;
        new_onset(j) = new_onset(j) - time_offset + system_start - grey_screen_offset/1000;
        new_offset(j) = new_offset(j) - time_offset + system_start - grey_screen_offset/1000;

   end

    %% Save variables in derived folder in Multiwork experiment folder
    % save cont var
    cevent_mtr = [new_onset new_offset label];
    var_name = sprintf('eye_saccades_angle_%s',agent);
    % rate = get_rate(subID);
    % cont_mtr = cevent2cont(cevent_mtr,floor(cevent_mtr(1,1)),1/rate,0);

    record_additional_variable(subID,['cevent1_' char(var_name)],cevent_mtr);


end