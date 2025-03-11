%%%
% Author: Elton Martinez
% Modifier: Jingwen Pang
% Last modified: 12/05/2024
%
% This demo function provides several examples of how to use 
% create_summary_movie to generate summary videos focused on particular 
% categories(object/face) during specified events. 
% 
% Input parameters:
%   - subexpIDs
%       array of integers, subject or exp list
%   - agent
%       string, 'child' or 'parent'
%       indicate the camera view to extract frames from (cam07 or cam08)
%   - cevent_variable
%       string, defines the windows of time to extract frames from
%   - cat_ids
%       array of integers, indicating the categories to include from the cevent
%   - reference_point
%       string, 'onset', 'middle', or 'offset'
%       this parameter combined with offset_time, allows you to select the 
%       cevent_variable window. Reference point can be 
%       respect to the onset, offset, or middle of the event.
%   - offset_time
%       float, can be positive(window length after reference point) or 
%       negative(window length before reference point)
%   - crop_size
%       [width height] crop window size
%   - frame_rate
%       integer, frame rate of output video, e.g: 3 means 3 frames per second
%   - out_vid_name
%       string, output video name
%
%   Output:
%       .mp4 video
%   
%%%
function demo_create_summary_movie(option)

    switch option
        case 1

            %{ 
            The cevent variable is eye_roi_child, we extract it for two 
            subjects (child's view). However we are interested in frames 0.10
            secs after the end of the cevent. So offset_time = 0.10 and
            reference_point = offset. We only include objects 12, 5, and 22 so 
            all other roi instances will be excluded. Lastly the crop size is
            300x300. For reference the frame size of exp 12,15 is 640x480.
            The frame rate here is 3, a longer frame rate will force a
            longer video duration 

            %}
            
            subexpIDs = [1201 1202];
            agent = 'child';
            cevent_variable = 'cevent_eye_roi_child';
            cat_ids = [12 5 22];
            reference_point = 'offset';
            offset_time = 0.10;
            crop_size = [300 300];
            frame_rate = 3;
            out_vid_name = 'Z:\CORE\repository_new\multi-lib\demo_results\summary_movie\case1';

           create_summary_movie(subexpIDs, agent, cevent_variable, cat_ids, ...
                                reference_point, offset_time, crop_size, frame_rate, out_vid_name)
         case 2

            %{
            Similary to above we are getting a subset of data. Something
            unique here is that cat_ids is empty, this will included all
            rois. Also here we used middle as the reference point. So we
            will get all the frames 0.10 after the middle point of the
            cevent. 
            %}
            
            subexpIDs = [1201 1205];
            agent = 'parent';
            cevent_variable = 'cevent_eye_roi_parent';
            cat_ids = [];
            reference_point = 'middle';
            offset_time = 0.10;
            crop_size = [300 300];
            frame_rate = 1;
            out_vid_name = 'Z:\CORE\repository_new\multi-lib\demo_results\summary_movie\case2';
    
           create_summary_movie(subexpIDs, agent, cevent_variable, cat_ids, ...
                                reference_point, offset_time, crop_size, frame_rate, out_vid_name)

           case 3

            %{
            Here we are only passing an experiment ID this will include all
            subjects that have the cevent variable. We do not want to shift 
            the timeline so set reference point to any valid value and set
            offset_time = 0
            %}

            subexpIDs = [12, 15];
            agent = 'parent';
            cevent_variable = 'cevent_eye_roi_parent';
            cat_ids = [];
            reference_point = 'middle';
            offset_time = 0;
            crop_size = [300 300];
            frame_rate = 1;
            out_vid_name = 'Z:\CORE\repository_new\multi-lib\demo_results\summary_movie\case3';
    
           create_summary_movie(subexpIDs, agent, cevent_variable, cat_ids, ...
                                reference_point, offset_time, crop_size, frame_rate, out_vid_name)

    
    end
end
