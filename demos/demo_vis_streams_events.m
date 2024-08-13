%%%
% Author: Jane Yang
% Last Modified: 06/04/2024
% This is the demo function for vis_streams_events() function.
%
% 
% 
%%%

function demo_vis_streams_events(option)
    switch option
        case 1
            subexpID = 351;
            cevent_name = 'cevent_speech_naming_local-id';
            var_list = {'cevent_eye_roi_child','cevent_eye_roi_parent','cevent_inhand_child','cevent_inhand_parent'};
            cevent_values = [1:27]; % display all object instances
            streamlabels = {'naming','ceye','peye','chand','phand'};
            output_file_dir = 'Z:\CORE\scheduled_tasks\multi-lib\demo_results\vis_streams_events\case1';

            args.whence = 'start';
            args.interval = [0 3];

            % This case shows events happened within 3 seconds after each
            % naming instance.
            vis_streams_events(subexpID,cevent_name,var_list,cevent_values,streamlabels,output_file_dir,args);
        case 2
            subexpID = 351;
            cevent_name = 'cevent_speech_naming_local-id';
            var_list = {'cevent_eye_roi_child','cevent_eye_roi_parent','cevent_inhand_child','cevent_inhand_parent'};
            cevent_values = [1:5]; % only display selected instances containing the list of target objects
            streamlabels = {'naming','ceye','peye','chand','phand'};
            output_file_dir = 'Z:\CORE\scheduled_tasks\multi-lib\demo_results\vis_streams_events\case2';

            args.whence = 'start';
            args.interval = [0 3];
            
            % This case shows events happened within 3 seconds after each
            % naming instance and only for a subset of objects.
            vis_streams_events(subexpID,cevent_name,var_list,cevent_values,streamlabels,output_file_dir,args);
        case 3
            subexpID = 351;
            cevent_name = 'cevent_speech_naming_local-id';
            var_list = {'cevent_eye_roi_child','cevent_eye_roi_parent','cevent_inhand_child','cevent_inhand_parent'};
            cevent_values = [1:5]; % only display selected instances containing the list of target objects
            streamlabels = {'naming','ceye','peye','chand','phand'};
            output_file_dir = 'Z:\CORE\scheduled_tasks\multi-lib\demo_results\vis_streams_events\case3';

            args.showSingleColor = 1;
            args.whence = 'start';
            args.interval = [0 3];
            
            % This case shows events happened within 3 seconds after each
            % naming instance.
            % Only instances that are about the same object as the naming
            % instance are displayed.
            vis_streams_events(subexpID,cevent_name,var_list,cevent_values,streamlabels,output_file_dir,args);
       case 4
            subexpID = 351;
            cevent_name = 'cevent_speech_naming_local-id';
            var_list = {'cevent_eye_roi_child','cevent_eye_roi_parent','cevent_inhand_child','cevent_inhand_parent'};
            cevent_values = [1:5]; % only display selected instances containing the list of target objects
            streamlabels = {'naming','ceye','peye','chand','phand'};
            output_file_dir = 'Z:\CORE\scheduled_tasks\multi-lib\demo_results\vis_streams_events\case4';

            args.displayObjList = [1:5];
            args.whence = 'start';
            args.interval = [0 3];
            
            % This case shows child's gaze, parent's gaze, child's inhand, and parent's inhand that
            % happened within 3 seconds after each parent's naming instance
            % only instances on a subset of objects are displayed
            vis_streams_events(subexpID,cevent_name,var_list,cevent_values,streamlabels,output_file_dir,args);
       case 5
            subexpID = 351;
            cevent_name = 'cevent_eye_roi_child';
            var_list = {'cevent_speech_naming_local-id','cevent_eye_roi_parent','cevent_inhand_child','cevent_inhand_parent'};
            cevent_values = [8:10]; % only display selected instances containing the list of target objects
            streamlabels = {'ceye','naming','peye','chand','phand'};
            output_file_dir = 'Z:\CORE\scheduled_tasks\multi-lib\demo_results\vis_streams_events\case5';

            args.displayObjList = [9];
            args.whence = 'start';
            args.interval = [0 3];
            
            % This case shows parent's speech, parent's gaze, child's inhand, and parent's inhand that
            % happened within 3 seconds after each child's gaze instance
            % only instances on a subset of objects are displayed
            vis_streams_events(subexpID,cevent_name,var_list,cevent_values,streamlabels,output_file_dir,args);
    case 6
            subexpID = 351;
            cevent_name = 'cevent_trials';
            var_list = {'cevent_speech_naming_local-id','cevent_eye_roi_child','cevent_eye_roi_parent','cevent_inhand_child','cevent_inhand_parent'};
            cevent_values = [1:27]; % only display selected instances containing the list of target objects
            streamlabels = {'trial','naming','ceye','peye','chand','phand'};
            output_file_dir = 'Z:\CORE\scheduled_tasks\multi-lib\demo_results\vis_streams_events\case6';

            args.displayObjList = [9];
            
            % This case shows parent's speech, parent's gaze, child's inhand, and parent's inhand that
            % happened within 3 seconds after each child's gaze instance
            % only instances on a subset of objects are displayed
           vis_streams_events(subexpID,cevent_name,var_list,cevent_values,streamlabels,output_file_dir,args);
    end
end