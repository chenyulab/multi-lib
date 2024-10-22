% Original Author: Ruchi Shah
% Modifier: Jingwen Pang
% Last modified: 10/22/2024
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
    exp_ids = [351 353 361 362 363];
    exp_type = 'HOME2';
    survey_dir = 'HOME_survey.xlsx';
    tsv_headers = {'subject','kid_id','gender','age_at_experiment','birth_year','birth_month'};
    tsv_type = {'int32', 'int32', 'string', 'double','int32','int32'};

    data = readtable(fullfile(get_multidir_root(),survey_dir));

    for e = 1:length(exp_ids)
        exp_id = exp_ids(e);
        sub_ids = cIDs(exp_id);

        tsv_table = table('Size', [0 length(tsv_headers)],'VariableTypes', tsv_type, 'VariableNames', tsv_headers);

        for s = 1:length(sub_ids)
            sub_id = sub_ids(s);

            % map with the data in Home survey corresponding row
            sub_info = get_subject_info(sub_id);
            kid_id = sub_info(:,4);
            date = sub_info(:,3);

            % Convert the number to string and extract year, month, and day
            yearStr = num2str(floor(date / 10000));  % First 4 digits for the year
            monthStr = num2str(mod(floor(date / 100), 100));  % Middle 2 digits for the month
            dayStr = num2str(mod(date, 100));  % Last 2 digits for the day
            dateObj = datetime([yearStr '-' monthStr '-' dayStr], 'InputFormat', 'yyyy-MM-dd');
            date = datestr(dateObj, 'dd-mmm-yyyy');

            idx = data{:,2} == kid_id & data{:,1} == date & strcmp(data{:,3}, exp_type);
            if any(idx)
                filtered_survey = data(idx, :);
                % disp(filtered_survey);
                % gender column
                gender = filtered_survey{:, 7};
                gender = gender{1};
                gender = gender(1);
            
                % Calculate age at experiment, extract birth year and month
                date_of_experiment = filtered_survey{:, 1};
                dob = filtered_survey{:, 4}; 
    
                age_in_months = calmonths(between(dob, date_of_experiment, 'months'));
                remaining_days = caldays(between(dob + calmonths(age_in_months), date_of_experiment));
                fractional_month = remaining_days / 31;
                age_at_experiment = age_in_months + fractional_month;
                age_at_experiment = round(age_at_experiment, 1);
    
                birth_year = year(dob);
                birth_month = month(dob);
        
                % Create results table
                subject_row = {sub_id, kid_id, gender, age_at_experiment, ...
                                     birth_year, birth_month};
    
                tsv_table(end+1, :) = subject_row;
            else
                fprintf('survey not found for %d\n', sub_id)
            end
        end
            
        % Directory setup and output (.tsv)
        exp_dir = get_experiment_dir(exp_id);
        directory = fullfile(exp_dir, 'survey_data');
        if ~exist(directory, 'dir')
           mkdir(directory);
        end
        filePath = fullfile(directory, 'basic.tsv');
        writetable(tsv_table,filePath, 'filetype','text', 'delimiter','\t');
    end
end
