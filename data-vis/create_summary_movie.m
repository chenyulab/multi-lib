%%%
% Author: Elton Martinez
% Modifier: Elton Martinez
% Last modified: 6/3/2025
%
% This function generates summary videos of frames centered around gaze
% dependent on particular categories(object/face) during specified events.
% It also displays the category label, subID, onset, and offset at the top.
% Overlapping utterances are displayed at the bottom. 
% 
% Requirements: Computer Vision Toolbox & Image Processing Toolbox
%
% 
%% Input parameters:
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
%       - cam_num (7)
%           integer (1-24), indicate the camera view to extract frames from. E.g.,
%           10 is cam10. If cameras 1,2,7,and 8 are defined then gaze is included.  
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
%      - crop_size (no crop)
%           [width height] as positive integers. The size of the image crop with the 
%           infants gaze as its geometric center. If cam is not a first
%           person view, the center of the image will be the center of the
%           crop. If the location of the gaze puts the image crop outside of the image, 
%           then a new image crop will be calculate to keep it in bounds. 
%           In the process gaze will no longer be the geometric center. 
%       - frame_rate (1)
%           positive integer, frame rate of output video, e.g: 3 means 3 frames per
%           second, so each instance will be displayed for 1/3 of a second 
%
%% Output:
%  - .mp4 video
%   
%%%

function create_summary_movie(subexpID, cevent_variable, output_filename, varargin)
    warning('off','MATLAB:table:ModifiedAndSavedVarnames')
    %% Define constants 
    % set default args if emtpy and if field is not present 
    if isempty(varargin)
        args = {};
    else
        args = varargin{1};
    end

    valid_args = {"cam_num", "cevent_dur_min","cevent_dur_max","cat_ids","cat_dict",...
                  "whence","interval","crop_size","frame_rate"};

    default_args = {7,-1,10,[],[],"onset",0,[0 0],1};

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
    
    % unpack crop size 
    crop_height = args.crop_size(2);
    crop_width = args.crop_size(1);

    if crop_width + crop_height == 0      
        no_crop = true;
    else
        no_crop = false;
    end

    % create relative cam path and include gaze depending on 
    % the target camera 
    if args.cam_num < 10
       cam_folder = "cam0" + int2str(args.cam_num);
    else
        cam_folder = "cam" + int2str(args.cam_num);
    end

    cam = sprintf('%s_frames_p',cam_folder);
    include_gaze = true;
    variables = {cevent_variable};

    if ismember(cam_folder, ["cam07","cam08","cam01","cam02"])
        if ismember(cam_folder, ["cam07", "cam01"])
            cont_eye = 'cont2_eye_xy_child';
        else
            cont_eye = 'cont2_eye_xy_parent';
        end
        variables{end+1} = cont_eye;
    else
        include_gaze = false;
    end
   
    % get mask of subjects with target vars
    % display if subject is missing var
    mask = false(1,numel(subjects));

    for i = 1:numel(subjects)
        has_both = true;
        has_target = has_variable(subjects(i), variables{1});

        if length(variables) == 2
            has_gaze = has_variable(subjects(i), variables{2});

            if ~has_gaze
                fprintf("Subject %d is missing %s\n",subjects(i),variables{2})
                has_both = has_both & has_gaze;
            end
        end

        if ~has_target 
            fprintf("Subject %d is missing %s\n",subjects(i),variables{1})
        end

        if ~has_both
            continue
        end
        mask(i) = has_both & has_target;
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

    % progress bar 
    f = waitbar(0,'Loading, please wait..','Name','writting to video..');
    open(writerObj);
   
    % iter through all subjects 
    for i = 1:numel(subjects)
        subID = subjects(i);
        sub_dir = get_subject_dir(subID);
        sub_dir_cam = fullfile(sub_dir, cam);

        if sum([dir(sub_dir_cam).bytes]) == 0
           fprintf("folder %s for subject %d is empty.. skipping subject\n", cam, subID)
           continue
        end
        
        %% Load cevent variable 
        % get only within cevent times 
        var = get_variable_by_trial_cat(subID, cevent_variable);

        if isempty(var)
            disp("Error has_variable is true but get_variable_by_trail_cat returned empty")
            continue
        end
        
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
        
        % convert array to table
        instances_df = array2table(target_frames);
        instances_df.Properties.VariableNames = ["frame","onset","offset","cat"];
        instances_df.dur = instances_df.offset - instances_df.onset;

        %% load eye var if valid 
        if include_gaze
            eye = get_variable_by_trial_cat(subID, cont_eye);
            frame_eye = [time2frame_num(eye(:,1),subID), eye];
    
            eye_df = array2table(frame_eye);
            eye_df.Properties.VariableNames = ["frame","cstream","x","y"];
        end
        
        % Load subject transcription
        try
            transcription = load_speech_transcription(subID);
        catch
            transcription = {};
        end
        % preallocate transcription array 
        k = 1;

        for j = 1:height(instances_df)
            % update process bar
            waitbar(i/numel(subjects), f, sprintf(' %d/%d subject %d: frame %d/%d',i,numel(subjects),subID,j,height(instances_df)))
            % if this instaces is too long or too short skip it
            inst_dur = instances_df{j,"dur"};

            if inst_dur < args.cevent_dur_min || inst_dur > args.cevent_dur_max
                continue
            end

            curr_onset = instances_df{j, "onset"};
            curr_offset = instances_df{j, "offset"};
            
            %% Find overlalping utterances 
            % get utterances within t_frames_concat{j}
            cumulative_utterance = {};
            if ~isempty(transcription)
                while true & k <= height(transcription) 

                    b1 = transcription{k, "onset"};
                    b2 = transcription{k, "offset"};

                    if cevents_have_overlap(curr_onset,curr_offset,b1,b2)
                        utterance = transcription{k, "utterance"}{1};
                        cumulative_utterance{end+1} = utterance;
                    end

                    % this utterance will not be selected in t+1
                    if curr_offset >= b2 
                       k = k + 1;
                    end
                    
                    % there can be no more utterances
                    if curr_offset <= b2
                        break
                    end
                end
            end

            % define subject frame path constants 
            frame_number = instances_df{j,"frame"};
            frame_name = sprintf('img_%d.jpg', frame_number);
            rel_frame_path = fullfile(sub_dir_cam, frame_name);
            
            % get frame constants
            try
                img = imread(rel_frame_path);
            catch ME
                disp(ME.message)
                
                continue
            end

            % check if crop is indicated or not 
            [frame_height, frame_width, ~] = size(img);
     
            % get and round gaze xy 
            if include_gaze
                % try to find an extact timing match between cstream &
                % cevent
                coordinates = eye_df(eye_df.frame == frame_number,:);

                if height(coordinates) > 0
                    % if not then look for cstream values within the 8 frame
                    % boundary and average 
                    if isnan(coordinates.x) || isnan(coordinates.y)
                        coor_candidates = eye_df(eye_df.frame >= frame_number - 4 & eye_df.frame <= frame_number + 4,:);
                        coordinates = mean(coor_candidates,"omitmissing");
    
                        if isnan(coordinates.x) || isnan(coordinates.y)
                            continue
                        end
                    end
                    % need to be integers 
                    centerX = round(coordinates.x);
                    centerY = round(coordinates.y);
    
                    % add red dot to indicate gaze 
                    if no_crop
                        relative_radius = round(frame_height * 0.02);
                    else
                        relative_radius = round(crop_width * 0.02);
                    end
    
                    img = insertShape(img, 'FilledCircle', [centerX, centerY, relative_radius], 'Color', [203,203,203], 'Opacity', 1);
                    img = insertShape(img, 'FilledCircle', [centerX, centerY, round(relative_radius*.7)], 'Color', 'red', 'Opacity', 0.7);
                end

            else
                centerX = round(frame_width/2);
                centerY = round(frame_height/2);
            end
                
            % crop if indicated
            % NOTE: if gaze is not used then it crops around the middle
            % of the frame
            if ~no_crop
            
                if frame_width < crop_width || frame_height < crop_height
                    dim_string = sprintf('  sub:%d img:%dx%d crop:%dx%d\n',subID, frame_height, frame_width, crop_height, crop_width);
                    error_string = ['crop size is greater than img size:' newline dim_string 'skipping subject'];
                    disp(error_string)
                    break
                end

                % find the top and bottom corner of the target crop
                top_x = round(centerX - (crop_width/2));
                top_y = round(centerY - (crop_height/2));
    
                low_x = round(centerX + (crop_width/2));
                low_y = round(centerY + (crop_height/2));
                
                %% If target crop is out of bounds 
    
                % if the x location of the crop is right-out of bounds
                if (frame_width - low_x) < 0
                    top_x = top_x - abs(frame_width - low_x);
                    %low_x = low_x - abs(fWidth - low_x);
                end
                
                % if the x location of the crop is left-out of bounds 
                if top_x < 0
                    top_x = top_x + abs(top_x) + 1;
                    %low_x = low_x + abs(top_x);
                end
            
                % if the y location of the crop is bottom-out of bounds 
                if (frame_height - low_y) < 0
                    top_y = top_y - abs(frame_height - low_y);
                    %low_y = low_y - abs(fHeight - low_y);
                end
            
                % if the y location of the crop is top-out of bounds 
                if top_y < 0
                    top_y = top_y + abs(top_y) + 1;
                    %low_y = low_y + abs(top_y);
                end
    
                % This deals with the dim requirements of the H.264 code, must
                % be even 
                if mod(crop_height, 2)
                   img = padarray(img, [1 0], 'replicate', 'post');
                end
       
                if mod(crop_width, 2)
                   img = padarray(img, [0 1], 'replicate', 'post');
                end
            
                % define valid rect and crop frame based on it's dim and coor
                % -1 because imcrop adds a 1 for some reason
                rect = [top_x top_y, crop_width-1, crop_height-1];     
                img = imcrop(img, rect);

                [frame_height, frame_width, ~] = size(img);
            end

            % Insert the subject id and cat name to the crop (top)
            target_label = instances_df{j,"cat"};

            if isKey(args.cat_dict, target_label)
                obj_label = args.cat_dict(target_label);
            else
                obj_label = "other";
            end
           
            % insert cat_label, subID, onset, and offset at top of frame
            target_string = sprintf('%s, %d, %.2f, %.2f', obj_label, subID, curr_onset, curr_offset);
            relative_font = round(frame_width * 0.05);
            RGB = insertText(img,[0 0],target_string, FontSize=relative_font, ...
                BoxOpacity=0.4,TextColor="white", AnchorPoint="LeftTop",BoxColor="black");
            
            % find length of insertText (need to write to empty image
            % and isolate) suggested by the one and only chatgpt
            [rF_height, rF_width] = get_text_dimensions('a', relative_font * 0.8); 
            px_to_ch = floor(frame_width / rF_width);
            
            
            %% Insert utterances into frame
            % step one is to make sure every utterance fits within the crop
            % if it doesn't then break it and add it as an new utterance
            cumulative_utter_cut = {};
            
            for v = 1:numel(cumulative_utterance)
                target_utterance = cumulative_utterance{v};
                % estimate how long the string sequence is in pixels 
                % and separate
                groups  = ceil((rF_width * numel(target_utterance)) / frame_width);
                idx_i = 1;
                idx_j = px_to_ch;
                group_utterance = {};
                
                % Here we are breaking utterances that are too big to be
                % displayed 
                if groups > 1
                    for w = 1:groups
                        if w == groups
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
                if cumulative_height + (3 * rF_height) >= frame_height * 0.25
                        break
                end
                % image writting operation
                RGB = insertText(RGB, [0, frame_height - cumulative_height], cumulative_utter_cut{v}, FontSize=floor(relative_font * 0.7), ...
                    BoxOpacity=0.4,TextColor="white", AnchorPoint="LeftBottom", BoxColor="black"); 
                cumulative_height = cumulative_height + (3 * rF_height);
            end
            try
                writeVideo(writerObj, RGB);
            catch ME
                disp(ME.message)
                fprintf("%d, %s\n",subID, frame_name)
                break
            end
        end
    end 
    % close object 
    lastwarn('')
    close(writerObj);

    [~, warnId] = lastwarn;

    if ~strcmp(warnId, 'MATLAB:audiovideo:VideoWriter:noFramesWritten')
        fprintf("Movie saved under %s.mp4\n",  output_filename)
    end
    
    F = findall(0,'type','figure','tag','TMWWaitbar');
    delete(F);


end

% helper function for create_summary_movie
% approximates the size of a ch in pixels 
function [text_height, text_width] = get_text_dimensions(text, font_size)

    x = zeros(1000, 1000, 3);
    y = insertText(x, [0,0], text,'FontSize', ceil(font_size), 'BoxColor', 'white', ...
                     'TextColor', 'white', 'BoxOpacity', 0);
   
    grayY = rgb2gray(y);
    box_mask = grayY > 0;
    stats = regionprops(box_mask, 'BoundingBox');
    text_width = stats(1).BoundingBox(3);
    text_height = stats(1).BoundingBox(4);
end

% reads a transcription with trail timing 
function transcription = load_speech_transcription(subID)
    subject_dir = get_subject_dir(subID);

    speech_dir = fullfile(subject_dir, 'speech_transcription_p');
    sub_info = get_subject_info(subID);
    speech_entry = dir(fullfile(speech_dir, sprintf('speech_%d.txt',sub_info(4))));
    speech_path = fullfile(speech_dir, speech_entry.name);
    
    transcription = readtable(speech_path);
    transcription.Properties.VariableNames = ["onset","offset","utterance"];
    
    % from extract_speech_in_situ
    frame_rate = 30;
    defaultSpeechTime = 30;

    extract_range_file = fullfile(get_subject_dir(subID),'supporting_files','extract_range.txt');
    range_file = fopen(extract_range_file,'r');
 
    if range_file ~= -1
        extract_range_onset = fscanf(range_file, '[%f]');
        fclose(range_file); % Close the file after reading
    else
        error('Failed to open extract_range.txt');
    end

    trials = get_trial_times(subID);
    trial_length = sum(trials(:,2) - trials(:,1));
    
    
    trial_lag = defaultSpeechTime - round(extract_range_onset/frame_rate,3);
    transcription{:,"onset"} = transcription{:,"onset"} + trial_lag; 
    transcription{:,"offset"} = transcription{:,"offset"} + trial_lag;

end

% finds if two timeseries overlap
function overlap = cevents_have_overlap(a1,a2,b1,b2)
    lower = b1 < a2 & b2 > a1;
    upper = b1< a2 & b2 > a2;
    middle = b1 >= a1 & b2 <= a2 & b2 > a1;

    overlap = lower | upper | middle;
end