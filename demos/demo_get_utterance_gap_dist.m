function demo_get_utterance_gap_dist(option)
    % Summary
    % This function outputs a file (of type specified by user in the
    % output_file argument (.csv recommended)) containing a list of subjects
    % and the distribution of their speech utterance gaps
    % Arguments 
    % sub_expID
    %       -- supply an array of subject IDs or an experiment ID
    % output_filename
    %       -- string filename for output file
    % args
    %       -- struct with two optional fields: bins_matrix and keywords
    %       -- args.bins_matrix: a matrix of time ranges
    %       -- args.keywords: a list of keywords
    switch option
        case 1
            % array of subIDs
            sub_expID = [1501, 1503, 1504, 1512, 1513];
            output_filename = 'demo_ex1.csv';
            args = [];
            get_utterance_gap_dist(sub_expID, output_filename, args)
        case 2
            % expID
            sub_expID = 15;
            output_filename = 'demo_ex2.csv';
            args = [];
            get_utterance_gap_dist(sub_expID, output_filename, args)
        case 3
            % bins matrix specified with cutoff
            sub_expID = 15;
            args.bins_matrix = [0.5 1; 1 1.5; 3 3.5; 5.5 6];
            output_filename = 'demo_ex3.csv';
            get_utterance_gap_dist(sub_expID, output_filename, args)
        case 4
            % bins matrix specified with no cutoff
            sub_expID = 15;
            args.bins_matrix = [0.5 1; 1 1.5; 3 3.5; 5.5 realmax('double')];
            output_filename = 'demo_ex4.csv';
            get_utterance_gap_dist(sub_expID, output_filename, args)
        case 5
            % utterance gap for keywords
            sub_expID = 15;
            args.keywords = {'who', 'what', 'when', 'where', 'why', 'how'};
            output_filename = 'demo_ex5.csv';
            get_utterance_gap_dist(sub_expID, output_filename, args)
        case 6
            % keywords and bins matrix
            sub_expID = 15;
            args.bins_matrix = [0.5 1; 1 1.5; 3 3.5; 5.5 6];
            args.keywords = {'who', 'what', 'when', 'where', 'why', 'how'};
            output_filename = 'demo_ex6.csv';
            get_utterance_gap_dist(sub_expID, output_filename, args)
    end
end

