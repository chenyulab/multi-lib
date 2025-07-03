%%%
% # Speech Analysis Demo Functions
%
% This demo showcases how to extract, organize, and analyze speech transcripts 
% in behavioral experiments using a modular, research-oriented pipeline.
%
% The demo is organized into 4 stages:
%
% ## 1. Extraction Functions
% Extract utterances based on cevent context (e.g., gaze, in-hand) or keyword patterns.
% Demonstrates keyword logic (individual, combined, sequence), timing alignment,
% and content-based filtering (e.g., object-specific or min-duration looks).
%
% ## 2. Grouping and Mapping Functions
% Group extracted speech by subject or category, and remap categorical values 
% using a mapping table for custom grouping (e.g., toy types, animate/inanimate).
%
% ## 3. Analysis and Calculation Functions
% Perform frequency analysis (word, word pair, category-word), lexical profiling,
% and word similarity computations to understand language use in context.
%
% ## 4. Other Utility Functions
% Create word frequency histograms, structured cevent variables, and wordcloud visualizations.
%
%
% ## Run Instructions
% To execute a specific demo case, call:
%
%   `demo_speech_analysis_functions(CASE_ID)`
%
% Each case below demonstrates a real use scenario and is tied to an analytical function:
%
% -----------------------------------------------------------------------
% CASE ID    FUNCTIONALITY                           RESEARCH INTENTION
% --------   --------------------------------------  ----------------------
% 1          Extract all utterances by subject IDs   Get the complete transcript per subject
% 2          Keyword matching modes (A, A+B, A B)     Test keyword logic and syntax flexibility
% 3          Speech during child gaze                What’s said when child looks at objects
% 4          Speech before child gaze                Do parents anticipate child gaze?
% 5          Partial speech overlap with gaze        Capture loosely co-occurring speech
% 6          Keyword use during gaze                 Does parent say ‘look’ when child looks?
% 7          Rabbit-specific analysis                Is ‘rabbit’ named when child looks at it?
% 8          Gaze longer than threshold (1s)         Filter short events to study sustained looks
% 9          Naming structure (a/the/none + label)   Compare different naming conventions
%
% 10         Category remapping after extraction     Merge fine-grained categories into types
% 11         Grouping speech by subject/category     Prepare for subject-level or category-level analysis
%
% 12         Count all words per subject             Compute word frequency distribution
% 13         Count specific words + types            Track verbs, keywords, and lexical richness
% 14         In-hand context + group + count         Link action context to spoken words
% 15         Word pair frequency by group            Get subject-level co-occurrence patterns
% 16         Word pair frequency by group            Get subject-level co-occurrence patterns
% 17         Cat-word frequency matrix               See which words map to which categories
% 18         Cat-word + similarity matrix            Are similar words used for similar objects?
%
% 19         Generate structured cevent variables    Create event-based labels from transcript
% 20         Generate wordclouds                     Visualize lexical frequency in transcripts
%
% -----------------------------------------------------------------------
%
% Output CSV and Excel files are stored in:
%   `Z:\demo_output_files\speech_analysis`
%
%%%
function demo_speech_analysis_functions(option)
    % all the demo files are saved into, users can define their own path:
    output_dir = 'Z:\demo_output_files\speech_analysis';
    
    switch option
        %%% extracting functions
        case 1
            % basic usage -- extract all the speech data based on subexpIDs
            % create an output file containing individual spoken utterances
            % from all the subjects, one utterance intance per row 
            subexpIDs = [12];
            keywords = {};
            output_filename = fullfile(output_dir,'case1_all_utterance.csv');
            extract_speech_by_keywords(subexpIDs,keywords,output_filename);
    
        case 2
            % extracting keywords in 3 different ways:
            % individual words {'A', 'B'}
            subexpIDs = [351];
            keywords = {'car','firetruck','bulldozer','motorcycle','helicopter'};
            output_filename = fullfile(output_dir,'case2_individual_words.csv');
            extract_speech_by_keywords(subexpIDs,keywords,output_filename);

            % combine {'A+B'}
            keywords = {'like+car','like+truck','play+car','play+truck'};
            output_filename = fullfile(output_dir,'case2_combine_words.csv');
            extract_speech_by_keywords(subexpIDs,keywords,output_filename);

            % sequence {'A B'}
            keywords = {'this car', 'that car','the car','a car'};
            output_filename = fullfile(output_dir,'case2_sequence_words.csv');
            extract_speech_by_keywords(subexpIDs,keywords,output_filename);
        
        case 3
            % Extract all of the spoken utterances that temporally overlap with a look 
            expID = 12;
            cevent_var = 'cevent_eye_roi_child';
            category_list = 1:get_num_obj(expID)+1; % include face looks as a category value 
            output_filename = fullfile(output_dir,'case3_speech_during_gaze.csv');
            extract_speech_in_situ(expID, cevent_var, category_list, output_filename);
    
        case 4
            % Extract Speech using a different temporal window defined as from 3 secs before a spoken utterance onset
            expID = 12;
            cevent_var = 'cevent_eye_roi_child';
            category_list = 1:get_num_obj(expID)+1;
            args.whence = 'start';
            args.interval = [-3 0];
            output_filename = fullfile(output_dir,'case4_speech_before_gaze.csv');
            extract_speech_in_situ(expID, cevent_var, category_list, output_filename, args);
    
        case 5
            % Speech Partially Overlapping with Gaze
            % Capture speech that overlaps 50% with gaze event
            expID = 12;
            cevent_var = 'cevent_eye_roi_child';
            category_list = 1:get_num_obj(expID)+1;
            args.threshold = 0.5; % to be included, 50% of an utterance is within the temporal window 
            output_filename = fullfile(output_dir,'case5_partial_overlap.csv');
            extract_speech_in_situ(expID, cevent_var, category_list, output_filename, args);
    
        case 6
            % Keyword Matching During Gaze
            % when attending to an object and hearing a list of keywords specified  
            expID = 351;
            cevent_var = 'cevent_eye_roi_child';
            category_list = [6 9 11]; % visual attention: 6-car 9 - truck 11 - carrot; 
            args.target_words = {'car','truck','motorcycle'};
            output_filename = fullfile(output_dir,'case6_keyword_during_gaze.csv');
            extract_speech_in_situ(expID, cevent_var, category_list, output_filename, args);
    
        case 7
            % simialr to case 6, with a specified time window 
            % Rabbit-Specific Attention Window
            % extract 3 sec before and 1 sec after child looks at rabbit,
            % see how many times parent is naming rabbit
            expID = 12;
            cevent_var = 'cevent_eye_roi_child';
            category_list = 7; % 7 - rabbit 
            args.whence = 'start';
            args.interval = [-3 1];
            args.target_words = {'rabbit','bunny'};
            output_filename = fullfile(output_dir,'case7_rabbit.csv');
            extract_speech_in_situ(expID, cevent_var, category_list, output_filename, args);

        case 8
            % only when looking longer Than 1 second
            % filter out short looking, only extract the looking that is
            % longer than 1 sec
            expID = 12;
            cevent_var = 'cevent_eye_roi_child';
            category_list = 1:get_num_obj(expID)+1;
            args.min_dur = 1;
            output_filename = fullfile(output_dir,'case8_long_look.csv');
            extract_speech_in_situ(expID, cevent_var, category_list, output_filename, args);


        case 9
            % grab object names from dictionary for expID, put names into keywords, 
            % and then run; extract three naming situations 
            % 1) the + name, 2) a + name, 3) just name
            expID = 12;
            cevent_var = 'cevent_speech_naming_local-id';
            category_list = 1:get_num_obj(expID);
            obj_labels = get_object_label(expID,category_list);

            % the + name
            keyword_list1 = {};
            for i = 1:length(obj_labels)
                keyword = ['the+',obj_labels{i}];
                keyword_list1 = [keyword_list1,keyword];
            end
            args.target_words = keyword_list1;
            output_filename = fullfile(output_dir,'case9_the+name.csv');
            extract_speech_in_situ(expID, cevent_var, category_list, output_filename, args);

            % a + name
            keyword_list2 = {};
            for i = 1:length(obj_labels)
                keyword = ['a+',obj_labels{i}];
                keyword_list2 = [keyword_list2,keyword];
            end
            args.target_words = keyword_list2;
            output_filename = fullfile(output_dir,'case9_a+name.csv');
            extract_speech_in_situ(expID, cevent_var, category_list, output_filename, args);

            % any name with or w/o a or the
            keyword_list3 = obj_labels;
            args.target_words = keyword_list3;
            output_filename = fullfile(output_dir,'case9_name.csv');
            extract_speech_in_situ(expID, cevent_var, category_list, output_filename, args);
            


        case 10
            % extract speech data that within child roi time window
            expID = 351;
            cevent_var = 'cevent_eye_roi_child'; 
            num_obj = get_num_obj(expID);
            category_list = 1:num_obj+1; % list all the category: objects + face for eye roi data
            output_filename = fullfile(output_dir,'case10_extracted.csv');
            extract_speech_in_situ(expID,cevent_var,category_list,output_filename);
    
            % remap the data with mapping table
            input_csv = output_filename;
            mapping_table = [1,1;12,1;14,1;24,1;3,1;11,1;18,1;19,1;22,1;2,2;7,2;...
                8,2;10,2;15,2;16,2;23,2;26,2;27,2;4,3;5,3;6,3;9,3;13,3;17,3;20,3;21,3;25,3;28,4]; % organize items based on semantic categories 
            categoryColumn = 6;
            output_csv = fullfile(output_dir,'case10_mapped.csv');
            remap_cat_values(input_csv, categoryColumn, mapping_table, output_csv)

        %%% grouping functions

        case 11
            % extract speech data that within child holding object time window
            expID = 351;
            cevent_var = 'cevent_inhand_child'; 
            num_obj = get_num_obj(expID);
            category_list = 1:num_obj+1; % list all the category: objects + face for eye roi data
            output_filename = fullfile(output_dir,'case11_extracted.csv');
            extract_speech_in_situ(expID,cevent_var,category_list,output_filename);
            
            % group the output file into subject level, category level,
            % subject-category level.
            input_csv_dir = output_filename;
            group_speech_in_situ(input_csv_dir)
    
    
        %%% analysis functions
        case 12
            % count the frequency of all the words in
            % these subjects' transcripts
            subexpIDs = [351, 353];
            output_filename = fullfile(output_dir,'case12_count_all_words.csv');
            count_words_by_subject(subexpIDs,output_filename)


        case 13
            % extract statistics (e.g. # of types, # of tokens, #s of nouns, verbs,...) 
            % and count # of keywords 
            subexpIDs = [12];
            target_words = {'eat','bite'};
            output_filename = fullfile(output_dir,'case13.csv');
            count_words_by_type(subexpIDs,target_words,output_filename)

        case 14
            % extract speech utterance that contains 'car' when parent holding a car or truck
            expID = 351;
            cevent_var = 'cevent_inhand_parent'; % set speech utterance as the default
            category_list = [6,9];% 6 - car; 9 - truck 
            args.target_words = {'car'}; 
            output_filename = fullfile(output_dir,'case14_extracted.csv');
            extract_speech_in_situ(expID,cevent_var,category_list,output_filename, args);

            % group in subject level
            input_file = output_filename; %fullfile(output_dir,'case14_extracted.csv');
            group_speech_in_situ(input_file)

            % count the 'look' and 'car' occurance in subject level
            input_file = fullfile(output_dir,'case14_extracted_subject.csv');
            output_file = fullfile(output_dir,'case14_extracted_word_count.csv');
            text_col = 5;
            id_col = 2;
            target_words = ["look","car"];
            extraStopWords = {};
            count_word_speech_in_situ(input_file, output_file, target_words, extraStopWords, text_col , id_col)


        case 15
            % extract all the words from exp 12
            subexpIDs = [12];
            cevent_var = '';
            category_list = NaN; 
            output_filename = fullfile(output_dir,'case15_all_words.csv');
            extract_speech_in_situ(subexpIDs,cevent_var,category_list,output_filename)

            % count word - word pair frequency in subject level
            input_csv = fullfile(output_dir,'case15_all_words.csv');
            utt_col = 8;
            group_col = 2;
            group_label = 'subject';
            output_folder = fullfile(output_dir,'case15_all_words_word-word_subject');
            count_word_word_pair_freq(input_csv, utt_col, group_col, group_label, output_folder)

        case 16 
            % extract the words when child is attending to toys from exp 12
            subexpIDs = [12];
            cevent_var = 'cevent_eye_roi_child';
            category_list = 1:get_num_obj(subexpIDs);
            output_filename = fullfile(output_dir,'case16_child_looking.csv');
            extract_speech_in_situ(subexpIDs,cevent_var,category_list,output_filename)
            
            % count word - word pair frequency in subject level
            input_csv = fullfile(output_dir,'case16_child_looking.csv');
            utt_col = 8;
            group_col = 2;
            group_label = 'subject';
            output_folder = fullfile(output_dir,'case16_child_looking_word-word_subject');
            count_word_word_pair_freq(input_csv, utt_col, group_col, group_label, output_folder)

            % count word - word pair frequency in object level
            input_csv = fullfile(output_dir,'case16_child_looking.csv');
            utt_col = 8;
            group_col = 6;
            group_label = 'category';
            output_folder = fullfile(output_dir,'case16_child_looking_word-word_category');
            count_word_word_pair_freq(input_csv, utt_col, group_col, group_label, output_folder)

        case 17
            % extract the speech when child is holding objects
            subexpIDs = [12];
            cevent_var = 'cevent_inhand_child'; 
            num_obj = get_num_obj(subexpIDs);
            category_list = 1:num_obj;
            output_filename = fullfile(output_dir,'case17_speech_in_child_inhand.csv');
            extract_speech_in_situ(subexpIDs,cevent_var,category_list,output_filename)
            
            % count cat - word pair frequency in subject level
            input_csv = output_filename;
            sub_col = 2;
            cat_col = 6;
            utt_col = 8;
            output_excel = fullfile(output_dir,'case17_speech_in_child_inhand_cat_word.xlsx');
            count_cat_word_pair_freq(input_csv,sub_col,cat_col,utt_col,output_excel);

        
        case 18
            % extract the speech when parent is naming objects
            subexpIDs = [15];
            cevent_var = 'cevent_speech_naming_local-id'; 
            num_obj = get_num_obj(subexpIDs);
            category_list = 1:num_obj;
            output_filename = fullfile(output_dir,'case18_parent_naming.csv');
            extract_speech_in_situ(subexpIDs,cevent_var,category_list,output_filename)

            % count cat - word pair frequency in subject level
            input_csv = output_filename;
            sub_col = 2;
            cat_col = 6;
            utt_col = 8;
            output_excel = fullfile(output_dir,'case18_parent_naming_cat_word.xlsx');
            count_cat_word_pair_freq(input_csv,sub_col,cat_col,utt_col,output_excel);

            % % calculate similarity score
            % input_excel = output_excel;
            % output_csv = fullfile(output_dir,'case18_parent_naming_cat_word_simailarity.csv');
            % cal_word_similarity(input_excel, output_csv)
        % 
        % case 19
        %     % extract the words when child is attending to toys from exp 12
        %     subexpIDs = [12];
        %     cevent_var = 'cevent_eye_roi_child';
        %     category_list = 1:get_num_obj(subexpIDs);
        %     output_filename = fullfile(output_dir,'case19_child_looking.csv');
        %     extract_speech_in_situ(subexpIDs,cevent_var,category_list,output_filename)
        % 
        %     % group the data into subject level & object level
        %     input_csv = output_filename;
        %     group_speech_in_situ(input_csv);
        % 
        %     % count word - word pair frequency in object level
        %     input_csv = fullfile(output_dir,'case19_child_looking_category.csv');
        %     utt_col = 4;
        %     output_excel = fullfile(output_dir,'case19_child_looking_word_word_category.xlsx');
        %     count_word_word_pair_freq(input_csv, utt_col, output_excel)
        % 
        %     % calculate similarity score
        %     input_excel = output_excel;
        %     output_csv = fullfile(output_dir,'case19_child_looking_word_word_simailarity.csv');
        %     cal_word_similarity(input_excel, output_csv)           
            


        % %%% other related functions        
        % case 19
        %     % ## Warning: this case will generate variables in our system,
        %     % users should not use this unless get approval.
        % 
        %     % generates csv file with every utterance where a
        %     % keyword was found in the speech transcripts of subjects
        %     % the output file also includes the timestamps and source camera information for each instance
        %     word_list = {'assemble','cut','close','drink'};
        %     word_ids = [1,2,3,4];
        %     subexpIDs = [58];
        %     output_filename = fullfile(output_dir,'example_19.csv');
        %     % optional arguments can be included to change the source
        %     % camera and alter the timestamp of the generated event clips
        %     data = extract_events_by_keyword(subexpIDs, word_list, output_filename);
        %     varname = 'cevent_speech_action-verbs_demo';
        %     make_keywords_events(word_list, word_ids, data, varname);
        % 
        % case 20
        %     % generates a wordcloud plot for a single subject or all
        %     % subjects in an experiment
        %     % size of the words reflects number of times that word was
        %     % referenced in the transcipt(s)
        %     subexpID = [1201];
        %     generate_wordcloud(subexpID,output_dir);
    end
end