%%%
% Author: Jane Yang
% Last Modifier: 3/15/2023
% This function returns a CSV file containing the frequency of each word
% appeared in the subjects.
% 
% Input: a list of keywords, subID or expID, output_filename
% Output: a subset of summary word count table of all subjects, containing
%         frequency of keywords. A .CSV file will be generated based on 
%         keywords' summary word count table.
%%%

function sub_list = list_key_words_count(keywords_list,subexpID,output_filename)
    summary_filename = 'summary_word_count.csv';
    [~,~,summary_count] = get_word_count_matrix(subexpID,summary_filename);
    disp(class(summary_count));

    sub_list = summary_count(ismember(summary_count.word,keywords_list),:);

    writetable(sub_list,output_filename);
end