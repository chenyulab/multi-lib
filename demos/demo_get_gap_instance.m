% Summary
    % USE: taking an event variable that contains multiple instances, we
    % find the gaps between instances and output two files csv each 
    % containing a list of subjects and the onset and offset of each gap.
    % 1) CAT: gaps between instances of the same category
    % 2) ALL: gaps between all instances
    %
    % REQUIRED Arguments 
    % subexpid
    %       -- supply an array of subject IDs or an experiment ID
    % num_cats
    %       -- number of categories for this experiment (include face if
    %       that is a valid category
    % var_name
    %       -- The variable of interest to determine distribution of gaps between
    % output_filename
    %       -- string filename for output file (.csv)
    %       -- e.g. 'parent_led_JA_gap_inst.csv'
    %       -- can also include file path
    %
    % OPTIONAL Arguments:
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
    function demo_get_gap_instance(option)
    % all the demo files are saved into, users can define their own path:
    output_dir = 'Z:\demo_output_files\get_gap_instance';
    switch option
        case 1 % basic usage
            % supplying a list of subject ID's for an experiment
            subexpid = [1501, 1503, 1504, 1512, 1513];
            num_cats = 11;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            output_filename = fullfile(output_dir,'demo_gen_gap_inst1.csv');
            args = [];
            get_gap_instance(subexpid, num_cats, var_name, output_filename, args)

        case 2 % basic usage
            % supplying an experiment ID
            subexpid = 15;
            num_cats = 11;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            output_filename = fullfile(output_dir,'demo_gen_gap_inst2.csv');
            args = [];
            get_gap_instance(subexpid, num_cats, var_name, output_filename, args)

        case 3 % same as case 2 but with specified categories
            subexpid = 15;
            num_cats = 11;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            args.cats = {1, 3, 5, 7}; % only considers these cats
            output_filename = fullfile(output_dir,'demo_gen_gap_inst3.csv');
            get_gap_instance(subexpid, num_cats, var_name, output_filename, args)

       
        case 4 % same as case 3 but with gap definition as onset to onset
               % instead of offset to onset
            subexpid = 15;
            num_cats = 11;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            args.cats = {1, 3, 5, 7};
            args.gap_def = ['onset', 'onset'];
            output_filename = fullfile(output_dir,'demo_gen_gap_inst4.csv');
            get_gap_instance(subexpid, num_cats, var_name, output_filename, args)
    end
end
