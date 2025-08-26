%% Demo function for build_gap_matrix 
% This takes the outfile of get_gap_instance (see demo_get_gap_instance)
% and reformats the csv into a matlab struct of the form
%   N = number_of_subjects x 1 cell array
%     N{i, 1}{1, 1} = subID of the ith subject
%     N{i, 1}{1, 2} = obj_num x obj_num cell array = A
%        
%       A{n, m} = gaps between instances whose category goes from n-->m,
%         there are four "columns" : inst1_onset, inst2_offset, inst2_onset, 
%         inst2_offset = num_of_instances x 4 = B. For example A{5, 10} are
%         the gaps between instances where inst1 has category is 5 and inst2
%         has category 10. 
%
%% Input Parameters
%       all_file_path: string/ch, path to the output of get_pap_instance
%       num_cats: the number of categories
%
function demo_build_gap_matrix(option)
    switch option
        
        case 1
            all_file_path = "Z:\demo_output_files\get_gap_instance\demo_gen_gap_inst1_all.csv";
            num_cats = 11;
            output_filename = '';

            build_gap_matrix(all_file_path, num_cats, output_filename)
    end
end