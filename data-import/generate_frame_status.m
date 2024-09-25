%%%
% this function update the subject frame information in frame_status table
% Author: Jingwen Pang
% last update: 9/25/2024
% input: list of subjects
% output: updated version of frame status table
%%%
function generate_frame_status(subIDs)
table_name = "M:/frame_status.csv";
max_cam = 30;
group_data = [];
big_table = readtable(table_name);

headers = big_table.Properties.VariableNames;

for s = 1: length(subIDs)
    subID = subIDs(s);
    data = [subID];
    for i = 1:max_cam
        [number,width,height,~] = inport_frame_status(subID,i);
        data = [data,number,width,height];
    end
    group_data = [group_data;data];
end 

table = array2table(group_data,"VariableNames",headers);


[in_big_table, idx_in_big_table] = ismember(table.subject_id, big_table.subject_id);

big_table(idx_in_big_table(in_big_table), :) = table(in_big_table, :);

big_table = [big_table; table(~in_big_table, :)];

writetable(big_table,table_name);
end

function [number,width,height] =  inport_frame_status(subject_id,cam_id)
% get the frame resolution for specific camera
    frame_folder = sprintf('cam%02d_frames_p',cam_id);
    path = fullfile(get_subject_dir(subject_id),frame_folder);
    frame_files = dir(fullfile(path, '*.jpg'));
    
    if ~isempty(frame_files)
        frame_name = frame_files(1).name;
        frame_info = imfinfo(fullfile(path,frame_name));
        number = size(frame_files,1);
        width = frame_info.Width;
        height = frame_info.Height;
    else
        sprintf('no frames found in %d cam%02d!',subject_id,cam_id)
        number = 0;
        width = NaN;
        height = NaN;
    end
end