%%%
% Author: Melina Knabe
% Last Modifier: 10/07/2024
% Demo function for a suite of speech analysis functions.

%% Required Arguments (for most functions)
% word_list
%                           -- a list of target words that should be queried/counted
% subexpID
%                           -- integer array, list of subjects or experiments
% output_filename
%                           -- full path or relative path of where to save the .csv file
%% Optional Arguments (for query_keywords - case 4)
% args.cam                   -- the source camera the event clips use,
%                            -- default is cam07 (child's view)
%
% args.whence                -- string, 'start', 'end', or 'startend'
%                            -- this parameter, when combined with args.interval, vallows you to shift the args.cevent_name window times by a certain amount.
%                            -- the shift can be respect to the start, end, or full event.
%                                   
% args.interval              --  array of 2 numbers, [t1 t2], where t1 and t2 refer to the offset to apply in each args.cevent_name window times.
%                            --  e.g., [-5 1] and whence = 'start', then we take the onset of each cevent and add -5 seconds to get new onset. Likewise, we add 1 second to onset to get new offset.
%                            --  therefore, if the original event was [45 55], then
%                                if args.whence = 'start', then new event is [40 46]
%                                if args.whence = 'end', then new event is [50 56]
%                                if args.whence = 'startend', then new event is [40 56]

function demo_speech_analysis_functions(option)
    switch option
        case 1
            % generates csv file with a word count matrix for individual subjects
            % each column is a subject, each row is a word, and the cells
            % display the total number of times that word appeared in the transcipt(s)
            subexpID = [1201 1205 1209];
            output_filename = 'Z:\CORE\scheduled_tasks\multi-lib\demo_results\speech_analysis\example1.csv';
            [individuals,common,summary_count] = get_word_count_matrix(subexpID,output_filename);
            
            %individual : a cell array of word count tables for each subject, where each
            %             cell is a subject in subexpID
            %common: a string array of words common to all subjects in
            %        subexpID
            %summary_count: a table of summary word counts for each subject
            %               in subexpID 
            % output csv: the outputted csv file contains the summary_count
            %             table
        case 2
            % generates csv file with a word count matrix for an experiment
            % each column is a subject, each row is a word, and the cells
            % display the total count for that word in the transcipt(s)
            subexpID = [12];
            output_filename = 'Z:\CORE\scheduled_tasks\multi-lib\demo_results\speech_analysis\example2.csv';
            [individuals,common,summary_count] = get_word_count_matrix(subexpID,output_filename);
        case 3
            % generates csv file with a word count matrix across several experiments 
            % each column is a subject, each row is a word, and the cells
            % display the total count for that word in the transcipt(s)
            subexpID = [12 15];
            output_filename = 'Z:\CORE\scheduled_tasks\multi-lib\demo_results\speech_analysis\example3.csv';
            [individuals,common,summary_count] = get_word_count_matrix(subexpID,output_filename);
        case 4
            % generates csv file with every utterance where a
            % keyword was found in the speech transcripts of subjects
            % the output file also includes the timestamps and source camera information for each instance
            % word_list = ["car","doll","rake","bug"];
            word_list = ["car"];
            subexpID = [12];
            output_filename = 'Z:\CORE\scheduled_tasks\multi-lib\demo_results\speech_analysis\example4.csv';
            % optional arguments can be included to change the source
            % camera and alter the timestamp of the generated event clips
            % -- args.cam = [7]
            % -- args.whence = 'start'
            % -- args.interval = [-5 0]
            % returns a table of keywords count
            rtr_table = query_keywords(subexpID, word_list, output_filename);
        case 5
            % uses input file from query_keywords (case 4 above) to 
            % generate a csv file with the target word count matrix by experiment or subject 
            % each row is a subject, each column is a target word
            word_list = ["car","doll","rake","bug"];
            subexpID = [12];
            input_filename = 'Z:\CORE\scheduled_tasks\multi-lib\demo_results\speech_analysis\example4.csv';
            output_filename = 'Z:\CORE\scheduled_tasks\multi-lib\demo_results\speech_analysis\example5.csv';
            list_key_words_count(subexpID, word_list, input_filename, output_filename);
        case 6
            % generates a csv file with subID, age, total session time, a word count for each target word
            % and additional linguistic measures: total speech
            % time, number of tokens (#Token), number of unique words (#UniqueWord), 
            % number of utterances (#Utterance), number of nouns, verbs, adjectives (#Noun, #Verb, #Adjective), 
            % type/token ratio, mean utterance length (sec), and mean utterance length (in tokens)
            subexpIDs = [12];
            keywords_list = ["car"];
            output_filename = 'Z:\CORE\scheduled_tasks\multi-lib\demo_results\speech_analysis\example6.csv';
            rtr_table = make_linguistic_measures(subexpIDs, keywords_list, output_filename);
        case 7
            % generates a wordcloud plot for a single subject or all
            % subjects in an experiment
            % size of the words reflects number of times that word was
            % referenced in the transcipt(s)
            subexpID = [1201];
            output_dir = 'Z:\CORE\scheduled_tasks\multi-lib\demo_results\speech_analysis';
            generate_wordcloud(subexpID,output_dir);
        case 8
            % generates csv file with every utterance where a
            % keyword was found in the speech transcripts of subjects
            % the output file also includes the timestamps and source camera information for each instance
            word_list = {'assemble','cut','close','drink','eat','get','grab','look','make','move','open','put','reach','rip','scoop','screw','spread','try','twist','wipe'};
            subexpID = [58 353];
            output_filename = 'Z:\CORE\scheduled_tasks\multi-lib\demo_results\speech_analysis\example8.csv';
            % optional arguments can be included to change the source
            % camera and alter the timestamp of the generated event clips
            data = query_keywords(subexpID, word_list, output_filename);
            word_ids = [1:length(word_list)];
            varname = 'cevent_speech_action-verbs';
            make_keywords_events(word_list, word_ids, data, varname);
        case 9
            % in some cases we want to use make_keywords_event directly, we
            % can load the csv data first
            word_list = {'assemble','cut','close','drink','eat','get','grab','look','make','move','open','put','reach','rip','scoop','screw','spread','try','twist','wipe'};
            word_ids = [1:length(word_list)];
            data = readtable('Z:\CORE\scheduled_tasks\multi-lib\demo_results\speech_analysis\example8.csv');
            varname = 'cevent_speech_action-verbs';
            make_keywords_events(word_list, word_ids, data, varname);




    end
end