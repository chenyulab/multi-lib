%%%
% Author: Jane Yang
% Last Modifier: 3/28/2023
% Demo function of a suite of speech analysis functions.
%%%

function demo_speech_analysis_functions(option)
    switch option
        case 1
            % get an individuals word count matrix for subject 1202,1205,1209
            subexpID = [1201 1205 1209];
            output_filename = '1201_1205_1209_word_count.csv';

            % returns a cell array of individual word count table, a table
            % of common words among three subjects, and an individuals word
            % count table
            [individuals,common,summary_count] = get_word_count_matrix(subexpID,output_filename);
        case 2
            % get an individuals word count matrix for all subjects in exp12
            subexpID = [12];
            output_filename = 'exp12_word_count.csv';

            % returns a cell array of individual word count table, a table
            % of common words among three subjects, and an individuals word
            % count table
            [individuals,common,summary_count] = get_word_count_matrix(subexpID,output_filename);
        case 3
            % get an individuals word count matrix for all subjects in exp12,15
            subexpID = [12 15];
            output_filename = 'exp12_exp15_word_count.csv';

            % returns a cell array of individual word count table, a table
            % of common words among three subjects, and an individuals word
            % count table
            [individuals,common,summary_count] = get_word_count_matrix(subexpID,output_filename);
        case 4
            % get a word count matrix of keywords for all subjects in exp12
            keywords_list = ["car","doll","rake","bug"];
            subexpID = [12];
            output_filename = 'exp12_word_count-car-doll-rake-bug.csv';

            % returns a table of keywords count
            sub_list = list_key_words_count(keywords_list,subexpID,output_filename);
        case 5
            % get a speech summary table for exp12
            subexpID = [12];
            target_words = ["car" "block" "pot"];
            output_filename = 'exp12_summary-car-block-pot.csv';

            summary_mtr = word_summary(subexpID,target_words,output_filename);
        case 6
            % generate a wordcloud figure for subject 1201
            subexpID = [1201];
            output_dir = '.';

            generate_wordcloud(subexpID,output_dir);
    end
end