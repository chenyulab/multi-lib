%%%
% Author: Jingwen Pang
% last edited date: 09/06/2024
% This function reads home survey data and update object and naming score table 
% Input paramter:
%   - subexpIDs: expID or subject id (only works for 351 now)
% Output data:
%   - updated version of exp351_scoretable_obj.xlsx
%   - updated version of exp351_scoretable_name.xlsx
% example call:
%   read_home_survey_toys(35144)
%%%
function read_home_survey_toys(subexpIDs)
    
    survey_filepath = "M:\\HOME_survey.xlsx";
    sheet_name = 'Vocab - Toys';
    obj_score_filepath = "M:\experiment_351\exp351_scoretable_obj.xlsx";
    word_score_filepath = "M:\experiment_351\exp351_scoretable_name.xlsx";
    range = 'A:AB';
    mapping_list = [16,16,15,15,10,10,11,11,7,7,5,5,17,17,9,9,2,2,22,22,3,3,13,13,4,4,21,21,8,8,20,20,19,19,27,27,26,26,6,6,23,23,18,18,12,12,24,24,25,25,14,14,1,1
    ];
    
    n_obj = get_num_obj(subexpIDs);
    subIDs = cIDs(subexpIDs);
    
    survey_data_raw = readtable(survey_filepath, 'Sheet', sheet_name);
    survey_data = survey_data_raw(~any(ismissing(survey_data_raw(:, 1:2)), 2), :);
    obj_score_data = readtable(obj_score_filepath,'Range', range);
    word_score_data = readtable(word_score_filepath,'Range', range);
    
    date_time = survey_data.Var1;
    date_str = datestr(date_time, 'yyyymmdd');
    for i = 1:length(date_str)
        date(i,1) = str2double (date_str(i,:));
    end
    
    kid_id = survey_data.Var2;
    all_data = table2array(survey_data(:,3:end));
    
    
    new_obj_score_data = [];
    new_word_score_data = [];
    for s = 1:length(subIDs)
        subID = subIDs(s);
        subInfo = get_subject_info(subID);
        subDate = subInfo(3);
        subKidID = subInfo(4);
        row_num = find(date == subDate & kid_id == subKidID);
        if ~isempty(row_num)
            for o = 1:n_obj
                obj_idx = 2*o-1;
                word_idx = 2 * o;
                obj_id = mapping_list(obj_idx);
                obj_value = all_data(row_num,obj_idx);
                obj_data(obj_id) = obj_value;
                word_id = mapping_list(word_idx);
                word_value = all_data(row_num,word_idx);
                word_data(word_id) = word_value;
            end
            obj_row_data = [subID,obj_data];
            word_row_data = [subID,word_data];
            % set a check point, new data will append to
            % the end of the table, if the subject exist in the table,
            % it should replace that row
            check_obj_row = find(obj_score_data{:,1} == subID, 1);
            if isempty(check_obj_row)
                new_obj_score_data = [new_obj_score_data;obj_row_data];
            else
                obj_score_data(check_obj_row,:) = array2table(obj_row_data);
            end
            check_word_row = find(word_score_data{:,1} == subID, 1);
            if isempty(check_word_row)
                new_word_score_data = [new_word_score_data;word_row_data];
            else
                word_score_data(check_word_row,:) = array2table(word_row_data);
            end
        else
            
            empty_data = nan(1, n_obj);
            empty_row = [subID,empty_data];

            check_obj_row = find(obj_score_data{:,1} == subID, 1);
            if isempty(check_obj_row)
                new_obj_score_data = [new_obj_score_data;empty_row];
            end
            check_word_row = find(word_score_data{:,1} == subID, 1);
            if isempty(check_word_row)
            new_word_score_data = [new_word_score_data;empty_row];
            end
        end
    
    end
    
    if ~isempty(new_obj_score_data)
        updated_obj_data = [obj_score_data;array2table(new_obj_score_data,"VariableNames",obj_score_data.Properties.VariableNames)];
        writetable(updated_obj_data, obj_score_filepath, 'Range', 'A1');
    else
        writetable(obj_score_data, obj_score_filepath, 'Range', 'A1');
    end

    if ~isempty(new_word_score_data)
        updated_word_data = [word_score_data;array2table(new_word_score_data,"VariableNames",word_score_data.Properties.VariableNames)];
        writetable(updated_word_data, word_score_filepath, 'Range', 'A1');
    else
        writetable(word_score_data, obj_score_filepath, 'Range', 'A1');
    end

end
