%%%
% # Speech Analysis Demo Functions
%
% This demo demonstrates how to analyze speech data across different situations using a set of modular functions. 
% The analysis generally follows 3 stages:
%
% ## 1. Extraction Functions
% Extract utterances from transcripts based on cevent or keyword matches.
%
%   **extract_speech_in_situ**
%     - Extracts speech data within a time window around cevent based on one experiment or a list of same-exp subjects.
%     - Windows can be adjusted relative to the start, end, or entire event duration.
%     - Can extract based on keywords
%
%   **extract_speech_by_keywords**
%     - Finds speech containing specific keywords across one or more experiments/subjects.
%     - Flexible keyword input: simple, combined (A+B), or sequential (A B).
%
% ## 2. Grouping and Mapping Functions
% Organize or recategorize extracted data.
%
%   **remap_cat_values**
%     - Maps original category values to new ones using a user-defined mapping table.
%
%   **group_speech_in_situ**
%     - Groups speech by subject, category (e.g., object), or their combination.
%
% ## 3. Analysis and Calculation Functions
% Analyze word usage patterns, count statistics, and compute similarities.
%
%   **count_words_by_subject**
%     - Counts word frequencies for each subject/experiment.
%
%   **count_words_by_type**
%     - Returns keyword frequencies and lexical properties (e.g., number of unique words, verbs).
%
%   **count_words_speech_in_situ**
%     - Performs detailed analysis of extracted speech including:
%       count total tokens, utterance length, word types, etc.
%
%   **count_speech_pair_in_situ**
%     - Finds local/global speech pairs and calculates word frequency.
%
%   **cal_word_similarity**
%     - Calculates similarity between utterance words and category labels using word vectors.
%
% ## 4. Other related Functions
%
%   **make_keywords_event**
%     - Helps generate structured keyword event files.
%   
%   **generate_wordcloud**
%     - Generate wordcloud images from subject's transcripts.
%
% Run `demo_speech_analysis_functions(CASE_ID)` with one of the cases below to try each demo.
%	Case	Functionality Description
%	1	    Extract all speech by subject IDs
%	2	    Extract speech containing any of several keywords
%	3	    Extract speech containing multiple keywords together (+ syntax)
%	4	    Extract speech with keywords in sequence (A B)
%	5	    Extract speech during cevent window
%	6	    Extract speech before a cevent (e.g., 3 seconds prior)
%	7	    Extract speech with partial overlap to cevent (50%)
%	8	    Extract speech with keyword within a cevent window
%	9	    Extract speech around a specific category object (e.g., rabbit)
%	10	    Extract + map categories + export
%	11	    Extract + group by subject/category
%	12	    Extract + count speech word pairs
%	13	    Extract + group by subject/category + count speech words type
%	14	    Count all word frequencies across experiments
%	15	    Count specific words and word types
%   16      Variable generation based on speech data
%   17      Generate word cloud image
%%%
function demo_speech_analysis_functions(option)
    % all the demo files are saved into, users can define their own path:
    output_dir = 'Z:\demo_output_files\speech_analysis';
    
    switch option
        %% extracting functions
        case 1
            % basic usage -- extract all the speech data based on subexpIDs
            subexpIDs = [12 15];
            keywords = {};
            output_filename = fullfile(output_dir,'example_1.csv');
            extract_speech_by_keywords(subexpIDs,keywords,output_filename);
    
        case 2
            % to extract a utterance that contains multiple keywords
            % each word need to be separated by comma, the output will be multiple
            % csv files, each file for one keyword
            % extract the speech data that contains 'try' or 'eat'
            subexpIDs = [12 15];
            keywords = {'try','eat'};
            output_filename = fullfile(output_dir,'example_2.csv');
            extract_speech_by_keywords(subexpIDs,keywords,output_filename);
    
        case 3
            % to extract a utterance that contains mutliple words, use
            % the format: 'A+B+C'
            % extract the speech data that contains 'look' and 'this' or 'look' and 'that' 
            subexpIDs = [12 15];
            keywords = {'look+this','look+that'};
            output_filename = fullfile(output_dir,'example_3.csv');
            extract_speech_by_keywords(subexpIDs,keywords,output_filename);
            
        case 4
            % to extract a utterance that contains mutliple words in sequence, use
            % the format: 'A B C'
            % extract the speech data that contains 'yummy' and 'mango' in sequence
            subexpIDs = [12 15];
            keywords = {'yummy mango'};
            output_filename = fullfile(output_dir,'example_4.csv');
            extract_speech_by_keywords(subexpIDs,keywords,output_filename);
        
        case 5    
            % basic usage -- extract speech utterance within cevent child roi time
            % window
            expID = 12;
            cevent_var = 'cevent_eye_roi_child';
            num_obj = get_num_obj(expID);
            category_list = 1:num_obj+1; % list all the category: objects + face for eye roi data
            output_filename = fullfile(output_dir,'example_5.csv');
            extract_speech_in_situ(expID,cevent_var,category_list,output_filename);
            
        case 6
            % extract the utterance in 3 seconds window before child roi
            expID = 12;
            cevent_var = 'cevent_eye_roi_child'; 
            num_obj = get_num_obj(expID);
            category_list = 1:num_obj+1;
            output_filename = fullfile(output_dir,'example_6.csv');
            args.whence = 'start';
            args.interval = [-3 0];
            extract_speech_in_situ(expID,cevent_var,category_list,output_filename, args);
    
        case 7
            % extract speech utterance that have 50% overlap with cevent data
            % window
            expID = 12;
            cevent_var = 'cevent_eye_roi_child'; 
            num_obj = get_num_obj(expID);
            category_list = 1:num_obj+1;
            args.threshold = 0.5;
            output_filename = fullfile(output_dir,'example_7.csv');
            extract_speech_in_situ(expID,cevent_var,category_list,output_filename, args);        
    
        case 8
            % extract speech utterance that contains keyword 'look' within cevent child roi time
            expID = 12;
            cevent_var = 'cevent_eye_roi_child'; % set speech utterance as the default
            num_obj = get_num_obj(expID);
            category_list = 1:num_obj+1;
            % target_words inputing format is the same as 'keywords' from extract_speech_by_keywords
            % see case 2 - case 4
            args.target_words = {'look'}; 
            output_filename = fullfile(output_dir,'example_8.csv');
            extract_speech_in_situ(expID,cevent_var,category_list,output_filename, args);
    
        case 9
            % extract speech utterance that contains keyword 'rabbit' 3 seconds
            % before and 1 second after child attending to rabbit
            expID = 12;
            cevent_var = 'cevent_eye_roi_child'; % set speech utterance as the default
            num_obj = get_num_obj(expID);
            category_list = 7;
            args.whence = 'start';
            args.interval = [-3 1];
            args.target_words = {'rabbit','bunny'}; 
            output_filename = fullfile(output_dir,'example_9.csv');
            extract_speech_in_situ(expID,cevent_var,category_list,output_filename, args);
           
    
        %% grouping functions
        case 10
            % extract speech data that within child roi time window
            expID = 351;
            cevent_var = 'cevent_eye_roi_child'; 
            num_obj = get_num_obj(expID);
            category_list = 1:num_obj+1; % list all the category: objects + face for eye roi data
            output_filename = fullfile(output_dir,'example_10_extracted.csv');
            extract_speech_in_situ(expID,cevent_var,category_list,output_filename);
    
            % remap the data with mapping table
            input_csv = output_filename;
            mapping_table = [1,1;12,1;14,1;24,1;3,1;11,1;18,1;19,1;22,1;2,2;7,2;...
                8,2;10,2;15,2;16,2;23,2;26,2;27,2;4,3;5,3;6,3;9,3;13,3;17,3;20,3;21,3;25,3;28,4];
            categoryColumn = 6;
            output_csv = fullfile(output_dir,'example_10_mapped.csv');
            remap_cat_values(input_csv, categoryColumn, mapping_table, output_csv)
    
        case 11
            % extract speech data that within child holding object time window
            expID = 351;
            cevent_var = 'cevent_inhand_child'; 
            num_obj = get_num_obj(expID);
            category_list = 1:num_obj+1; % list all the category: objects + face for eye roi data
            output_filename = fullfile(output_dir,'example_11_extracted.csv');
            extract_speech_in_situ(expID,cevent_var,category_list,output_filename);
            
            % group the output file into subject level, category level,
            % subject-category level.
            input_csv_dir = output_filename;
            group_speech_in_situ(input_csv_dir)
    
    
        %% calculation functions
        case 12
            % extract speech utterance that contains keyword 'lemon' 3 seconds
            % before and 1 second after child attending to lemon
            expID = 15;
            cevent_var = 'cevent_eye_roi_child'; % set speech utterance as the default
            category_list = 6;
            args.whence = 'start';
            args.interval = [-3 1];
            args.target_words = {'lemon'}; 
            output_filename = fullfile(output_dir,'example_12.csv');
            extract_speech_in_situ(expID,cevent_var,category_list,output_filename, args);
    
            % extarct the speech pairs and count the frequency of words
            input_file = fullfile(output_dir,'example_12_lemon.csv');
            output_file = fullfile(output_dir,'example_12_lemon_speech_pair.xlsx');
            text_col = 8;
            count_speech_pair_in_situ(input_file, text_col, output_file);
            
        case 13
            %****This function is debuging, not avaliable now
            % extract speech utterance that contains 'car' when parent holding a car/truck
            expID = 351;
            cevent_var = 'cevent_inhand_parent'; % set speech utterance as the default
            category_list = [6,9];
            args.target_words = {'car'}; 
            output_filename = fullfile(output_dir,'example_13.csv');
            extract_speech_in_situ(expID,cevent_var,category_list,output_filename, args);

            % group in subject level
            input_file = fullfile(output_dir,'example_13_car.csv');
            group_speech_in_situ(input_file)

            % count the 'look' and 'car' occurance in subject level
            input_file = fullfile(output_dir,'example_13_car_subject.csv');
            output_file = fullfile(output_dir,'example_13_car_word_count.csv');
            text_col = 5;
            id_col = 2;
            target_words = ["look","car"];
            extraStopWords = [];
            count_word_speech_in_situ(input_file, target_words, extraStopWords, text_col , id_col, output_file)
    
        case 14
            % given a list of subject ids or exp ids, count the frequency of all the words in
            % these subjects' transcripts
            subexpIDs = [351, 353];
            output_filename = fullfile(output_dir,'example_14.csv');
            count_words_by_subject(subexpIDs,output_filename)
    
        case 15
            % given a list of subject ids or exp ids, count the number of keywords
            % and types of words (e.g. number of verb, number of unique token .etc)
            subexpIDs = [12, 15];
            target_words = {'eat','bite'};
            output_filename = fullfile(output_dir,'example_15.csv');
            count_words_by_type(subexpIDs,target_words,output_filename)

        case 16
            % extract utterance when child is attending objects
            expID = 15;
            cevent_var = 'cevent_eye_roi_child'; % set speech utterance as the default
            category_list = 1:get_num_obj(expID);
            output_filename = fullfile(output_dir,'example_16.csv');
            extract_speech_in_situ(expID,cevent_var,category_list,output_filename);

            % group data into subject-category level and category level
            input_file = fullfile(output_dir,'example_16.csv');
            group_speech_in_situ(input_file)

            % calculate the similarity in subject-category level
            input_filename = fullfile(output_dir,'example_16_subject-category.csv');
            output_filename = fullfile(output_dir, 'example_16_sub-cat_similarity.csv');
            args.catValue_col = 5;
            args.speechWord_col = 6;
            cal_word_similarity(input_filename,output_filename,args)

            % calculate the similarity in category level
            input_filename = fullfile(output_dir,'example_16_category.csv');
            output_filename = fullfile(output_dir, 'example_16_cat_similarity.csv');
            args.subID_col = nan; % no subject id for cat level data
            args.catValue_col = 2;
            args.speechWord_col = 4;
            cal_word_similarity(input_filename,output_filename,args)


        case 17
            % ## Warning: this case will generate variables in our system,
            % users should not use this unless get approval.

            % generates csv file with every utterance where a
            % keyword was found in the speech transcripts of subjects
            % the output file also includes the timestamps and source camera information for each instance
            word_list = {'assemble','cut','close','drink'};
            word_ids = [1,2,3,4];
            subexpIDs = [58];
            output_filename = fullfile(output_dir,'example_17.csv');
            % optional arguments can be included to change the source
            % camera and alter the timestamp of the generated event clips
            data = query_keywords(subexpIDs, word_list, output_filename);
            varname = 'cevent_speech_action-verbs_demo';
            make_keywords_events(word_list, word_ids, data, varname);

        case 18
            % generates a wordcloud plot for a single subject or all
            % subjects in an experiment
            % size of the words reflects number of times that word was
            % referenced in the transcipt(s)
            subexpID = [1201];
            generate_wordcloud(subexpID,output_dir);
    end
end