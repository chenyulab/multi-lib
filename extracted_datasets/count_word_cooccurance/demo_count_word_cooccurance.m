% PURPOSE
%   Extract and analyze word–word co-occurrence patterns from speech data across
%   multiple experiments. This demo builds co-occurrence matrices showing how
%   often pairs of words appear together within the same utterance, and then
%   filters those matrices down to a target vocabulary list (e.g., MCDI words).
%
%   Co-occurrence definition (for this function):
%     - We treat each utterance as one "bucket" of words.
%     - Two words co-occur if they both appear in the same utterance
%       (i.e., in the same row of the input CSV).
%     - The co-occurrence count for a word pair is the number of utterances
%       in which both words appear together.
%     - Example:
%           Utterance 1: "get the ball"
%           Utterance 2: "kick the ball"
%           Utterance 3: "get the red ball"
%           Utterance 4: "look, a dog"
%         -> ("get","ball") co-occur in 2 utterances
%         -> ("ball","red") co-occur in 1 utterance
%         -> ("ball","dog") co-occur in 0 utterances
%
%     - Rule: ROW label cooccur with COLUMN label N time
%     - Utterance: 'dog... dog... cat!'
%       in this case, dog co-occur with cat 2 times, cat co-occur with dog
%       1 times, so the table will be: 
%           dog cat
%       dog 1    2
%       cat 1    0
%
% AUTHOR:  Jingwen Pang
% DATE:    2025-11-05
% REVISED: Connor Pickett 2025-11-14
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
%   Step 2) Count word–word co-occurrence
%      - Uses 'count_word2word_freq()' on the all-speech CSV to build matrices
%        showing how often pairs of words appear together within a single
%        utterance, based on the definition above.
%      - Input file:
%          * exp##_all_speech.csv    (from Step 1)
%      - Output files (in exp##_all_speech_word-cooccur\):
%          * exp##_all.csv      - overall co-occurrence matrix for the experiment
%          * cat-XX.csv         - per-category co-occurrence
%          * per-subject files  - written only if args.skipSubVersions = 0
%
%   Step 3) Filter by vocabulary list
%      - Loads a predefined word list (e.g., MCDI via 'MCDI_wordlist.csv').
%      - Uses 'filter_word2word_freq()' to keep only rows/columns that match
%        the vocabulary items.
%      - Input files:
%          * exp##_all.csv         (from Step 2)
%          * MCDI_wordlist.csv     (or another word list on disk)
%      - Output file:
%          * exp##_all_filtered_obj-obj.csv
%        This filtered matrix contains only the words from MCDI and summary
%        columns such as word frequency and word-pair frequency.
%
% OUTPUT EXAMPLE (per experiment)
%   M:\extracted_datasets\count_word_cooccurance\
%     Step 1  |- exp12_all_speech.csv
%     Step 2  |- exp12_all_speech_word-cooccur\
%             |     |- exp12_all.csv
%             |     |- cat-1.csv
%             |     |- cat-2.csv
%             |     |- ...
%             |     `- subID files (if not skipped)
%     Step 3  `- exp12_all_filtered_obj-obj.csv
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