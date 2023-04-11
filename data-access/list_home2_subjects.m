% add age interval to input arg
% 351:355 --> new expID
% 1: toyplay, 2: book reading, 3: meal time, 4: sorting, 5: ball drop
function sub_list = list_home2_subjects(actID,visitID,age_range)
    if ~exist('age_range','var')
        age_range = [];
    end

    % parse activity->expID mapping
    mapping = readtable(fullfile(get_multidir_root(),'home2_activity_mapping.csv')); % TODO: put it in a file
    expID = table2array(mapping(table2array(mapping(:,1))==actID,2));

    % read subject table
    home2_subject_table = read_home2_subject_table();

    sub_list = home2_subject_table(home2_subject_table.Exp_num == expID & home2_subject_table.Visit == visitID & home2_subject_table.Age >= age_range(1) & home2_subject_table.Age <= age_range(2),1);
    sub_list = table2array(sub_list);
end