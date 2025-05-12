% Summary
    % USE: taking an event variable that contains multiple instances, we
    % count gaps based on duration of gaps and output three csv files 
    % each containing a list of subjects and the distribution of gaps 
    % of time window of variables.
    % 1) distribution of gaps between all categories
    % 2) distribution of gaps per category
    % 3) summation of gaps per category to category occurrences
    %
    % REQUIRED Arguments 
    % subexpid
    %       -- supply an array of subject IDs from the same experiment or ONE experiment ID
    % num_cats
    %       -- number of categories for this experiment (include face if
    %       that is a valid category
    % var_name
    %       -- The variable of interest to determine distribution of gaps between
    % output_filename
    %       -- string filename for output file (.csv)
    %       -- e.g. 'parent_led_JA_gap.csv'
    %       -- can also include file path
    %
    % OPTIONAL Arguments:
    % args.time_bins
    %       -- bins of time ranges
    %       -- e.g. [0.5 1; 1 1.5; 3 3.5; 5.5 6] - times in seconds;
    %       gap between 0.5 to 1 second etc. (0, 1] (1, 1.5]... This means
    %       lower bound excluded, upper bound included.
    %
    % args.cats
    %       -- a list of categories
    %       -- e.g. {1, 3, 5, 7} - only will use these specified categories
    %       
    % args.gap_def 
    %       -- definition of gap, between offset of current and onset of 
    %       next or onset of current and onset of next
    %       -- ['offset', 'onset'] - default - gap between offset of first 
    %       and onset of second instance
    %       -- ['onset', 'onset'] - gap between onset of first and onset of
    %       second instance
    %
    % args.by_trial
    %       -- 0 - default (no trial separation)
    %       -- 1 - output with trial separation
    %       
    %
function demo_get_gap_dist(option)
    % all the demo files are saved into, users can define their own path:
    output_dir = 'Z:\demo_output_files\get_gap_dist';
    switch option
        case 1 % basic usage
            % supplying a list of subject ID's for an experiment
            subexpid = [1501, 1503, 1504, 1512, 1513];
            num_cats = 11;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            output_filename = fullfile(output_dir,'demo_gen_gap_ex1.csv');
            args = [];
            get_gap_dist(subexpid, num_cats, var_name, output_filename, args)

        case 2 % basic usage with trials separated out
            % supplying an experiment ID
            subexpid = 15;
            num_cats = 11;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            output_filename = fullfile(output_dir,'demo_gen_gap_ex2.csv');
            args.by_trial = 1; % set to 1 to show gaps per trial
            get_gap_dist(subexpid, num_cats, var_name, output_filename, args)

        case 3 % same as case 2 but with defined bins
            % bins matrix specified with cutoff
            subexpid = 15;
            num_cats = 11;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            output_filename = fullfile(output_dir,'demo_gen_gap_ex3.csv');
            % counts gaps between 0.5 to 1, 1 to 1.5, 3 to 3.5, and 5.5 to 6 seconds 
            args.time_bins = [0.5 1; 1 1.5; 3 3.5; 5.5 6]; 
            args.by_trial = 1;
            get_gap_dist(subexpid, num_cats, var_name, output_filename, args)

        case 4 % same as case 2 but with defined bins
            % bins matrix specified with no cutoff
            subexpid = 15;
            num_cats = 11;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            output_filename =fullfile(output_dir,'demo_gen_gap_ex4.csv');
            args.time_bins = [0.5 1; 1 1.5; 3 3.5; 5.5 Inf];
            args.by_trial = 1;
            get_gap_dist(subexpid, num_cats, var_name, output_filename, args)
         
        case 5 % same as case 2 but with specified categories
            subexpid = 15;
            num_cats = 11;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            output_filename = fullfile(output_dir,'demo_gen_gap_ex5.csv');
            args.cats = {1, 3, 5, 7}; % only considers these cats
            args.by_trial = 1;
            get_gap_dist(subexpid, num_cats, var_name, output_filename, args)
  
        case 6 % same as case 2 but with specified bins and specified categories
            subexpid = 15;
            num_cats = 11;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            output_filename = fullfile(output_dir,'demo_gen_gap_ex6.csv');
            args.time_bins = [0.5 1; 1 1.5; 3 3.5; 5.5 6];
            args.cats = {1, 3, 5, 7};
            args.by_trial = 1;
            get_gap_dist(subexpid, num_cats, var_name, output_filename, args)
        
        case 7 % same as case 6 but with gap definition as onset to onset
               % instead of offset to onset
            subexpid = 15;
            num_cats = 11;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            output_filename = fullfile(output_dir,'demo_gen_gap_ex7.csv');
            args.time_bins = [0.5 1; 1 1.5; 3 3.5; 5.5 6];
            args.cats = {1, 3, 5, 7};
            args.gap_def = ['onset', 'onset'];
            args.by_trial = 1;
            get_gap_dist(subexpid, num_cats, var_name, output_filename, args)
   
    end
end
