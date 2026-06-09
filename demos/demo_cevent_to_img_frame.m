function demo_cevent_to_img_frame(option)
%% Summary
% This function takes a .csv file and extracts representative image frames
% for each event (a row in the .csv file). It can extract either one frame per event or multiple frames
% per event based on a specified frames-per-second value. There is also an
% option to extract attended-object frames based on child ROI. 

% In order to run this function, run a function that generates an excel
% file with this format: 
% subID      expID      onset      offset      category       trial      instanceID
%  --          --         --         --          --             --          --
% 
% (i.e. extract_multi_measures, extract_speech_in_situ, extract_cevent_info)
% and pass it as input to the function. 

% This function will output the original csv file with the frame IDs and frame paths appended
% It will also create a directory in 'output_location' where the images and output file will
% be placed. 

%% Required Arguments
% cevent_file
%        -- generated from extract.... with specific format (see above)
%
% output_location
%        -- directory where the output folder should be created
%        -- The function creates a folder based on the input filename, 
%            attended-object setting, and fps setting.
%        -- The output .mat file and copied images are saved inside this folder
% 

%% Optional Arguments
% args.attended_obj
%     -- logical, if true, the function extracts both full-frame images and 
%         attended-object cropped images based on child cstream ROI file (derived/cstream_eye_roi_child.mat).
%     -- The attended object is selected as the most common ROI object during the event window.
%     -- If true, the closest valid attended-object frame to the respective full-frame
%         is chosen, given that it is in the event window. This can result in duplicates
%         or NaN values.
%     -- Default: false, and will only include full-frames
% 
% args.fps
%     -- numeric value or string.
%     -- If "single", the function selects one representative frame per event
%     -- If numeric, the function selects approximately 'fps' frames per second within
%         each event window. 
%     -- Default: "single"
% 

%% Output
% The output directory contains:
% 
% rawOut .mat file
%     -- A .mat file containing rawOut
%     -- rawOut preserves the original input file formatting, including rows 
%         before the detected header.
%     -- New frame ID and frame path columns are appended starting at the detected
%         header row.
% 
% full_images folder
%     -- Contains copied full-frame images selected for each event.
%     -- Image Names: 'subID'_cam07_'instanceID'_'frameID'
% 
% attended_images folder
%     -- Created only when args.attended_obj is true.
%     -- Contains copied attended-object crop images selected for each event.
%     -- Image Names: 'subID'_cam07_'instanceID'_'frameID'

%% Appended Columns
% 
% selected_full_frame_id_X
%     -- frame ID of the selected full-frame image for frame sample X.
% selected_full_frame_path_X
%     -- full file path to the selected full-frame image for frame sample X.
% selected_att_frame_id_X
%     -- frameID of the selected attended-object image for frame sample X.
%     -- Only added when args.attended_obj is true;
% selected_att_frame_path_X
%     -- full file path to the selected attended-object image for frame sample X.
%     -- Only added when args.attended_obj s true.
% 
% The value of 'X' increases as more frames per event are selected. This value 
% indicates the order of frames in the event, which are equally spaced as much as possible. 
% Additionally, the number of columns appended changes depending on the value of args.fps

switch option
    %% Basic Usage -- Use plain cevent to get representative frames
    case 1
        % Get events from cevent_inhand_child for two subjects (1501 and 1502)
        filename = 'Z:\James\ImageVectorMeasures\DEMO_Cases\case01.csv';
        extract_cevent_info('cevent_inhand_child', [1501 1502], filename);
        
        % Get a single full frame representing the events
        args = [];
        output_location = 'Z:\James\ImageVectorMeasures\DEMO_Cases\';
        cevent_to_img_frame(filename, output_location, args);

    case 2        
        % Use extract_multi_measures to get ROI during naming instances, 
        % then pull a single full frame
        args = [];
        var_list = {'cevent_eye_roi_child'};
        subexpIDs = [15];
        filename = 'Z:\James\ImageVectorMeasures\DEMO_Cases\case02.csv';
        args.cevent_name = 'cevent_speech_naming_local-id';
        args.cevent_values = 1:10;
        extract_multi_measures(var_list, subexpIDs, filename, args);
        
        % Images and matlab file created in output_location
        output_location = 'Z:\James\ImageVectorMeasures\DEMO_Cases\';
        args = [];
        cevent_to_img_frame(filename, output_location, args);
    case 3
        % Similar to case 2: get ROI during naming instances, but also get
        % a single frame for the attended object. Due to the fact that we don't 
        % have an attended_obj frame for every full frame, the attended 
        % frames can be duplicates (or NaN).
        % Often, the attended-obj frame will have a different frame ID than
        % the respective full frame. Also, depending on the base cevent
        % variable, different instances may share the same attended frame. 
       
        args = [];
        var_list = {'cevent_eye_roi_child'};
        subexpIDs = [15];
        filename = 'Z:\James\ImageVectorMeasures\DEMO_Cases\case03.csv';
        args.cevent_name = 'cevent_speech_naming_local-id';
        args.cevent_values = 1:10;
        extract_multi_measures(var_list, subexpIDs, filename, args);

        % Images and matlab file created in output_location
        args = [];
        output_location = 'Z:\James\ImageVectorMeasures\DEMO_Cases\';
        args.attended_obj = true;
        cevent_to_img_frame(filename, output_location, args);
    
    case 4
        % Use extract_speech_in_situ to get events of ROI when the parent
        % used predefined "args.target_words." Get both the full and
        % attended object frame. 
        args = [];
        subexpIDs = [15];
        filename = 'Z:\James\ImageVectorMeasures\DEMO_Cases\case04.csv';
        cevent_var = 'cevent_eye_roi_child';
        num_obj = get_num_obj(subexpIDs);
        category_list = 1:num_obj; % all objects
        args.target_words = {'red', 'green', 'blue', 'white', 'black', 'pink', 'purple', 'orange', 'yellow', 'gray'};
        args.extract_mode = 'individual';
        extract_speech_in_situ(subexpIDs, cevent_var, category_list, filename, args);

        args = [];
        output_location = 'Z:\James\ImageVectorMeasures\DEMO_Cases\';
        args.attended_obj = true;
        cevent_to_img_frame(filename, output_location, args);

    case 5
        % Get more than 1 frame per second during naming instances 
        % (works for both full and attended frames)
        args = [];
        var_list = {'cevent_eye_roi_child'};
        subexpIDs = [15];
        filename = 'Z:\James\ImageVectorMeasures\DEMO_Cases\case05.csv';
        args.cevent_name = 'cevent_speech_naming_local-id';
        args.cevent_values = 1:10;
        extract_multi_measures(var_list, subexpIDs, filename, args);
        
        % The length of the event is floored when calculating how many frames 
        % to select (e.g. a 1.9 second event is treated as 1 second).
        % The number of selected frames is: 
        %   max(1, floor(event_duration) * fps)
        % The selected frames are spaced evenly within the event window
        args = [];
        args.fps = 2;
        % args.attended_object = true; % Will work with attended frames
        output_location = 'Z:\James\ImageVectorMeasures\DEMO_Cases\';
        
        cevent_to_img_frame(filename, output_location, args);
    
    %% Post Processing after using cevent_to_img_frame
    % First, run any of the cases 1 - 5 to generate the .mat file
    % containing the image IDs and frame paths

    % Then, call post-processing function to get a vector
    % representation of the image. 

    % This will create a new .mat file in the same directory as the
    % input_file, with the representation name appended to it. Each
    % image in the input file will get an associated vector (full and
    % attended frames). 
    case 6
        % Get a COLOR vector for the images pulled from cevent_to_img_frame
        % In this example, we will use the output from case 4 to get a
        % color profile of the full frames and object frames associated
        % with a spoken "zcolor word". 
        args = [];
        subexpIDs = [351];
        filename = 'Z:\James\ImageVectorMeasures\DEMO_Cases\case06_color.csv';
        cevent_var = 'cevent_eye_roi_child';
        num_obj = get_num_obj(subexpIDs);
        category_list = 1:num_obj; % all objects
        args.target_words = {'red', 'green', 'blue', 'white', 'black', 'pink', 'purple', 'orange', 'yellow', 'gray'};
        args.extract_mode = 'individual';
        extract_speech_in_situ(subexpIDs, cevent_var, category_list, filename, args);

        args = [];
        output_location = 'Z:\James\ImageVectorMeasures\DEMO_Cases\';
        args.attended_obj = true;
        cevent_to_img_frame(filename, output_location, args);
        
        % This function takes two arguments: 
        %   -- input_file 
        %       -- this is the .mat file created as in one of the above
        %           examples
        %   -- which frames you want the color vector for
        %         -- options are {"attended", "full", "all}
        
        input_file = "Z:\James\ImageVectorMeasures\DEMO_Cases\case06_color_att_fps_single\case06_color_att_fps_single.mat";
        image_color_profile(input_file, "attended"); 
    case 7
        % Use extract_cevent_info to get naming instances from exp 15
        filename = 'Z:\James\ImageVectorMeasures\DEMO_Cases\case07.csv';
        extract_cevent_info('cevent_speech_naming_local-id', [1501 1502 1503 1504], filename);

        args = [];
        output_location = 'Z:\James\ImageVectorMeasures\DEMO_Cases\';
        cevent_to_img_frame(filename, output_location, args);
                
        % Only input is the .mat file
        input_file = "Z:\James\ImageVectorMeasures\DEMO_Cases\case07_fps_single\case07_fps_single.mat";
        image_GBVS_profile(input_file);

    case 8
        % Get a CONCEPT vector -- REWORD

    
    case 100
        filename = 'Z:\James\ImageVectorMeasures\DEMO_Cases\case07.csv';
        extract_cevent_info('cevent_speech_naming_local-id', [35101 35102], filename);
        args=[];
        output_location = 'Z:\James\ImageVectorMeasures\DEMO_Cases\';
        cevent_to_img_frame(filename, output_location, args);
        input_file = "Z:\James\ImageVectorMeasures\DEMO_Cases\case100_fps_single\case100_fps_single.mat";
        image_GBVS_profile(input_file);
end


 