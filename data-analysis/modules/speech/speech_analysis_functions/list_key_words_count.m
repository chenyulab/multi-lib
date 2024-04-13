%%%
% Author: Jane Yang
% Last Modifier: 4/12/2024
% This function returns a CSV file containing the frequency of each word
% appeared in the subjects.
% 
% Input: a list of keywords, subID or expID, output_filename
% Output: a subset of summary word count table of all subjects, containing
%         frequency of keywords. A .CSV file will be generated based on 
%         keywords' summary word count table.
%%%

function sub_list = list_key_words_count(keywords_list,subexpID,output_filename)
    summary_filename = 'summary_word_count_table.csv';
    wordCountTable = get_word_count_matrix(subexpID,summary_filename);

    % check for keywords appeared in the summary table
    sub_list = wordCountTable(ismember(wordCountTable.Word,keywords_list),:);

    writetable(sub_list,output_filename);
end