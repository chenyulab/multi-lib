% This demo extracts and analyzes speech data within child-attention windows
% across multiple experiments. It generates category–word frequency matrices
% and filters them to relevant naming words.
%
% Author: Jingwen Pang
% Date: 2025-11-05
%
% Pipeline overview:
%   Extract Speech in Child Attention
%       - Uses 'extract_speech_in_situ()' with cevent 'cevent_eye_roi_child'
%         to collect utterances spoken while the child attends.
%
%   ️Group Utterances
%       - Runs 'group_speech_in_situ()' to produce subject, category,
%         and subject–category grouped CSVs.
%
%   Count Category–Word Frequency
%       - Uses 'count_cat2word_freq()' to build frequency matrices from the
%         subject–category file (optionally weighted by instance counts).
%
%   Filter by Object Words
%       - Retrieves object labels and word lists via 'get_object_label()' and
%         'get_object_words()'.
%       - Filters the matrices with 'filter_cat2word_freq()' to retain only
%         relevant words (adds zero placeholders for missing ones).
%
% Output example:
%   M:\extracted_datasets\count_individual_word_frequency\speech_in_child_attention\
%       ├─ exp12_speech_in_child_attention.csv
%       ├─ exp12_speech_in_child_attention_subject-category.csv
%       ├─ exp12_speech_in_child_attention_cat-word.xlsx
%       └─ exp12_speech_in_child_attention_cat-word_filtered.xlsx
%
function demo_count_individual_freq()
    output_dir = 'M:\extracted_datasets\count_individual_word_frequency\speech_in_child_attention';
    if ~exist("expIDs","var")
        expIDs =[12, 15, 58, 65, 66, 67, 68, 77, 78, 79, 351, 353, 361, 362, 363]; 
    end
    
    for e = 1:length(expIDs)
        expID = expIDs(e);
        % Step 1: Extract Speech Utterances in Child Attention Window
        num_obj = get_num_obj(expID);             
        category_list = 1:num_obj;% All object 
        cevent_var = 'cevent_eye_roi_child'; 
        file_name = 'speech_in_child_attention'; 
        output_filename = fullfile(output_dir, sprintf('exp%d_%s.csv', expID,file_name));
        extract_speech_in_situ(expID, cevent_var, category_list, output_filename);
        
        
        % Step 2: Group Utterance Data by Subject & Category
        group_speech_in_situ(output_filename);  % This creates multiple grouped files (subject, category, subject-category)
        
        
        % Step 3: Count Category–Word Frequency from Subject-Category File
        input_csv = fullfile(output_dir, sprintf('exp%d_%s_subject-category.csv', expID,file_name));
        sub_col = 1;         
        cat_col = 3;         
        utt_col = 6;         
        args.instance_col = 5;  % instance # column number, default: 0 - no instance # column, just count rows
        output_excel = fullfile(output_dir, sprintf('exp%d_%s_cat-word.xlsx', expID,file_name));
        count_cat2word_freq(input_csv, sub_col, cat_col, utt_col, output_excel, args);
        
        
        % Step 4: Filter Word Matrix based on Keyword List
        num_obj = get_num_obj(expID);
        cat_list = [1:num_obj];
        labels = get_object_label(expID,cat_list)';
        
        % Mark bad labels (uppercase tokens)
        bad = contains(string(labels), "UNKNOWN") | ...
        contains(string(labels), "ERROR")   | ...
        contains(string(labels), "INVALID_LABEL");
        
        labels   = labels(~bad);
        cat_list = cat_list(~bad);
        
        word_list = get_object_words(expID,cat_list);
        
        input_file = output_excel;
        % % word_list = get_object_label(expID, category_list); % all object names
        output_file = fullfile(output_dir, sprintf('exp%d_%s_cat-word_filtered.xlsx', expID, file_name));
        filter_cat2word_freq(input_file, output_file, word_list)
    end

end