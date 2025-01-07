function demo_make_small_vis_streams(option)
% Summary: Generates visualizations of specified cevent variables for short clips from query
% keywords files 

%{

Required arguments 

input file:
    - the query keywords csv file 
vars: 
        - string/character array 
        -array of variables to go into the plot

steamlabels: 
    - string/character array 
    - same length as vars, shorthand names for each variable to display on
    plot
    - each stream label correspond to the variable in the same position in
    vars array 

directory:
    directory where visualizations output to 

%}

%{
Optional arguments 


panels:
    -0 for no, 1 for yes 
    - specifies if you want each keyword insatnce in its own file
    - specifyung 1 generates files with 5x5 panels of plots

cutoff: 
       - integer
       - cutoff after onset of naming instance starts 
        - ex. if cutoff = 5, will only display the variables from onset to
        onset + 5 seconds

%}



    switch option
    
        case 1
            % create individual files for each row in query keywords
    
            vars = {'cevent_eye_roi_child', 'cevent_eye_roi_parent', 'cevent_eye_joint-attend_both', 'cevent_inhand_parent'};
            streamlabels = {'ceye', 'peye', 'ja', 'parent inhand'};
            directory = 'Z:\bryanna\small_vis_streams\demo_results\no_panels';
            input_file = "..\demo_results\speech_analysis\example8.csv";
                       
            make_small_vis_streams(input_file, vars, streamlabels, directory)
    
        
        case 2
            % create files of 5x5 plots of small vis streams - 25 plots
            % where each plot represents a row in the query keywords file
    
            vars = {'cevent_eye_roi_child', 'cevent_eye_roi_parent', 'cevent_eye_joint-attend_both', 'cevent_inhand_parent'};
            streamlabels = {'ceye', 'peye', 'ja', 'parent inhand'};
            directory = 'Z:\bryanna\small_vis_streams\demo_results\panels';
            input_file = "..\demo_results\speech_analysis\example8.csv";
            panels = 1;
                       
            make_small_vis_streams(input_file, vars, streamlabels, directory, panels)

       case 3
            % uses a cutoff of 2 seconds so any keyword instance longer
            % than that gets cutoff 
    
            vars = {'cevent_eye_roi_child', 'cevent_eye_roi_parent', 'cevent_eye_joint-attend_both', 'cevent_inhand_parent'};
            streamlabels = {'ceye', 'peye', 'ja', 'parent inhand'};
            directory = 'Z:\bryanna\small_vis_streams\demo_results\cutoff';
            input_file = "..\demo_results\speech_analysis\example8.csv";
            panels = 1; 
            cutoff = 2;
                       
            make_small_vis_streams(input_file, vars, streamlabels, directory, panels, cutoff)
       case 4
            % uses a cutoff of 2 seconds so any keyword instance longer
            % than that gets cutoff

            % if you want to specify a cutoff but do not want panels
    
            vars = {'cevent_eye_roi_child', 'cevent_eye_roi_parent', 'cevent_eye_joint-attend_both', 'cevent_inhand_parent'};
            streamlabels = {'ceye', 'peye', 'ja', 'parent inhand'};
            directory = 'Z:\bryanna\small_vis_streams\demo_results\cutoff';
            input_file = "..\demo_results\speech_analysis\example8.csv";
            panels = 0; 
            cutoff = 2;
                       
            make_small_vis_streams(input_file, vars, streamlabels, directory, panels, cutoff)
    
    
    end
end
