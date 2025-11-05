% This demo function illustrates a complete workflow for extracting and analyzing
% word co-occurrence patterns from speech data.
%
% Author: Jingwen Pang
% Date: 2025-11-05
%
% Pipeline overview:
%   Speech Extraction
%       - Uses 'extract_speech_in_situ()' to collect utterance-level speech data
%         for each experiment ID.
%
%   Word–Word Co-occurrence Counting
%       - Uses 'count_word2word_freq()' to compute pairwise word co-occurrence matrices
%         within utterances.
%       - Generates aggregate CSVs at multiple levels:
%           • per-subject (subID.csv)
%           • per-category (cat-XX.csv)
%           • overall (expXX_all.csv)
%       - The parameter 'args.skipSubVersions = 1' disables saving the
%         utterance-level (sub-version) files for faster batch processing.
%
%   Word Matrix Filtering
%       - Uses 'filter_word2word_freq()' to subset the large co-occurrence matrix
%         according to a predefined vocabulary (e.g., MCDI word list).
%       - Outputs a reduced version of the co-occurrence matrix that includes
%         only relevant words and summary columns (e.g., word frequency and pair frequency).
%
% Output structure (example):
%   M:\extracted_datasets\count_word_cooccurance\
%       ├─ exp12_all_speech.csv
%       ├─ exp12_all_speech_word-cooccur\
%       │     ├─ exp12_all.csv
%       │     ├─ cat-1.csv
%       │     ├─ 1201.csv
%       │     └─ ...
%       └─ exp12_all_filtered_obj-obj.csv
%
%
function demo_count_word_cooccurance(expIDs)
    % This function is showing how to extract word co-occurance 
    output_dir = 'M:\extracted_datasets\count_word_cooccurance';
    if ~exist("expIDs","var")
        expIDs =[12, 15, 58, 65, 66, 67, 68, 77, 78, 79, 351, 353, 361, 362, 363]; 
    end
    
    for e = 1:length(expIDs)
        expID = expIDs(e);
        % Step 1: Extract Basic Speech Utterances
        num_obj = get_num_obj(expID);             
        category_list = [];
        cevent_var = ''; 
        file_name = 'all_speech'; 
        output_filename = fullfile(output_dir, sprintf('exp%d_%s.csv', expID,file_name));
        extract_speech_in_situ(expID, cevent_var, category_list, output_filename);
        
        % Step 2: Count Word–Word Cooccurance
        input_csv = output_filename;
        utt_col = 10;
        sub_col = 1;
        cat_col = 5;
        output_folder = fullfile(output_dir,sprintf('exp%d_%s_word-cooccur', expID,file_name));
        args.skipSubVersions = 1; % skip sub versions (in utterance level)
        count_word2word_freq(input_csv, utt_col, sub_col, cat_col, output_folder)
        
        % Step 3: Filter Word Matrix based on Word List
        input_folder = output_folder;
        
        mcdi_path = "M:\MCDI_wordlist.csv";
        mcdi_table = readtable(mcdi_path);
        word_list = mcdi_table.item_definition;
        word_list = word_list';
        
        col_to_keep = {'word_freq','word_pair_freq'}; % column headers to keep and will be appended at the end
        placeholder = 0; % 0 - set column placeholder value as 0, 1 - set as NaN
        
        % just subset the main file
        input_file = fullfile(input_folder,sprintf('exp%d_all.csv',expID));
        output_file = fullfile(output_dir,sprintf('exp%d_all_filtered_obj-obj.csv',expID));
        filter_word2word_freq(input_file, output_file, word_list);
    
    end
end