%%%
% This function read the frame status table and return the number of
% frames, frame width, frame height for 1 subject 1 camera.
% Author: Jingwen Pang
% last update: 9/25/2024
% example use: get_frame_status(35301,1)
%%%
function [number,width,height] = get_frame_status(sub_id,cam_id)
frame_number = cam_id * 3 - 1;
frame_width = cam_id * 3;
frame_height = cam_id * 3 + 1;

table_name = "M:/frame_status.csv";
data = table2array(readtable(table_name));

number = data(data(:,1)==sub_id,frame_number);
width = data(data(:,1)==sub_id,frame_width);
height = data(data(:,1)==sub_id,frame_height);

end