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
% -------------------------------------------------------------------
%
% Output CSV and Excel files are stored in:
%   `Z:\demo_output_files\speech_analysis`
%
%%%
function demo_speech_analysis_functions(option)
    % all the demo files are saved into, users can define their own path:
    output_dir = 'Z:\CORE\repository_new\multi-lib\demo_results\speech_analysis';
    
    switch option
        %%% extracting functions
        case 1
            % basic usage -- extract all the speech data based on subexpIDs
            % create an output file containing individual spoken utterances
            % from all the subjects, one utterance intance per row 
            subexpIDs = [12];
            category_list = [];
            cevent_var = '';
            output_filename = fullfile(output_dir,'case1_all_utterance.csv');
            extract_speech_in_situ(subexpIDs,cevent_var,category_list,output_filename)

        case 2
            % extracting keywords in 4 different ways:
            % individual words {'A', 'B'}
            subexpIDs = [351];
            category_list = [];
            cevent_var = '';
            args.target_words = {'car','firetruck','bulldozer','motorcycle','helicopter'};
            output_filename = fullfile(output_dir,'case2_individual_words.csv');
            extract_speech_in_situ(subexpIDs,cevent_var,category_list,output_filename,args)

            % combine {'A+B'}
            args.target_words = {'like+car','like+truck','play+car','play+truck'};
            output_filename = fullfile(output_dir,'case2_combine_words.csv');
            extract_speech_in_situ(subexpIDs,cevent_var,category_list,output_filename,args)

            % sequence {'A B'}
            args.target_words = {'this car', 'that car','the car','a car'};
            output_filename = fullfile(output_dir,'case2_sequence_words.csv');
            extract_speech_in_situ(subexpIDs,cevent_var,category_list,output_filename,args)

            % sequence_wildcard {'A * B'}, * can be any word
            args.target_words = {'a * car', 'the * car'};
            output_filename = fullfile(output_dir,'case2_sequence_wildcard_words.csv');
            extract_speech_in_situ(subexpIDs,cevent_var,category_list,output_filename,args)

        case 3
            % Extract all of the spoken utterances that temporally overlap with a look 
            subexpID = 12;
            cevent_var = 'cevent_eye_roi_child';
            category_list = 1:get_num_obj(subexpID)+1; % include face looks as a category value 
            output_filename = fullfile(output_dir,'case3_speech_during_gaze.csv');
            extract_speech_in_situ(subexpID, cevent_var, category_list, output_filename);
    
        case 4
            % Extract Speech using a different temporal window defined as
            % from 3 secs before a child gaze onset
            subexpID = 12;
            cevent_var = 'cevent_eye_roi_child';
            category_list = 1:get_num_obj(subexpID)+1;
            args.whence = 'start';
            args.interval = [-3 0]; % 3 seconds before the onset
            output_filename = fullfile(output_dir,'case4_speech_before_gaze.csv');
            extract_speech_in_situ(subexpID, cevent_var, category_list, output_filename, args);
    
        case 5
            % Speech Partially Overlapping with Gaze
            % Capture speech that overlaps 50% with gaze event
            subexpID = 12;
            cevent_var = 'cevent_eye_roi_child';
            category_list = 1:get_num_obj(subexpID)+1;
            args.threshold = 0.5; % to be included, 50% of an utterance is within the temporal window 
            output_filename = fullfile(output_dir,'case5_partial_overlap.csv');
            extract_speech_in_situ(subexpID, cevent_var, category_list, output_filename, args);
    
        case 6
            % Keyword Matching During Gaze
            % when attending to an object and hearing a list of keywords specified  
            subexpID = 351;
            cevent_var = 'cevent_eye_roi_child';
            category_list = [6 9]; % visual attention: 6-car 9 - truck; 
            args.target_words = {'car','truck'};
            output_filename = fullfile(output_dir,'case6_keyword_during_gaze.csv');
            extract_speech_in_situ(subexpID, cevent_var, category_list, output_filename, args);
    
        case 7
            % simialr to case 6, with a specified time window 
            % Rabbit-Specific Attention Window
            % extract 3 sec before and 1 sec after child looks at rabbit,
            % see how many times parent is naming rabbit
            subexpID = 12;
            cevent_var = 'cevent_eye_roi_child';
            category_list = 7; % 7 - rabbit 
            args.whence = 'start';
            args.interval = [-3 1];
            args.target_words = [
                2;   % cat
                7;   % ostrich
                8;   % frog
                10;  % lobster
                15;  % dog
                16;  % elephant
                23;  % stingray
                26;  % duck
                27;  % bee
            ];
            args.target_words = {
                'cat','kitty','animal','ostrich','frog','froggy','lobster','crab','dog',...
                'doggy','puppy','pug','elephant','animal','stingray','ray','duck','ducky',...
                'bee','bumblebee'...
            };
            output_filename = fullfile(output_dir,'case7_rabbit.csv');
            extract_speech_in_situ(subexpID, cevent_var, category_list, output_filename, args);

        case 8
            % only when looking longer Than 1 second
            % filter out short looking, only extract the looking that is
            % longer than 1 sec
            subexpID = 12;
            cevent_var = 'cevent_eye_roi_child';
            category_list = 1:get_num_obj(subexpID)+1;
            args.min_dur = 1;
            output_filename = fullfile(output_dir,'case8_long_look.csv');
            extract_speech_in_situ(subexpID, cevent_var, category_list, output_filename, args);


        case 9
            % grab object names from dictionary for subexpID, put names into keywords, 
            % and then run; extract three naming situations 
            % 1) the + name, 2) a + name, 3) just name
            subexpID = 12;
            cevent_var = 'cevent_speech_naming_local-id';
            category_list = 1:get_num_obj(subexpID);
            obj_labels = get_object_label(subexpID,category_list);

            % the + name
            keyword_list1 = {};
            for i = 1:length(obj_labels)
                keyword = ['the+',obj_labels{i}];
                keyword_list1 = [keyword_list1,keyword];
            end
            args.target_words = keyword_list1;
            output_filename = fullfile(output_dir,'case9_the+name.csv');
            extract_speech_in_situ(subexpID, cevent_var, category_list, output_filename, args);

            % a + name
            keyword_list2 = {};
            for i = 1:length(obj_labels)
                keyword = ['a+',obj_labels{i}];
                keyword_list2 = [keyword_list2,keyword];
            end
            args.target_words = keyword_list2;
            output_filename = fullfile(output_dir,'case9_a+name.csv');
            extract_speech_in_situ(subexpID, cevent_var, category_list, output_filename, args);

            % any name with or w/o a or the
            keyword_list3 = obj_labels;
            args.target_words = keyword_list3;
            output_filename = fullfile(output_dir,'case9_name.csv');
            extract_speech_in_situ(subexpID, cevent_var, category_list, output_filename, args);
            
        case 10
            % Extract speech data during child ROI windows and remap objects into semantic categories

            % extract speech data that within child roi time window
            subexpID = 351;
            cevent_var = 'cevent_eye_roi_child'; 
            num_obj = get_num_obj(subexpID);
            category_list = 1:num_obj+1; % list all the category: objects + face for eye roi data
            output_filename = fullfile(output_dir,'case10_extracted.csv');
            extract_speech_in_situ(subexpID,cevent_var,category_list,output_filename);
    
            % remap the data with mapping table
            input_csv = output_filename;
            mapping_table = [1,1;12,1;14,1;24,1;3,1;11,1;18,1;19,1;22,1;2,2;7,2;...
                8,2;10,2;15,2;16,2;23,2;26,2;27,2;4,3;5,3;6,3;9,3;13,3;17,3;20,3;21,3;25,3;28,4]; % organize items based on semantic categories 
            categoryColumn = 6;
            output_csv = fullfile(output_dir,'case10_mapped.csv');
            remap_cat_values(input_csv, categoryColumn, mapping_table, output_csv)

        %%% grouping functions
        case 11
            % this demo shows how to group the extracted data into subject level, category level,
            % and subject-category level.
            %   subject.csv
            %       - Each row contains all utterances grouped by subject.
            %       - Example:
            %           subject 35001 -> all extracted utterances from subject 35001
            %
            %   category.csv
            %       - Each row contains all utterances grouped by category/object ID.
            %       - Example:
            %           category 3 -> all utterances occurring while object 3 was in hand
            %
            %   subject-category.csv
            %       - Each row contains utterances grouped by both subject and category.
            %       - Example:
            %           subject 35001 + category 3 ->
            %           all utterances from subject 35001 during object 3 intervals

            % extract speech data that within child holding object time window
            subexpID = 351;
            cevent_var = 'cevent_inhand_child'; 
            num_obj = get_num_obj(subexpID);
            category_list = 1:num_obj+1; % list all the category: objects + face for eye roi data
            output_filename = fullfile(output_dir,'case11_extracted.csv');
            extract_speech_in_situ(subexpID,cevent_var,category_list,output_filename);
            
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
            subexpID = 351;
            cevent_var = 'cevent_inhand_parent'; % set speech utterance as the default
            category_list = [6,9];% 6 - car; 9 - truck 
            args.target_words = {'car'}; 
            output_filename = fullfile(output_dir,'case14_extracted.csv');
            extract_speech_in_situ(subexpID,cevent_var,category_list,output_filename, args);

            % group in subject level
            input_file = output_filename; %fullfile(output_dir,'case14_extracted.csv');
            group_speech_in_situ(input_file)

            % count the 'look' and 'car' occurance in subject level
            input_file = fullfile(output_dir,'case14_extracted_subject.csv');
            output_file = fullfile(output_dir,'case14_extracted_word_count.csv');
            text_col = 5;
            id_col = 1;
            target_words = ["look","car"];
            extraStopWords = {};
            count_word_speech_in_situ(input_file, output_file, target_words, extraStopWords, text_col , id_col)

        case 15
            % This case extracts all utterances from experiment 12 without
            % applying any behavioral filtering. It then computes word-word
            % co-occurrence frequencies and generates outputs at: subject level, 
            % category level, and experiment overall level

            % extract all the words from exp 12
            subexpIDs = [12];
            cevent_var = '';
            category_list = NaN; 
            output_filename = fullfile(output_dir,'case15_all_words.csv');
            extract_speech_in_situ(subexpIDs,cevent_var,category_list,output_filename)

            % count word - word pair frequency in subject level and
            % categoryical level
            input_csv = fullfile(output_dir,'case15_all_words.csv');
            sub_col = 1; % subject column number
            cat_col = 5; % category column number
            utt_col = 10; % utterance column number
            output_folder = fullfile(output_dir,'case15_all_words_word-word');
            count_word2word_freq(input_csv, utt_col, sub_col,cat_col, output_folder)

        case 16 
            % This case extracts utterances that occur while the child is
            % visually attending to toys in experiment 12. Word-word
            % co-occurrence frequencies are then calculated for the extracted
            % speech data.

            % extract the words when child is attending to toys from exp 12
            subexpIDs = [12];
            cevent_var = 'cevent_eye_roi_child';
            category_list = 1:get_num_obj(subexpIDs); % all toys in exp
            output_filename = fullfile(output_dir,'case16_child_looking.csv');
            extract_speech_in_situ(subexpIDs,cevent_var,category_list,output_filename)
            
            % count word - word pair frequency in subject level and
            % categoryical level
            input_csv = fullfile(output_dir,'case16_child_looking.csv');
            sub_col = 1; % subject column number
            cat_col = 5; % category column number
            utt_col = 10; % utterance column number
            output_folder = fullfile(output_dir,'case16_child_looking_word-word');
            count_word2word_freq(input_csv, utt_col, sub_col,cat_col, output_folder)

        case 17
            % This case extracts speech occurring while the child is holding
            % objects in experiment 12. It then computes category-word
            % association frequencies between held objects and spoken words.

            % extract the speech when child is holding objects
            subexpIDs = [12];
            cevent_var = 'cevent_inhand_child'; 
            num_obj = get_num_obj(subexpIDs);
            category_list = 1:num_obj; % all objects
            output_filename = fullfile(output_dir,'case17_speech_in_child_inhand.csv');
            extract_speech_in_situ(subexpIDs,cevent_var,category_list,output_filename)
            
            % count cat - word pair frequency in subject level and category
            % level
            input_csv = output_filename;
            sub_col = 1;
            cat_col = 5;
            utt_col = 10;
            output_excel = fullfile(output_dir,'case17_speech_in_child_inhand_cat_word.xlsx');
            count_cat2word_freq(input_csv,sub_col,cat_col,utt_col,output_excel);

        
        case 18
            % This case extracts speech segments labeled as parent naming
            % events in experiment 15. It then computes category-word
            % association frequencies between named objects and spoken words.

            % extract the speech when parent is naming objects
            subexpIDs = [15];
            cevent_var = 'cevent_speech_naming_local-id'; 
            num_obj = get_num_obj(subexpIDs);
            category_list = 1:num_obj; % all objects
            output_filename = fullfile(output_dir,'case18_parent_naming.csv');
            extract_speech_in_situ(subexpIDs,cevent_var,category_list,output_filename)

            % count cat - word pair frequency in subject level
            input_csv = output_filename;
            sub_col = 1;
            cat_col = 5;
            utt_col = 10;
            output_excel = fullfile(output_dir,'case18_parent_naming_cat_word.xlsx');
            count_cat2word_freq(input_csv,sub_col,cat_col,utt_col,output_excel);   
            


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