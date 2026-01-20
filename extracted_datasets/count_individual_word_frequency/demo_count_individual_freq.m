% PURPOSE
%   Extract and analyze speech that occurs while the child is attending to an
%   object (cevent_eye_roi_child), across multiple experiments. The demo builds
%   category–word frequency matrices and then filters them down to relevant
%   object-naming words.
%
% AUTHOR:  Jingwen Pang
% DATE:    2025-11-05
% REVISED: Connor Pickett 2025-11-13
%
%
% PIPELINE OVERVIEW
%   Step 1) Extract speech during child attention
%      - Uses 'extract_speech_in_situ()' with 'cevent_eye_roi_child' to collect
%        utterances that happen while the child is looking at a category.
%
%   Step 2) Group utterances
%      - Uses 'group_speech_in_situ()' to create three CSVs:
%          * subject.csv
%          * category.csv
%          * subject-category.csv    <-- used by the pipeline
%        Descriptions:
%          - subject.csv: all utterances produced by each subject across the
%            experiment (ignores category).
%          - category.csv: all utterances that occurred while the child looked at
%            a given category (ignores who spoke).
%          - subject-category.csv: all utterances spoken per category per subject in the entire experiment.
%          -  columns include subID, expID, category, trial_time, utterance, and "instance#".
%              > "instance#": how many times the category (object) looked
%              at and had an utterance.
%
%   Step 3) Count category - word frequency
%      - Uses 'count_cat2word_freq()' on the subject-category CSV to build
%        frequency matrices (experiment-wide and subject-level).
%        Axes:
%          X-axis = spoken words
%          Y-axis = category labels
%        Meaning:
%          Counts how often each word appeared while the child was looking at a
%          given category (optionally weighted by instance counts).
%
%   Step 4) Filter by object words
%      - Uses 'get_object_label()' to get the experiment's object labels and
%        'get_object_words()' to get the accepted word list for those objects.
%      - Uses 'filter_cat2word_freq()' to keep only relevant object words and to
%        add zeros for expected labels that did not appear.
%        Axes (filtered matrix):
%          X-axis = spoken object labels (plus accepted alternates)
%          Y-axis = category labels
%        Meaning:
%          Shows how often valid object names (and alternates) were spoken while
%          the child was looking at the corresponding category.
%
% OUTPUT EXAMPLE (per experiment)
%   M:\extracted_datasets\count_individual_word_frequency\speech_in_child_attention\
%     Step 1  |- exp12_speech_in_child_attention.csv
%     Step 2  |- exp12_speech_in_child_attention_subject.csv          (not used in pipeline)
%             |- exp12_speech_in_child_attention_category.csv         (not used in pipeline)
%             |- exp12_speech_in_child_attention_subject-category.csv
%     Step 3  |- exp12_speech_in_child_attention_cat-word.xlsx
%     Step 4  `- exp12_speech_in_child_attention_cat-word_filtered.xlsx
%
function demo_count_individual_freq(expIDs)
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
        
        
        % Step 3: Count Category - Word Frequency from Subject-Category File
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