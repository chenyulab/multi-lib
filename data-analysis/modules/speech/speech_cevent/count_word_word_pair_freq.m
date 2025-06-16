%%%
% Author: Jingwen Pang
% Date: 6/16/2025
% 
% This function processes an instance-level speech file and a specified utterance column. It reads all utterances and constructs an n × (n + 2) frequency matrix, where:
% n + 1 counts individual word frequencies.
% n + 2 counts word pair co-occurrence frequencies.
% It outputs:
% An overall sheet with aggregated results.
% Subject-level sheets.
% 
% Example call:
% input_csv = 'example_7.csv';
% utt_col = 8;
% output_excel = 'example_7_word_word.xlsx';
% count_word_word_pair_freq(input_csv, utt_col, output_excel)
%%%
function count_word_word_pair_freq(input_csv, utt_col, output_excel)

output_file = output_excel;

data = readtable(input_csv);

all_text = strjoin(table2cell(data(:,utt_col)),' ');
all_text = erase(all_text, ';');
all_text = regexprep(all_text, '\s+', ' ');
all_text = strtrim(all_text);

all_words = split(all_text, ' ');
unique_words = unique(all_words);


% initialize freq table, overall freq matrix
freq_table = {};
overall_matrix = zeros(length(unique_words),length(unique_words) +2);

% set up sheet id
% row_id = 1 : size(data,1);
sheet_list = [0];

% go through each row count for overall matrix
for i = 1:size(data,1)
    sheet_idx = 1 + i;
    indiv_matrix = zeros(length(unique_words),length(unique_words) +2);

    utterance = data{i,utt_col};

    if isempty(utterance) 
        continue;
    end

    % expand utterance into word list
    utterance = erase(utterance, ';');
    utterance = regexprep(utterance, '\s+', ' ');
    utterance = strtrim(utterance);
    word_list = split(utterance);

    unique_words_list = unique(word_list);
    word_pairs = nchoosek(unique_words_list,2);

    % count word pair
    for j = 1:size(word_pairs,1)
        word1 = word_pairs{j,1};
        word2 = word_pairs{j,2};

        word_idx1 = find(strcmp(unique_words,word1));
        word_idx2 = find(strcmp(unique_words,word2));

        overall_matrix(word_idx1,word_idx2) = overall_matrix(word_idx1,word_idx2) + 1;
        overall_matrix(word_idx2,word_idx1) = overall_matrix(word_idx2,word_idx1) + 1;      

        % count total word pair
        overall_matrix(word_idx1,length(unique_words)+2) = overall_matrix(word_idx1,length(unique_words)+2) + 1;
    end

    % count word freq alone
    for j = 1:length(word_list)
        word = word_list{j};
        word_idx = find(strcmp(unique_words,word));

        overall_matrix(word_idx,length(unique_words)+1) = overall_matrix(word_idx,length(unique_words)+1) + 1;
        % indiv_matrix(word_idx,length(unique_words)+1) = indiv_matrix(word_idx,length(unique_words)+1) + 1;
    end

    freq_table{sheet_idx} = word_list;
    
end


% Rebuild headers and table
headers = [{'words'}, unique_words',{'word_freq','word_pair_freq'}];
overall_table = cell2table(horzcat(unique_words, num2cell(overall_matrix)), "VariableNames", headers);

freq_table{1} = overall_table;

% Extract the word frequency column (last -1 column)
word_freqs = overall_matrix(:, end-1);  % second-to-last column is word_freq

% Sort indices by descending frequency
[~, sort_idx] = sort(word_freqs, 'descend');

% Reorder everything based on sorted frequency
sorted_words = unique_words(sort_idx);
sorted_matrix = overall_matrix(sort_idx, sort_idx);  % sort the n x n part
sorted_word_freq = word_freqs(sort_idx);
sorted_word_pair_freq = overall_matrix(sort_idx, end);  % last column

% Rebuild full matrix with word_freq and word_pair_freq columns
sorted_overall_matrix = [sorted_matrix, sorted_word_freq, sorted_word_pair_freq];

% Rebuild headers and table
headers = [{'words'}, sorted_words', {'word_freq','word_pair_freq'}];
overall_table = cell2table(horzcat(sorted_words, num2cell(sorted_overall_matrix)), "VariableNames", headers);

% Store back into the first sheet
freq_table{1} = overall_table;


for i = 1:size(data, 1)
    disp(i + 1)  % to match freq_table sheet index

    utterance = data{i, utt_col};

    if isempty(utterance)
        % empty sheet
        continue;
    end

    % Initialize matrix
    indiv_matrix = zeros(length(unique_words), length(unique_words) + 2);

    % Clean and split the utterance
    utterance = erase(utterance, ';');
    utterance = regexprep(utterance, '\s+', ' ');
    utterance = strtrim(utterance);
    word_list = split(utterance);

    % Get unique words in this utterance
    unique_words_list = unique(word_list);
    if length(unique_words_list) > 1

        word_pairs = nchoosek(unique_words_list, 2);
    
        % Count word pairs
        for j = 1:size(word_pairs, 1)
            word1 = word_pairs{j, 1};
            word2 = word_pairs{j, 2};
    
            idx1 = find(strcmp(unique_words, word1));
            idx2 = find(strcmp(unique_words, word2));
    
            indiv_matrix(idx1, idx2) = indiv_matrix(idx1, idx2) + 1;
            indiv_matrix(idx2, idx1) = indiv_matrix(idx2, idx1) + 1;
    
            indiv_matrix(idx1, end) = indiv_matrix(idx1, end) + 1;  % word_pair_freq
        end
    end

    % Count individual word freq
    for j = 1:length(word_list)
        word = word_list{j};
        idx = find(strcmp(unique_words, word));
        indiv_matrix(idx, end-1) = indiv_matrix(idx, end-1) + 1;  % word_freq
    end

    % Sort matrix
    sorted_indiv_matrix = indiv_matrix(sort_idx, sort_idx);
    sorted_word_freq = indiv_matrix(sort_idx, end-1);
    sorted_word_pair_freq = indiv_matrix(sort_idx, end);

    sorted_indiv_matrix_full = [sorted_indiv_matrix, sorted_word_freq, sorted_word_pair_freq];

    % Build table
    indiv_table = cell2table(horzcat(sorted_words, num2cell(sorted_indiv_matrix_full)), "VariableNames", headers);
    freq_table{i+1} = indiv_table;
    sheet_list = [sheet_list,i + 1];
end

% Delete existing file to remove default Sheet1
if exist(output_file, 'file')
    delete(output_file);
    fprintf('Deleted existing file: %s\n', output_file);
end

for i = 1:length(freq_table)
    data = freq_table{i};
    sheet_id = sheet_list(i);

    % Create sheet name
    if sheet_id == 0
        sheetName = 'overall';
    else
        sheetName = sprintf('%d', sheet_id);
    end

    % Debug info
    fprintf('Writing to sheet: %s\n', sheetName);

    % Write only if data is non-empty
    if ~isempty(data) && width(data) > 0
        writetable(data, output_file, ...
            'Sheet', sheetName);  % R2020a+
    else
        warning('Sheet %s is empty. Skipping.', sheetName);
    end
end

end