% Author: Ruchi Shah
% Last modified: 03/27/3034
% Summary: 
% This function uses the inputted experiment's dictionary to generate csv's
% for each ROI using query_csv_speech()
% 
function exp_dict_query_csv_speech(exp_ID)
    output_dir = strcat('M:\extracted_datasets\event_clips\data\CLIP_data\experiment_', string(exp_ID), '\');
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    exp_dir = get_experiment_dir(exp_ID);
    dict = strcat(exp_dir, '\exp_', string(exp_ID), '_dictionary.xlsx');
    exp_dict = readtable(dict);
    keywords = exp_dict{:,4};

    for i = 1:length(keywords)
        splitStrings = strtrim(split(keywords{i}, ','));

        word_list = splitStrings;
        output_filename = strcat(splitStrings{1}, '_', string(i),'.csv');
        query_csv_speech(exp_ID,word_list, output_dir, output_filename);
        fclose('all');
    end

end

