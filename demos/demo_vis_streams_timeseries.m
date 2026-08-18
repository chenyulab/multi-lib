function demo_vis_streams_timeseries(option)
%% Summary
% Demo of vis_streams_timeseries
% plots a variable's time series across multiple subjects and concatenates trials to remove inactive time

switch option

    case 1
        % Standard use: one variable, default colormapping 
        subexpIDs = 12;
        var_name = 'cevent_eye_roi_child';
        output_dir = 'Z:\ashley\vis_streams_timeseries\demo_results';
        args = struct();
        args.save_name = 'demo_01_default';

        vis_streams_timeseries(subexpIDs, var_name, output_dir, args)

    case 2
        % Two variables, default colormapping 
        subexpIDs = 12;
        var_name = {'cevent_eye_roi_child', 'cevent_eye_roi_parent'};
        output_dir = 'Z:\ashley\vis_streams_timeseries\demo_results';
        args = struct();
        args.save_name = 'demo_02_two_variables';

        vis_streams_timeseries(subexpIDs, var_name, output_dir, args)

    case 3
        % One variable, single color 
        subexpIDs = 12;
        var_name = 'cevent_speech_naming_local-id';
        output_dir = 'Z:\ashley\vis_streams_timeseries\demo_results';
        args = struct();
        args.save_name = 'demo_03_single_color';
        args.single_color = [0.2 0.4 0.8];

        vis_streams_timeseries(subexpIDs, var_name, output_dir, args)

    case 4
        % One variable, duration capped at the first 180 seconds
        subexpIDs = 12;
        var_name = 'cevent_eye_roi_parent';
        output_dir = 'Z:\ashley\vis_streams_timeseries\demo_results';
        args = struct();
        args.save_name = 'demo_04_duration_limit';
        args.duration = 180;
        
        vis_streams_timeseries(subexpIDs, var_name, output_dir, args)

    case 5
        % One variable, custom color override  
        % Useful for emphasizing specific categories while leaving the
        % remaining categories unchanged 
        subexpIDs = 12; 
        var_name = 'cevent_eye_roi_child'; 
        output_dir = 'Z:\ashley\vis_streams_timeseries\demo_results';
        args = struct();
        args.save_name = 'demo_05_color_override';
        args.colors = [
            1   0.49    0.26    0.08;   % category 1 
            2   0.75    0.45    0.35;   % category 2 
            3   0.20    0.35    0.05;   % category 3 
            4   1       0.8     0;      % category 4  
            5   0       0       0;      % category 5  
            8   0.96    0.8     0.69;   % category 8
            15  0.63    0.32    0.18;   % category 15
            16  0.8     0.53    0.6;    % category 16
            17  0.60    0.15    0.05;   % category 17  
            22  0.25    0.45    0.45;   % category 22
            ];      
        vis_streams_timeseries(subexpIDs, var_name, output_dir, args)

end 
end 

 