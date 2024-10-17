%%%
% Author: Chen Yu
% Editor: Jingwen Pang
% Last updated: 9/27/2024
% This function returns a CSV file containing the frequency of each word
% appeared in the subjects.
%
% Input: 
%       - subID or expID
%       - a list of keywords
%       - inputfile
%           - deriven from query_keyword:
%             a detailed csv containing instances where the target keyword was found in speech transcription.
%       - output_file
%           - output filename
% Output: a subset of summary word count table of all subjects, containing
%         frequency of keywords. A .CSV file will be generated based on
%         keywords' summary word count table.
%
% example call: list_keyword_count([58 353],{'assemble','reach', 'close','cut','rip','drink','eat','get', 'grab','open', 'screw', 'twist', 'put','spread', 'move','scoop','make','look', 'try', 'wipe'},'Z:\Jingwen\list_keyword_count\pbj_verbs-all.csv','summary_word_count.csv')
%%%
function list_key_words_count(exp_ids,word_list,input_file,output_file)

data = readtable(input_file);

sub_list = list_subjects(exp_ids);
results = zeros(length(sub_list),length(word_list));

for s = 1 : length(sub_list)
    idx = find(data.subID==sub_list(s)); 
    sub_data = data(idx,:); 

    for w = 1 : length(word_list)
        target_word = word_list{w}; 

        sub_word_data = sub_data(strcmp(sub_data.word1,target_word),:);
        if isempty(sub_word_data)
              results(s,w) = 0;
        else
            for i = 1:size(sub_word_data,1)
                results(s,w) = results(s,w)+count(sub_word_data.utterances1(i),target_word);
            end
        end
    end
end

headers = ['subID',word_list];
results = horzcat(sub_list,results);

table = array2table(results);
table.Properties.VariableNames = headers;

writetable(table,output_file);
end