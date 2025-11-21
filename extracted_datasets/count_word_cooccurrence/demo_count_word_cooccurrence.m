% AUTHOR:  Jingwen Pang
% DATE:    2025-11-05
% REVISED: Connor Pickett 2025-11-14
% PURPOSE
%   Extract and analyze word–word co-occurrence patterns from speech data across
%   multiple experiments. This demo builds co-occurrence matrices showing how
%   often pairs of words appear together within the same utterance, and then
%   filters those matrices down to a target vocabulary list (e.g., MCDI words).
%
%   Co-occurrence definition (for this function):
%   - We treat each utterance as a single "bucket" of words.
%   - Two words are said to co-occur if they both appear in the same
%     utterance (i.e., in the same row of the input CSV).
%   - The co-occurrence count for a word pair is the number of utterances
%     in which both words appear together.
%
%   Simple example:
%       Utterance 1: "get the ball"
%       Utterance 2: "kick the ball"
%       Utterance 3: "get the red ball"
%       Utterance 4: "look, a dog"
%
%     -> ("get", "ball") co-occur in 2 utterances
%     -> ("ball", "red") co-occur in 1 utterance
%     -> ("ball", "dog") co-occur in 0 utterances
%
%   Matrix convention:
%   - By definition, the ROW label co-occurs with the COLUMN label N times.
%
%   Example with repeated words in one utterance:
%       Utterance: "dog ... dog ... cat!"
%
%       In this case:
%         - "dog" co-occurs with "cat" 2 times
%         - "cat" co-occurs with "dog" 1 time
%
%       So the resulting co-occurrence table is:
%                 dog   cat
%           dog    1     2
%           cat    1     0
%
%       Note: because of this counting rule, the co-occurrence matrix
%       is not necessarily symmetric.
%
% PIPELINE OVERVIEW
%   Step 1) Extract all speech utterances
%      - Uses 'extract_speech_in_situ()' to gather every utterance from the
%        experiment (not restricted by attention or category).
%      - Input file:
%          * No CSV input file; reads from the lab's data for a given expID.
%      - Output file:
%          * exp##_all_speech.csv
%            (one row per utterance with subject, category, timing, text, etc.)
%
%   Step 2) Count word - word co-occurrence
%      - Uses 'count_word2word_freq()' on the all-speech CSV to build matrices
%        showing how often pairs of words appear together within a single
%        utterance, based on the definition above.
%      - Input file:
%          * exp##_all_speech.csv    (from Step 1)
%      - Output files (in exp##_all_speech_word-cooccur\):
%          exp##_all.csv – The overall word co-occurrence matrix for the entire experiment.
%          cat-XX.csv – Category-level summary, created by aggregating row-level word co-occurrence data into categories.
%          [subID].csv – Subject-level summary, created by aggregating row-level word co-occurrence data for each subject.
%          Row-level files – Detailed row-level co-occurrence files. These are generated only when args.skipSubVersions = 0.
%
%   Step 3) Filter by vocabulary list
%      - Loads a predefined word list (e.g., MCDI via 'MCDI_wordlist.csv').
%      - Uses 'filter_word2word_freq()' to keep only rows/columns that match
%        the vocabulary items.
%      - Input files:
%          * exp##_all.csv  (from Step 2)
%          * word list  (e.g. mcdi)
%      - Output file:
%          * exp##_all_filtered.csv
%        This filtered matrix contains only the words from assigned word list and summary
%        columns such as word frequency and word-pair frequency.
%
%
function demo_count_word_cooccurrence(option,expIDs)
    switch option
        case 1
            % This function is showing how to extract word co-occurrence 
            output_dir = 'M:\extracted_datasets\count_word_cooccurrence\mcdi_word_cooccurrence';
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
                
                % Step 2: Count Word - Word Cooccurrence
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
                output_file = fullfile(output_dir,sprintf('exp%d_all_filtered_mcdi.csv',expID));
                filter_word2word_freq(input_file, output_file, word_list);
            end
        case 2
            output_dir = 'M:\extracted_datasets\count_word_cooccurrence\obj_word_cooccurrence';
            if ~exist("expIDs","var")
                expIDs =351; 
            end
            for e = 1:length(expIDs)
                expID = expIDs(e);
                % Step 1: Extract Basic Speech Utterances
                num_obj = get_num_obj(expID);             
                category_list = [];
                cevent_var = ''; 
                file_name = 'all_speech_3s_before_after'; 
                args.whence = 'startend'; 
                args.interval = [-3 3]; % time window: 3 second before and 3 second after
                output_filename = fullfile(output_dir, sprintf('exp%d_%s.csv', expID,file_name));
                extract_speech_in_situ(expID, cevent_var, category_list, output_filename, args);
    
                % Step 2: Count Word - Word Cooccurrence
                input_csv = output_filename;
                utt_col = 10;
                sub_col = 1;
                cat_col = 5;
                output_folder = fullfile(output_dir,sprintf('exp%d_%s_word-cooccur', expID,file_name));
                args.skipSubVersions = 1; % skip sub versions (in utterance level)
                count_word2word_freq(input_csv, utt_col, sub_col, cat_col, output_folder)
            
                % Step 3: Filter Word Matrix based on Word List
                input_folder = output_folder;
                word_list = get_object_label(expID, 1:num_obj);
                input_file = fullfile(input_folder,sprintf('exp%d_all.csv',expID));
                output_file = fullfile(output_dir,sprintf('exp%d_all_filtered_obj_name.csv',expID));
                filter_word2word_freq(input_file, output_file, word_list);
            end
        
    end
end