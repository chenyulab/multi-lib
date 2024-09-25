%%%
% This function read exp_list and create frame_status table in Multiwork
% Author: Jingwen Pang
% last update: 9/25/2024
% Input: exp list
% output: frame_status table that include frame number, width, height for
% the frames in each frame folder, up to 30 cameras
%%%
function main_generate_frame_status(exp_list)
    % exp_list = [12, 15, 27, 58, 59, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 77, 78, 79,  91, 96, 351, 353, 355, 361, 362, 363];
    max_cam = 30;
    table_name = "M:\frame_status.csv";
    
    % create headers
    headers = {'subject_id'};
    for i = 1:max_cam
        headers{end+1} = sprintf('cam%02d_number',i);
        headers{end+1} = sprintf('cam%02d_width',i);
        headers{end+1} = sprintf('cam%02d_height',i);
    end
    % create table
    data_table = table('Size', [0, length(headers)], 'VariableTypes', repmat("double", 1, length(headers)), 'VariableNames', headers);
    writetable(data_table,table_name);
    
    subIDs = cIDs(exp_list);
    generate_frame_status(subIDs);
end