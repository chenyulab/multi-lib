 % Author: Ruchi Shah
 % Based on get_subject_dir
function dir_name = get_experiment_dir(sub_expID)
    
    % gets the directory holding the experiment's data, given its subject or experiment id.
    %   This directory name is returned without a trailing file separator (like
    %   / or \).
    
    multidir = get_multidir_root();
    
    % find the experiment info for the given exp_id
    table = read_subject_table();
    exp_info = func_filter(@(subj) subj(2) == sub_expID | subj(1) == sub_expID, table);
    
    if length(exp_info(1,2)) < 1
        error('No such experiment (%d) exists in the subject_table.txt file!', sub_expID)
    end
    
    % format the subject info into a filename.
    % use 'fullfile' instead of 'sprintf' so that the function can run well under windows system 
    dir_name = fullfile(multidir, ['experiment_' num2str(exp_info(1,2))]);

end

