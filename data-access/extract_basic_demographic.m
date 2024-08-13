% Author: Ruchi Shah
% Last modified: 03/20/2024
% Summary
    % This function creates a .tsv containing demographic information
    % derived from the subject_table and the inputted demographic_survey
    % excel sheet for each experiment subjects are a part of.
    %
    % Output:
    % a directory called 'survey_data' within each experiment the subjects are
    % a part of. 'survey_data' contains a file called 'basic.tsv' containing the
    % following columns:
    %       SubjectID
    %       KidID
    %       Gender
    %       AgeAtExperiment
    %       BirthYear
    %       BirthMonth
   
function extract_basic_demographic()
    data = readtable(fullfile(get_multidir_root(),'HOME_survey.xlsx'));
    subTable = read_subject_table(); 
    kid_ids = data{:, 2};
    % find the subjects in the subject table that demographic_survey
    % kid_ids correspond to
    idx = ismember(subTable(:, 4), kid_ids); 
    filtered_subjTable = subTable(idx, :);
    % get the experiments subjects are a part of
    experiments = unique(filtered_subjTable(:, 2));

    for i = 1:length(experiments)
        % currently only for experiment 351 and 353
        if experiments(i) ~= 351 && experiments(i) ~= 353
            continue;
        end
            exp_idx = filtered_subjTable(:, 2) == experiments(i);
            exp_filtered_table = filtered_subjTable(exp_idx, :);
            sub_id_col = exp_filtered_table(:, 1); 
            kid_id_col = exp_filtered_table(:, 4); 
            [match, loc] = ismember(kid_id_col, data{:, 2});
            filtered_survey = data(loc(match), :);
    
            % gender column
            gender_col = filtered_survey{:, 7};
            gender_col = cellfun(@(x) x(1), gender_col, 'UniformOutput', false);
        
            % Calculate age at experiment, extract birth year and month
            date_of_experiment = filtered_survey{:, 1};
            dob = filtered_survey{:, 4}; 
            age_at_experiment = between(dob, date_of_experiment, 'Months');
            age_at_experiment = split(age_at_experiment, {'months'});
            birth_year = year(dob);
            birth_month = month(dob);
    
            % Create results table
            resultsTable = table(sub_id_col(match), kid_id_col(match), gender_col, age_at_experiment, ...
                                 birth_year, birth_month, ...
                                 'VariableNames', {'subject','kid_id','gender','age_at_experiment','birth_year','birth_month'});
            
            % Directory setup and output (.tsv)
            exp_dir = get_experiment_dir(experiments(i));
            directory = fullfile(exp_dir, 'survey_data');
            if ~exist(directory, 'dir')
               mkdir(directory);
            end
            filePath = fullfile(directory, 'basic.tsv');
            writetable(resultsTable,filePath, 'filetype','text', 'delimiter','\t');
    end
end
