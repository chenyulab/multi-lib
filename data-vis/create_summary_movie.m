%%%
% Author: Elton Martinez
% Modifier: Elton Martinez
% Last modified: 1/23/2024
%
% This function generate summary videos focused on particular 
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
%%%
function create_summary_movie(subexpIDs, agent, cevent_variable, cat_ids, ...
    reference_point, offset_time, crop_size, frame_rate, out_vid_name)

    % create the video object 
    writerObj = VideoWriter(out_vid_name, 'MPEG-4');
    writerObj.FrameRate = frame_rate;
    open(writerObj);
    
    % unpack crop size 
    target_height = crop_size(1);
    target_width = crop_size(2);

    % set frame path constants based on the agent 
    if strcmp(agent,'child')
        cam = 'cam07_frames_p';
    elseif strcmp(agent,'parent')
        cam = 'cam08_frames_p';
    end
    cont_eye = ['cont2_eye_xy_' agent];
    
    subexpIDs = cIDs(subexpIDs);

    % get mask of subjects with target vars 
    mask = arrayfun(@(x) has_all_variables(x, {cont_eye, cevent_variable}), subexpIDs);
    subexpIDs = subexpIDs(mask);

    expID = sub2exp(subexpIDs(1));
    category_names = get_object_label(expID, 1:get_num_obj(expID));
    category_names{end+1} = 'face';
        
    % iter through all subjects 
    for z= 1:numel(subexpIDs)
        subject_id = subexpIDs(z);
        
        % get only within trial gaze(xy) and target cevent times
        var = get_variable_by_trial_cat(subject_id, cevent_variable);
        eye = get_variable_by_trial_cat(subject_id, cont_eye);
        
        % if cat_ids is empty include all rois otherwise filter
        if ~isempty(cat_ids)
            mask = ismember(var(:,3), cat_ids);
            var = var(mask,:);
        end
        
        % checks where's the reference point and moves the timeline 
        if strcmp(reference_point,'onset')
            var(:,4) = var(:,1) + offset_time;
        elseif strcmp(reference_point,'middle')
            var(:,4) = (var(:,1) + var(:,2)) / 2 + offset_time;
        elseif strcmp(reference_point,'offset')
            var(:,4) = var(:,2) + offset_time;
        end
        
        % convert secs to frames 
        target_frames = time2frame_num(var(:,4),subject_id);
        eye(:,4) = time2frame_num(eye(:,1),subject_id);
        
        % convert array to table to do inner join 
        t_target_frames = array2table(target_frames);
        t_eye = array2table(eye(:,2:4));

        % get the corresponding gaze values for the target frames 
        t_frames_concat = innerjoin(t_target_frames, t_eye,'LeftKeys',1,'RightKeys',3);
        
        % get subdir and iterate through frames 
        sub_dir = get_subject_dir(subject_id);
          

        for i = 1:height(t_frames_concat)
            % define subject frame path constants 
            frame_name = sprintf('img_%d.jpg', t_frames_concat{i,1});
            rel_frame_path = fullfile(sub_dir, cam, frame_name);
            
            % get frame constants
            frame = imread(rel_frame_path);
            [fHeight, fWidth, ~] = size(frame);

            % check if the frame dim of the sub is less than the dim of the
            % crop

            if fWidth < target_width || fHeight < target_height
                dim_string = sprintf('  sub:%d img:%dx%d crop:%dx%d\n',subject_id, fHeight, fWidth, target_height, target_width);
                error_string = ['crop size is greater than img size:' newline dim_string 'skipping subject'];
                disp(error_string)
                break
            end
            
            % get and round gaze xy 
            centerX = round(t_frames_concat{i,2});
            centerY = round(t_frames_concat{i,3});
    
            if isnan(centerX) || isnan(centerY)
                continue
            end
            
            % find the top and bottom corner of the target crop
            top_x = round(centerX - (target_width/2));
            top_y = round(centerY - (target_height/2));
        
            low_x = round(centerX + (target_width/2));
            low_y = round(centerY + (target_height/2));
            
            %% If target crop is out of bounds 

            % if the x location of the crop is right-out of bounds
            if (fWidth - low_x) < 0
                top_x = top_x - abs(fWidth - low_x);
                %low_x = low_x - abs(fWidth - low_x);
            end
            
            % if the x location of the crop is left-out of bounds 
            if top_x < 0
                top_x = top_x + abs(top_x) + 1;
                %low_x = low_x + abs(top_x);
            end
        
            % if the y location of the crop is bottom-out of bounds 
            if (fHeight - low_y) < 0
                top_y = top_y - abs(fHeight - low_y);
                %low_y = low_y - abs(fHeight - low_y);
            end
        
            % if the y location of the crop is top-out of bounds 
            if top_y < 0
                top_y = top_y + abs(top_y) + 1;
                %low_y = low_y + abs(top_y);
            end
            
            % add red dot to indicate gaze 
            img = insertShape(frame, 'FilledCircle', [centerX, centerY, 10], 'Color', 'red', 'Opacity', 1);
            % define valid rect and crop frame based on it's dim and coor
            rect = [top_x top_y, target_width-1, target_height-1];     
            croppedFrame = imcrop(img, rect);   
            
            % target crop constants 
            [cF_rows, cF_col, ~] = size(croppedFrame);
            
            % This deals with the dim requirements of the H.264 code, must
            % be even 
            if mod(cF_rows, 2)
                croppedFrame = padarray(croppedFrame, [1 0], 'replicate', 'post');
            end
            
            if mod(cF_col, 2)
                croppedFrame = padarray(croppedFrame, [0 1], 'replicate', 'post');
            end
            
            % Insert the subject id and cat name to the crop (top)
            obj_label = category_names{var(i,3)};
            target_string = ['subID: ' num2str(subject_id),'     ','catID: ' obj_label];
            relative_font = round(cF_rows * 0.05);
            RGB = insertText(croppedFrame,[0 0],target_string, FontSize=relative_font, ...
                BoxOpacity=0.4,TextColor="white", AnchorPoint="LeftTop",BoxColor="black");
            
            % Insert the timming into to the crop (bottom)
            target_string = ['onset:', num2str(var(i,1)) ,'     ' ,'offset: ',num2str(var(i,2))];
            RGB = insertText(RGB,[0 cF_rows],target_string, FontSize=relative_font, ...
                BoxOpacity=0.4,TextColor="white", AnchorPoint="LeftBottom",BoxColor="black");
            
            % write the crop to the video object 
            writeVideo(writerObj, RGB);
        end 
    end
    close(writerObj);
    fprintf("Movie saved under %s.mp4\n", fullfile(pwd, out_vid_name))
end