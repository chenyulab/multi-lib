%%%
% Author: Elton Martinez
% Modifier: Elton Martinez
% Last modified: 5/21/2025
%
% This function generates summary videos of frames centered around gaze
% dependent on particular categories(object/face) during specified events.
% It also displays the category label, subID, onset, and offset at the top.
% Overlapping utterances are displayed at the bottom. 
% 
% Requirements: Computer Vision Toolbox & Image Processing Toolbox
%
% 
% Input parameters:
%   - subexpIDs
%       array of integers/ integer, subject or exp list
%   - cevent_variable
%       char/string, defines the windows of time to extract frames from
%   - output_filename
%       char/string, output video name
%   - args (optional)
%       struct, the default values of the sub-args(fields) are the indicated
%       next to the name
%
%       - agent (child)
%           char/string, 'child' or 'parent'
%           indicate the camera view to extract frames from (cam07 or cam08)
%       - cevent_dur_min (-1) 
%           positive integer, the minimum duration to include a cevent
%       - cevent_dur_max (10)
%           positive integer, the maximum duration to include a cevent
%       
%       - cat_ids ([])
%           array of integers, indicating the categories to include from the cevent
%           if empty it includes all categories from the experiment
%       - cat_dict ([])
%           empty double array, or matlab dictionary to map cat_ids to names. If emtpy it
%           will default to using the local dictionary xlsx file
%
%       - whence ('onset')
%           char/string, 'onset', 'middle', or 'offset'
%           this parameter combined with interval, allows you to select where in the cevent
%           you want to extract a frame from. Reference point can be 
%           respect to the onset, offset, or middle of the event.
%       - interval (0)
%           float, can be positive(window length after reference point) or 
%           negative(window length before reference point)
%
%      - crop_size ([600 600])
%           [width height] as positive integers. The size of the image crop with the 
%           infants gaze as its geometric center. If the location of the gaze puts the 
%           image crop outside of the image, then a new image crop will be calculate to
%           keep it in bounds. In the process gaze will no longer be the geometric center. 
%       - frame_rate (1)
%           positive integer, frame rate of output video, e.g: 3 means 3 frames per
%           second, so each instance will be displayed for 1/3 of a second 
%
% Output:
%  - .mp4 video
%   
%%%

function create_summary_movie(subexpID, cevent_variable, output_filename, varargin)
    %% Define constants 
    % set default args if emtpy and if field is not present 
    if isempty(varargin)
        args = {};
    else
        args = varargin{1};
    end

    valid_args = {"agent", "cevent_dur_min","cevent_dur_max","cat_ids","cat_dict",...
                  "whence","interval","crop_size","frame_rate"};

    default_args = {'child',-1,10,[],[],"onset",0,[600 600],1};

    for i = 1:numel(valid_args)
        if ~isfield(args, valid_args{i})
           args.(valid_args{i}) = default_args{i};
        end
    end

    % get subjects 
    subjects = cIDs(subexpID);
    expID = sub2exp(subjects(1));

    % create the video object 
    writerObj = VideoWriter(output_filename, "MPEG-4");
    writerObj.FrameRate = args.frame_rate;
    writerObj.Quality = 100;
    open(writerObj);
    
    % unpack crop size 
    target_height = args.crop_size(1);
    target_width = args.crop_size(2);

    % set frame path constants based on the agent 
    if strcmp(args.agent,'child')
        cam = 'cam07_frames_p';
    elseif strcmp(args.agent,'parent')
        cam = 'cam08_frames_p';
    end
    cont_eye = ['cont2_eye_xy_' args.agent];
    
    % get mask of subjects with target vars
    mask = false(1,numel(subjects));

    for i = 1:numel(subjects)
        mask(i) = logical(has_all_variables(subjects(i), {cevent_variable, cont_eye}));
    end
    
    % handle 1D case? 
    if isscalar(mask) 
       if mask == 0 
            subjects = [];
       end
    else 
        subjects = subjects(mask);
    end
   
    % define category dictionary 
    if isempty(args.cat_dict)
        categories = 1:get_num_obj(expID);
        labels = string(get_object_label(expID, categories));
        args.cat_dict = dictionary(categories, labels);
        args.cat_dict(numel(categories)+1) = 'face';
    end
   
    % iter through all subjects 
    for i = 1:numel(subjects)
        subID = subjects(i);
        
        %% Match cont_eye with cevent timing window
        % get only within trial gaze(xy) and target cevent times
        var = get_variable_by_trial_cat(subID, cevent_variable);
        eye = get_variable_by_trial_cat(subID, cont_eye);
        
        % if cat_ids is empty include all rois otherwise filter
        if ~isempty(args.cat_ids)
            mask = ismember(var(:,3), args.cat_ids);
            var = var(mask,:);
        end
        
        % checks where's the reference point and moves the timeline 
         if strcmp(args.whence,'onset')
            var(:,4) = var(:,1) + args.interval;
         elseif strcmp(args.whence,'middle')
            var(:,4) = (var(:,1) + var(:,2)) / 2 + args.interval;
         elseif strcmp(args.whence,'offset')
            var(:,4) = var(:,2) + args.interval;
        end
        
        % convert secs to frames 
        target_frames = [time2frame_num(var(:,4),subID), var(:,1), var(:,2), var(:,3)];
        frame_eye = [time2frame_num(eye(:,1),subID), eye];
        
        % convert array to table to do inner join 
        target_frames_df = array2table(target_frames);
        target_frames_df.Properties.VariableNames = ["frame","onset","offset","cat"];
        eye_df = array2table(frame_eye);
        eye_df.Properties.VariableNames = ["frame","cstream","x","y"];

        % get the corresponding gaze values for the target frames 
        instances_df = innerjoin(target_frames_df, eye_df);
        instances_df.dur = instances_df.offset - instances_df.onset;

        % get subdir and iterate through frames 
        sub_dir = get_subject_dir(subID);
        
        % Load subject transcription
        try
            transcription = load_speech_transcription(subID);
        catch
            transcription = {};
        end
        % preallocate transcription array 
        k = 1;

        for j = 1:height(instances_df)
            % if this instaces is too long or too short skip it
            inst_dur = instances_df{j,"dur"};

            if inst_dur < args.cevent_dur_min || inst_dur > args.cevent_dur_max
                continue
            end
            
            %% Find overlalping utterances 
            % get utterances within t_frames_concat{j}
            if ~isempty(transcription)
            cumulative_utterance = {};

                while true & k <= height(transcription) 
                    if j > height(transcription)
                        break
                    end

                    a1 = instances_df{j, "onset"};
                    a2 = instances_df{j, "offset"};
                    b1 = transcription{k, "onset"};
                    b2 = transcription{k, "offset"};

                    if cevents_have_overlap(a1,a2,b1,b2)
                        utterance = transcription{k, "utterance"}{1};
                        cumulative_utterance{end+1} = utterance;
                    end

                    % this utterance will not be selected in t+1
                    if a2 >= b2 
                       k = k + 1;
                    end
                    
                    % there can be no more utterances
                    if a2 <= b2
                        break
                    end
                end
            end

            % define subject frame path constants 
            frame_name = sprintf('img_%d.jpg', instances_df{j,"frame"});
            rel_frame_path = fullfile(sub_dir, cam, frame_name);
            
            % get frame constants
            frame = imread(rel_frame_path);
            [fHeight, fWidth, ~] = size(frame);

            % check if the frame dim of the sub is less than the dim of the
            % crop

            if fWidth < target_width || fHeight < target_height
                dim_string = sprintf('  sub:%d img:%dx%d crop:%dx%d\n',subID, fHeight, fWidth, target_height, target_width);
                error_string = ['crop size is greater than img size:' newline dim_string 'skipping subject'];
                disp(error_string)
                break
            end
            
            % get and round gaze xy 
            centerX = round(instances_df{j,"x"});
            centerY = round(instances_df{j,"y"});
    
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
            
            %% Add gaze and identifiers 
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
            target_label = instances_df{j,"cat"};

            if isKey(args.cat_dict, target_label)
                obj_label = args.cat_dict(target_label);
            else
                obj_label = "other";
            end

            % insert cat_label, subID, onset, and offset at top of frame
            target_string = sprintf('%s, %d, %.2f, %.2f', obj_label, subID, instances_df{j,"onset"}, instances_df{j,"offset"});
            relative_font = round(cF_rows * 0.05);
            RGB = insertText(croppedFrame,[0 0],target_string, FontSize=relative_font, ...
                BoxOpacity=0.4,TextColor="white", AnchorPoint="LeftTop",BoxColor="black");
            
            [rF_height, rF_width] = get_text_dimensions('a', relative_font * 0.8); 
            px_to_ch = floor(cF_col / rF_width);
            

            %% Insert utterances into frame
            % step one is to make sure every utterance fits within the crop
            % if it doesn't then break it and add it as an new utterance
            cumulative_utter_cut = {};
            
            for v = 1:numel(cumulative_utterance)
                target_utterance = cumulative_utterance{v};
                % find length of insertText (need to write to empty image
                % and isolate) suggested by the one and only chatgpt
                groups  = ceil((rF_width * numel(target_utterance)) / cF_col);
                idx_i = 1;
                idx_j = px_to_ch;
                group_utterance = {};
                
                % Here we are breaking utterances that are too big to be
                % displayed 
                if groups > 1
                    for k = 1:groups
                        if k == groups
                            group_utterance{end+1} = target_utterance(idx_i:end);
                        else
                            group_utterance{end+1} = strcat(target_utterance(idx_i:idx_j),'-');
                        end

                        idx_i = idx_j+1;
                        idx_j = idx_j + px_to_ch;
                    end
                else
                    group_utterance{end+1} = target_utterance;
                end  
                cumulative_utter_cut = horzcat(cumulative_utter_cut, group_utterance);
            end
            
            % all the utterances to the image, it the utterances take up 
            % more than 1/4 of the space stop adding them 
            cumulative_height = 0;
            for v = numel(cumulative_utter_cut):-1:1
                if cumulative_height + (3 * rF_height) >= cF_rows * 0.25
                        break
                end
                % image writting operation
                RGB = insertText(RGB, [0, cF_rows - cumulative_height], cumulative_utter_cut{v}, FontSize=floor(relative_font * 0.7), ...
                    BoxOpacity=0.4,TextColor="white", AnchorPoint="LeftBottom", BoxColor="black"); 
                cumulative_height = cumulative_height + (3 * rF_height);
            end
            writeVideo(writerObj, RGB);
        end
    end 
    % close object 
    close(writerObj);
    fprintf("Movie saved under %s.mp4\n",  output_filename)
end

% helper function for create_summary_movie
% approximates the size of a ch in pixels 
function [text_height, text_width] = get_text_dimensions(text, font_size)

    x = zeros(1000, 1000, 3);
    y = insertText(x, [0,0], text,'FontSize', font_size, 'BoxColor', 'white', ...
                     'TextColor', 'white', 'BoxOpacity', 0);
   
    grayY = rgb2gray(y);
    box_mask = grayY > 0;
    stats = regionprops(box_mask, 'BoundingBox');
    text_width = stats(1).BoundingBox(3);
    text_height = stats(1).BoundingBox(4);
end

