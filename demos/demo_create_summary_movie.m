%%%
% Author: Elton Martinez
% Modifier: Elton Martinez
% Last modified: 5/21/2025
%
% This demo function provides several examples of how to use 
% create_summary_movie to generate summary videos focused on particular 
% categories(object/face) during specified events. 
% 
% Requirements: Computer Vision Toolbox & Image Processing Toolbox
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

function demo_create_summary_movie(option)
        
    switch option
        case 1
            %{ 
            create_summary_movie conditions frames(centered around gaze) from 
            either parent or child view based on a cevent variable. A simple 
            example of this is looking at child's view given cevent_eye_roi_child. 
            Lets check all the toys. If args is not passed the default
            values for the sub-args will be used (check above).
            %}
            
            subexpIDs = [35120];
            cevent_variable = 'cevent_eye_roi_child';
            output_filename = 'results_2/case_1';

            create_summary_movie(subexpIDs, cevent_variable, output_filename)
         
        case 2
            %{
            Let's say we want to see what parent is looking at when child
            is holding any category. We define the agent as parent and
            make the parent's gaze dependent on cevent_inhand_child.
            The reference point is set to onset but in order to give some
            room for reaction lets shift back -0.1. Lets also adjust the
            frame rate to speed up the video. We will also decrease the crop
            window to focus on the attended information. 
            %}
            
            subexpIDs = [35116];
            cevent_variable = 'cevent_inhand_child';
            output_filename = 'results_2/case_2';
            
            args.agent = 'parent';
            args.whence = 'middle';
            args.interval = -0.1;
            
            args.frame_rate = 2;
            args.crop_size = [400 300];
            
            create_summary_movie(subexpIDs, cevent_variable, output_filename, args)

           case 3

            %{
            Utterances that overlap with the target cevent will be displayed
            in the bottom left of the frame. Lets use naming to get consistent examples.
            Here we can check what the child is looking at when the parent
            labels an object and what the parent is saying. Since we only
            have timing information for an entire utterance, a very long
            utterance can overlap with a very small event. One way to avoid
            is to exclude event instances that last less than x seconds.
            %}

            subexpIDs = [35104];
            cevent_variable = 'cevent_speech_naming_local-id';
            output_filename = 'results_2/case_3'; 
            
            args.whence = 'middle';
            args.cevent_dur_min = 0.5;
            % can also add an upper boundary
            args.cevent_dur_max = 2;
            
            args.crop_size = [300 300];
            args.frame_rate = 1/2;
           
            create_summary_movie(subexpIDs, cevent_variable, output_filename, args)

           case 4 
           %{
            The default mapping of category id to category label is based
            on the object dictionary. If the choosen cevent variable has a
            different mapping you can change category dict to display the 
            correct category label. In this example we are using speech
            words which have their unique cat-label mapping. We will only
            look at the verbs scoop and cut. 
           %}

            subexpIDs = 353;
            cevent_variable = 'cevent_speech_verb_word-id_parent';
            output_filename = 'results_2/case_4';  

            args.cat_ids = [15 2];
            args.cat_dict = dictionary(args.cat_ids,["scoop" "cut"]);

            args.whence = 'middle';
            args.frame_rate = 1/2;
           
            create_summary_movie(subexpIDs, cevent_variable, output_filename, args)
    end
end
