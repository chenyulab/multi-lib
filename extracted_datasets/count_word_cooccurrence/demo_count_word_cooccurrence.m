% AUTHOR:  Jingwen Pang
% DATE:    2026-1-20
% REVISED: Connor Pickett 2025-11-14
% ========================================================================
% PURPOSE
% ========================================================================
% This demo illustrates how to extract and analyze word–word co-occurrence
% patterns from speech data at the experiment level.
%
% The pipeline:
%   1) Extract all speech utterances from an experiment
%   2) Compute word–word co-occurrence matrices
%   3) Filter the matrices using one or more vocabulary lists
%
% The final output can be a full n × n co-occurrence matrix (all words),
% or a reduced matrix (e.g., m × m or a × b) depending on the input
% vocabulary list(s).
%
%
% ========================================================================
% CO-OCCURRENCE DEFINITION AND MATRIX CONVENTION
% ========================================================================
% Each utterance is treated as a single "bag" (bucket) of words.
%
% Two words are said to co-occur if they appear together within the same
% utterance (i.e., within the same row of the input CSV).
%
% The co-occurrence count for a word pair is defined as the number of
% utterances in which both words appear together.
%
% ------------------------------------------------------------------------
% How to read the matrix
% ------------------------------------------------------------------------
% By definition:
%   - Each ROW corresponds to a reference word.
%   - Each COLUMN corresponds to a co-occurring word.
%   - The value at (row_i, col_j) is the number of utterances in which
%     row_i and col_j appear together.
%
% ------------------------------------------------------------------------
% Example 1: Basic co-occurrence
% ------------------------------------------------------------------------
%   Utterance 1: "get ... ball"
%   Utterance 2: "kick ball"
%   Utterance 3: "get red ball"
%   Utterance 4: "look ... dog"
%
%   Resulting co-occurrence matrix:
%
%               get  ball  red  dog  kick
%       get       0    2    1    0     0
%       ball      2    0    1    0     1
%       red       1    1    0    0     0
%       dog       0    0    0    0     0
%       kick      0    1    0    0     0
%
% ------------------------------------------------------------------------
% Example 2: Repeated words within one utterance
% ------------------------------------------------------------------------
%   Utterance: "dog ... dog ... cat!"
%
%   In this case:
%     - "dog" co-occurs with "cat" twice
%     - "cat" co-occurs with "dog" once
%
%   Resulting matrix:
%
%               dog   cat
%       dog       1     2
%       cat       1     0
%
%   Important note:
%     Because repeated words within a single utterance are counted,
%     the co-occurrence matrix is NOT necessarily symmetric.
%
%     (row_i, col_j) and (row_j, col_i) can differ.
%
%
% ========================================================================
% PIPELINE OVERVIEW
% ========================================================================
% Step 1) Extract speech utterances
% ------------------------------------------------------------------------
%   Uses:
%     extract_speech_in_situ()
%
%   Description:
%     Extracts speech utterances from experiment, time window can be
%     specificed. See more info in demo_speech_analysis_functions
%
%   Input:
%     - No CSV input file
%     - Reads directly from the lab data using expID
%
%   Output:
%     - exp##_all_speech.csv
%       (one row per utterance, including subject, category, timing, text)
%
% ------------------------------------------------------------------------
% Step 2) Count word–word co-occurrence
% ------------------------------------------------------------------------
%   Uses:
%     count_word2word_freq()
%
%   Description:
%     Builds word–word co-occurrence matrices based on utterance-level
%     co-occurrence.
%
%   Input:
%     - exp##_all_speech.csv  (from Step 1)
%
%   Output (stored in exp##_all_speech_word-cooccur/):
%     - exp##_all.csv
%         Overall word co-occurrence matrix for the experiment
%     - cat-XX.csv
%         Category-level summaries
%     - [subID].csv
%         Subject-level summaries
%     - Row-level files
%         Detailed utterance-level co-occurrence data
%         (generated only when args.skipSubVersions = 0)
%
%
% ------------------------------------------------------------------------
% Step 3) Filter by vocabulary list(s)
% ------------------------------------------------------------------------
%   Uses:
%     filter_word2word_freq()
%
%   Description:
%     Filters the full co-occurrence matrix using one or more predefined
%     vocabulary lists.
%
%   Input:
%     - exp##_all.csv        (from Step 2)
%     - One or two word lists (e.g., MCDI, object names, action verbs)
%
%   Output:
%     - exp##_all_filtered.csv
%
%   Notes:
%     - One word list  → m × m filtered matrix
%     - Two word lists → a × b filtered matrix
%
%   The filtered matrix also includes summary statistics such as
%   word frequency and word-pair frequency.
%
% ========================================================================
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
                count_word2word_freq(input_csv, utt_col, sub_col, cat_col, output_folder, args)
                
                % Step 3: Filter Word Matrix based on Word List
                input_folder = output_folder;
                
                mcdi_path = "M:\MCDI_wordlist.csv";
                mcdi_table = readtable(mcdi_path);
                word_list = mcdi_table.item_definition;
                word_list = word_list'; % get mcdi word list
                
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
                count_word2word_freq(input_csv, utt_col, sub_col, cat_col, output_folder, args)
            
                % Step 3: Filter Word Matrix based on Word List
                input_folder = output_folder;
                word_list = get_object_label(expID, 1:num_obj); % get object word label list
                input_file = fullfile(input_folder,sprintf('exp%d_all.csv',expID));
                output_file = fullfile(output_dir,sprintf('exp%d_all_filtered_obj_name.csv',expID));
                filter_word2word_freq(input_file, output_file, word_list);
            end

        case 3
            output_dir = 'M:\extracted_datasets\count_word_cooccurrence\obj_verb_cooccurrence';
            if ~exist("expIDs","var")
                expIDs =[351]; 
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
                count_word2word_freq(input_csv, utt_col, sub_col, cat_col, output_folder, args)
            
                % Step 3: Filter Word Matrix based on Word List
                input_folder = output_folder;
                verb_list = {'look', 'put', 'eat', 'make', 'get', 'spin', 'open', 'call', 'pour', 'try',...
                    'turn', 'push', 'give', 'drink', 'fit', 'hold', 'drive', 'touch', 'move', 'bring',...
                    'hop', 'close', 'scoop', 'ride', 'pet', 'crash', 'roll', 'pull', 'shake', 'pick'};

                obj_word_list = {'kettle','teapot','cat','kitty','potato','firetruck','bulldozer','backhoe','excavator','car','ostrich',...
                    'frog','froggy' 'truck','lobster','crab','carrot','colander','strainer','motorcycle','bike','motorbike','cup','dog',...
                    'doggy','pug','elephant','spaceship','pineapple','banana','submarine','boat','cookie','oreo','stingray','ray','fork',...
                    'helicopter','duck','ducky','bee'};
                input_file = fullfile(input_folder,sprintf('exp%d_all.csv',expID));
                output_file = fullfile(output_dir,sprintf('exp%d_all_filtered_obj_verb.csv',expID));
                filter_word2word_freq(input_file, output_file, verb_list, obj_word_list);

            end


        case 4
            output_dir = 'M:\extracted_datasets\count_word_cooccurrence\obj_verb_cooccurrence';
            if ~exist("expIDs","var")
                expIDs =[353]; 
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
                count_word2word_freq(input_csv, utt_col, sub_col, cat_col, output_folder, args)
            
                % Step 3: Filter Word Matrix based on Word List
                input_folder = output_folder;
                verb_list = {'spread', 'cut', 'make', 'eat', 'put', 'get', 'look', 'give', 'try', 'scoop',...
                    'hold', 'wipe', 'shake', 'touch', 'drink', 'move', 'pick', 'park', 'call',...
                    'open', 'close', 'pour', 'drop', 'pull', 'ride', 'tip', 'peel', 'fit', 'drive', 'stick'};

                obj_word_list = {'bread','sandwich','slice','top','piece','bag',...
                    'knife','fork','plate','jelly','jam','jar','strawberry','lid','cover',...
                    'cap','peanut_butter','peanut',...
                    'napkin','water','pitcher','drink','cola','cup',...
                    'closure','tie','fruit','bowl','banana','pear','grape','salt','pepper',...
                    'mug','flower','vase','table','chair'};
                input_file = fullfile(input_folder,sprintf('exp%d_all.csv',expID));
                output_file = fullfile(output_dir,sprintf('exp%d_all_filtered_obj_verb.csv',expID));
                filter_word2word_freq(input_file, output_file, verb_list, obj_word_list);

            end

    end
end