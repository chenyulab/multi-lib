%%
% Author: Ruchi Shah
% Modifier: Elton Martinez
% Last modified: 6/2/2025

% This takes the outfile of get_gap_instance (see demo_get_gap_instance)
% and reformats the csv into a matlab struct of the form
%   N = number_of_subjects x 1 cell array
%    ┃
%    ┣━ N{i, 1}{1, 1} = subID of the ith subject
%    ┗━ N{i, 1}{1, 2} = obj_num x obj_num cell array = A
%     ┃   
%     ┗━ A{n, m} = gaps between instances whose category transition is
%        n-->m. There are four "columns" : inst1_onset, inst2_offset,
%        inst2_onset,inst2_offset = num_of_instances x 4 = B. 
%        For example A{5, 10} are the gaps between instances where inst1 
%        has category 5 and inst2 has category 10. 
%
%% Input Parameters
%       gap_instance_filename: string/ch, path to the output of get_gap_instance
%       num_cats: integer, the number of categories
%       output_filename: string/ch, name of the output file. if empty ('')
%       then output will not be saved as .mat file
%
%% Output
%       struct 
%       .mat file (optional)
%%

function subject_gap_data = build_gap_matrix(gap_instance_filename, num_cats, output_filename)
    
    % read csv
    T = readtable(gap_instance_filename);
    
    % get constants
    subjects = unique(T.subID);
    num_subjects = length(subjects);
    
    subject_gap_data = cell(num_subjects, 1);
    
    % iterate through subjects 
    for s = 1:num_subjects
        % subset data
        subID = subjects(s);
        sub_data = T(T.subID == subID, :);
        % initialize gap matrix
        gap_mat = cell(num_cats, num_cats);
        % iterate through each instance and sort them into the proper
        % matrix instance 
        for i = 1:height(sub_data)
            r1 = sub_data.inst1_cat(i);
            r2 = sub_data.inst2_cat(i);

            if isnumeric(r1) && isnumeric(r2) && r1 > 0 && r2 > 0 && r1 <= num_cats && r2 <= num_cats
                row = [sub_data.inst1_onset(i), sub_data.inst1_offset(i), sub_data.inst2_onset(i), sub_data.inst2_offset(i)];
                
                if isempty(gap_mat{r1, r2})
                    gap_mat{r1, r2} = row;
                else
                    gap_mat{r1, r2}(end+1, :) = row;
                end
            end
        end
        % append to global cell array
        subject_gap_data{s} = {subID, gap_mat};
    end

    % save if valid
    if ~isempty(output_filename)
        save(output_filename, "subject_gap_data")
    end
end
