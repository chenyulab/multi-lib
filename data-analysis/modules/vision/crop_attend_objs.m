%% 
%  Given a roi event try to find the bounding box of the category of the event. If 
%  found then save that detection as an image to cam07/08_attended-objs-frames_p
%
% Author: Jingwen Pang
% Editor: Elton Martinez
% Last modified: 8/19/2025
%
%
% Input:
%   subexpID:
%       expID or subIDs, please do not run this across experiments might cause 
%       unexpected behavior due to discontinuous matching between
%       categories.
%   agents:
%       a cell array of ch, indicate if you want child, parent, or both
%   args (optional):
%       cevent_values: which categories to include. This is used if you
%       want to just run it on one category or if you want to include face.
%       The default behavior is to include all toy categories. 

% couple of warnings:
% experiment's 12 and 15 bbox_struct have different structures than what is
% the default format. For bbox_struct we expect a struct of 1xframe_num.
% 12 and 15 do not do that and ommit some frames. Therefore you cannot index to them 
% by simply using (i). 
% For exp 12 the field frame_id is a string...
% For exp 15 the post_boxes are in the format [top_left_x top_left_y width
% height].... 


function crop_attend_objs(subexpID, agents, varargin)
    % define default arguments
    if isempty(varargin)
        args = {};
    else
        args = varargin{1};
    end
    
    % constants 
    subexpID = cIDs(subexpID);
    expID = get_experiment_dir(subexpID(1));
    expID = regexp(expID, '\d+', 'match');
    expID = str2double(expID{1});
    
    num_obj = get_num_obj(subexpID(1));
    cevent_values = 1:num_obj;

    valid_args = {"cevent_values","empty_dir"};
    default_args = {cevent_values, false};

    % assign default arguments if not passed
    for i = 1:numel(valid_args)
        if ~isfield(args, valid_args{i})
            args.(valid_args{i}) = default_args{i};
        end
    end
    
    % add face if included 
    if ismember(num_obj + 1, args.cevent_values)
        include_face = true;
    else
        include_face = false;
    end

    input_foldernames = {'cam07_frames_p','cam08_frames_p'};
    % might not be best lol 
    output_foldernames = {'cam07_attended-objs-frames_p','cam08_attended-objs-frames_p'};

    for i = 1:length(agents)
        
        % get constants for child or parent
        agent = agents{i};
        output_foldername = output_foldernames{i};
        input_foldername = input_foldernames{i};

        for j = 1:length(subexpID)
    
            subID = subexpID(j);
            subject_path = get_subject_dir(subID);
    
            % get roi variable
            roi_name = sprintf('cstream_eye_roi_%s', agent);
            roi = get_variable_by_trial_cat(subID,roi_name);
        
            if ~isempty(roi)
                roi(:,1) = time2frame_num(roi(:,1),subID);
                frames = roi(:,1);
            else
                fprintf('%d %s roi is not found\n',subID, agent)
                continue;
            end

            % only include the declared categories 
            roi_mask = ismember(roi(:,2), args.cevent_values);
            roi = roi(roi_mask,:);

            % get the bounding box data 
            filename = sprintf('%d_%s_boxes.mat',subID, agent);
            file_path = fullfile(subject_path,'extra_p',filename);
            
            try 
                box_data = load(file_path).box_data;
                box_data = struct2table(box_data);
                frame_id_col = box_data.frame_id;

                if isa(frame_id_col, 'cell')
                    if isa(frame_id_col{1},'char') | isa(frame_id_col{1},'string')
                        frame_id_col = arrayfun(@(x) str2double(x), frame_id_col);
                        box_data = removevars(box_data, 'frame_id');
                        box_data.frame_id = frame_id_col;
                    end
                end

            catch ME
                disp(ME.message)
                fprintf('%d %s box data is not found\n',subID,agent);
                continue;
            end
            
            % read face is passed as category value
            if include_face
                filename_face = [filename(1:end-4) '_face.mat'];
                filename_face_path = fullfile(subject_path,'extra_p',filename_face);
               
                try 
                     face_box_data = load(filename_face_path).box_data;
                     face_box_data = table2struct(face_box_data);
                catch ME
                    fprintf('%d %s face box data is not found\n',subID,agent);
                    continue;
                end
            end
            
            % Get the full folder path
            folderPath = fullfile(subject_path, output_foldername);
            
            % Check if the folder exists
            if ~isfolder(folderPath)
                mkdir(folderPath);
            elseif args.empty_dir && isfolder(folderPath)
                fprintf("cleaning folder %s\n",folderPath);
                rmdir(folderPath,'s');
                mkdir(folderPath);
            end
            
            % loading bar .. 
            bar = waitbar(0,'1','Name','cropping_images..');
            fprintf("Processing subject %d: %d/%d\n",subID,j,length(subexpID))
            
           
            % create folders 
            for t = 1:numel(args.cevent_values)
                val = args.cevent_values(t);

                cat_folder = sprintf('obj_%d',val);
                %cat_folder = num2str(val);
                
                output_cat_foldername = fullfile(folderPath, cat_folder);
                if ~isfolder(output_cat_foldername)
                    try
                        mkdir(output_cat_foldername);
                    catch ME
                        disp(ME.message);
                    end
                end
            end
      
            missed_detections = 0;
            for f = 1:length(frames)
                frame_num = frames(f);
                % find attended obj
                attend_obj = roi(roi(:,1) == frame_num,2);

                if isempty(attend_obj)
                    continue
                end
 
                % Read the image
                img_name = sprintf('img_%d.jpg', frame_num);
                img_path = fullfile(subject_path,input_foldername,img_name);
                img = imread(img_path);

                % get bounding box data and skip if empty 
                if attend_obj == num_obj + 1
                    bbox = face_box_data{face_box_data{:,"frame_id"} == frame_num,"post_boxes"};
                else
                    bbox = box_data{box_data{:,"frame_id"} == frame_num,"post_boxes"};
                end

                % find if a detection for that frame exists
                % if it does find out if its empty 
                if isempty(bbox)
                    missed_detections = missed_detections + 1;
                    continue
                else
                    bbox = bbox{1};
                    if attend_obj ~= num_obj + 1
                        bbox = bbox(attend_obj,:);
                    end
        
                    if sum(bbox) == 0
                        missed_detections = missed_detections + 1;
                        continue
                    end
                end
              
    
                [img_height, img_width, ~] = size(img);
                crop_width = round(bbox(3)*img_width);
                crop_height = round(bbox(4)*img_height);

                if expID == 15
                     % exp15 is in format topleftx, toplefty, width, height 
                    topLeftX = round(bbox(1) * img_width);
                    topLeftY = round(bbox(2) * img_height);
                else
                    % Center point of the cropping region
                    centerX = round(bbox(1)*img_width);
                    centerY = round(bbox(2)*img_height);
                
                    % Calculate the top-left corner of the cropping rectangle
                    topLeftX = centerX - crop_width/2;
                    topLeftY = centerY - crop_height/2;
                end
            
                % Define the cropping rectangle
                rect = [topLeftX, topLeftY, crop_width, crop_height];

                % Crop the image
                croppedImg = imcrop(img, rect);
            
                % Save the cropped image
                %output_img_name = sprintf('%d_img_%d.jpg',attend_obj,frame_num);
                output_img_name = sprintf('obj_%d_img_%d.jpg',attend_obj,frame_num);
    
                %cat_folder = num2str(attend_obj);
                cat_folder = sprintf('obj_%d',attend_obj);
                output_crop_path = fullfile(folderPath, cat_folder);
                img_path = fullfile(output_crop_path,output_img_name);
                imwrite(croppedImg,img_path);
    
                waitbar(f/length(frames), bar, sprintf('frame %d/%d',f,length(frames)))
            end
            fprintf("Total detections %d/%d\n",length(frames)-missed_detections, length(frames))
            delete(bar);
        end
    end

% remove taskbar(s)
F = findall(0,'type','figure','tag','TMWWaitbar');
delete(F);

end