function demo_get_cevent_gap_dist(option)
    % Summary
    % This function outputs a file (of type specified by user in the
    % output_file argument (.csv recommended)) containing a list of subjects
    % and the distribution of their speech utterance gaps
    % Arguments 
    % sub_expID
    %       -- supply an array of subject IDs or an experiment ID
    % var_name
    %       -- The variable of interest to determine distribution of gaps between
    % output_filename
    %       -- string filename for output file
    % args
    %       -- struct with two optional fields: bins_matrix and keywords
    %       -- args.bins_matrix: a matrix of time ranges
    %       -- args.rois: a list of rois
    switch option
        case 1
            % array of subIDs
            sub_expID = [1501, 1503, 1504, 1512, 1513];
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            output_filename = 'demo_gen_gap_ex1.csv';
            args = [];
            get_cevent_gap_dist(sub_expID, var_name, output_filename, args)
        case 2
            % expID
            sub_expID = 15;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            output_filename = 'demo_gen_gap_ex2.csv';
            args = [];
            get_cevent_gap_dist(sub_expID, var_name, output_filename, args)
        case 3
            % bins matrix specified with cutoff
            sub_expID = 15;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            output_filename = 'demo_gen_gap_ex3.csv';
            args.bins_matrix = [0.5 1; 1 1.5; 3 3.5; 5.5 6];
            get_cevent_gap_dist(sub_expID, var_name, output_filename, args)
        case 4
            % bins matrix specified with no cutoff
            sub_expID = 15;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            output_filename ='demo_gen_gap_ex4.csv';
            args.bins_matrix = [0.5 1; 1 1.5; 3 3.5; 5.5 realmax('double')];
            get_cevent_gap_dist(sub_expID, var_name, output_filename, args)
        case 5
            % utterance gap for keywords
            sub_expID = 15;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            output_filename = 'demo_gen_gap_ex5.csv';
           args.rois = {1, 3, 5, 7};
            get_cevent_gap_dist(sub_expID, var_name, output_filename, args)
        case 6
            % keywords and bins matrix
            sub_expID = 15;
            var_name = 'cevent_eye_joint-attend_parent-lead_both';
            output_filename = 'demo_gen_gap_ex6.csv';
            args.bins_matrix = [0.5 1; 1 1.5; 3 3.5; 5.5 6];
            args.rois = {1, 3, 5, 7};
            get_cevent_gap_dist(sub_expID, var_name, output_filename, args)
    end
end

