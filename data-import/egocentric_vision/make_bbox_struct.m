%%%
% Author: Jane Yang
% last editor: Jingwen Pang
% Last modified: 9/17/2024
%
% This function read the files containing bounding box prediction label 
% from a target filepath and parse them to store in the Matlab struct with
% three columns. The struct will include the following information: path to
% the image frame, frame index, and a Nx4 bounding box array including
% bbox coordinates.
%%%
function make_bbox_struct(subID,agent,is_face)

    if strcmp(agent,'child')
        cam = 7;
    elseif strcmp(agent,'parent')
        cam = 8;
    end

    num_obj = get_num_obj(subID);

    if is_face
        folder_name = sprintf('bbox_annotations_%s_face',agent);
    else
        folder_name = sprintf('bbox_annotations_%s',agent);
    end
    % bbox prediction folder
    fileDir = fullfile(get_subject_dir(subID),'supporting_files',folder_name);
    % target destination folder
    destFolder = fullfile(get_subject_dir(subID),'extra_p');
    % set output bbox Matlab filename
    output_filename = sprintf('%d_%s_boxes.mat',subID,agent);

    if is_face
        output_filename = sprintf('%d_%s_boxes_face.mat',subID,agent);
        num_obj = 1;
        % num_of_cols = 5;
    end

    % list all text files in the current directory
    fileList = dir(fullfile(fileDir,'*.txt'));
    filenameList = sort({fileList.name}');

    % check if any txt file exists
    if isempty(filenameList) % no prediction .txt files exist
        fprintf("No bounding box prediction files exist for subject %d\n",subID);
    else % txt files exist
        % initialize bbox struct
        box_data(length(filenameList)) = struct();

        % iterate through each text file
        for f = 1:length(filenameList)
        % for f = 1
            currFile = filenameList{f};
            % TODO: parse text filename to find target frame index
            parsedFilenames = strsplit(currFile,'_');
            frameID = str2double(regexp(parsedFilenames{2}, '\d+', 'match'));
            % if isempty(frameID) % TODO: hard-coded for now, change later
            %     frameID = str2double(regexp(parsedFilenames{end-1}, '\d+', 'match'))+1;
            % end
    
            % load bounding box data from text file
            data = readtable(fullfile(fileDir,currFile));
            data = table2array(data);
    
            % get source frame path
            framePath = fullfile(get_subject_dir(subID),sprintf('cam%d_frames_p',cam),sprintf('img_%d.jpg',frameID));
    
            % check if any object was detected
            if size(data,1) > 0
                % adjust YOLO objectIDs
                data(:,1) = data(:,1)+1;

                % remove the confidence value
                if is_face
                    data(:,end) = [];
                    modified_boxData = data(2:end);
                else
    
                % fill all the non-detected objects as zeros
                notDetectedObjs = setdiff([1:num_obj]',data(:,1));
                notDetectedMtx = horzcat(notDetectedObjs,zeros(size(notDetectedObjs,1),4));
                modified_boxData = vertcat(data(:,1:end-1),notDetectedMtx); % concat not detected objs with detected ones
                modified_boxData = sortrows(modified_boxData,1); % sort bounding box by object IDs
                modified_boxData = modified_boxData(:,2:end);
                end
            else  % no object detected
                modified_boxData = zeros(num_obj,4);
                fprintf('No object was detected in frame %d.\n',frameID);
            end
    
            % append an entry to the box_data struct
            box_data(frameID).frame_name = framePath;
            box_data(frameID).frame_id = frameID;
            box_data(frameID).post_boxes = modified_boxData;
        end
        

        % TODO: save box_data to a .mat file
        save(fullfile(destFolder,output_filename),'box_data');
    
        % deallocate box_data struct for reuse
        clear box_data;
    end
end