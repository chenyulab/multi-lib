%%%
% Author: Jingwen Pang
% Date: 6/16/2025
% 
% This function takes a speech file (any level), and the column indices for category ID, subject ID, and utterance. It generates a category × unique word matrix:
% Each cell indicates how often a word appears with an object.
% Outputs include an overall sheet and row-level sheets, grouped according to input csv.
% 
% example call:
% input_csv = 'example_7.csv';
% sub_col = 2;
% cat_col = 6;
% utt_col = 8;
% output_excel = 'example_7_cat_word.xlsx';
% count_cat_word_pair_freq(input_csv,sub_col,cat_col,utt_col,output_excel)
%% 
function count_cat_word_pair_freq(input_csv,sub_col,cat_col,utt_col,output_excel)

output_file = output_excel;

data = readtable(input_csv);

% find expID base on the subID_list
sub_list = table2array(unique(data(:,sub_col)));
expID = unique(sub2exp(sub_list));

if length(expID) > 1 || isempty(expID)
    error('please make sure all the subjects come from a single experiment')
end

num_obj = get_num_obj(expID);
cat_list = [1:num_obj];
labels = get_object_label(expID,cat_list)';

% get naming labels
if ismember(expID,[77,78,79])
    map_fileList = dir(fullfile(get_multidir_root,'experiment_77','exp77_object_word_pairs.xlsx'));
elseif ismember(expID,80)
    map_fileList = dir(fullfile(get_multidir_root,sprintf('experiment_%d',expID),'exp80_object_word_pairs.xlsx'));
elseif ismember(expID,58)
    map_fileList = dir(fullfile(get_multidir_root,sprintf('experiment_%d',expID),'exp58_object_word_pairs.xlsx'));
else
    map_fileList = dir(fullfile(get_multidir_root,sprintf('experiment_%d',expID),'object_word_pairs.xlsx'));
end

word_object_mapping_filename = map_fileList.name;
mapping = readtable(fullfile(map_fileList.folder,word_object_mapping_filename));

names = mapping.name;
N = arrayfun(@(k) sum(arrayfun(@(j) isequal(names{k}, names{j}), 1:numel(names))), 1:numel(names));
unique_naming = names(N==1);
unique_elements_objID = mapping.obj_id(N==1);

% get all the words
all_text = strjoin(table2cell(data(:,utt_col)),' ');
all_text = erase(all_text, ';');
all_text = regexprep(all_text, '\s+', ' ');
all_text = strtrim(all_text);

all_words = split(all_text, ' ');
unique_words = unique(all_words);


% initialize freq table, overall freq matrix
freq_table = {};
overall_matrix = zeros(length(cat_list),length(unique_words));
sheet_list = [0, sub_list'];


% go through each row count for overall matrix
for i = 1:size(data,1)
    utterance = data{i,utt_col};

    if isempty(utterance) 
        continue;
    end

    cat_idx = find(cat_list == data{i,cat_col});

    if isempty(cat_idx)
        continue;
    end

    % expand utterance into word list
    utterance = erase(utterance, ';');
    utterance = regexprep(utterance, '\s+', ' ');
    utterance = strtrim(utterance);
    word_list = split(utterance);

    for j = 1:length(word_list)
        word = word_list{j};
        word_idx = find(strcmp(unique_words,word));
        % plus one to target position
        overall_matrix(cat_idx, word_idx) = overall_matrix(cat_idx, word_idx) + 1;
    end
    
end


% Filter valid labels
valid_labels = unique_naming(ismember(unique_naming, unique_words));

% Calculate column sums
column_sums = sum(overall_matrix, 1);

% Sort remaining words by frequency
[~, freq_sort_idx] = sort(column_sums, 'descend');
sorted_words = unique_words(freq_sort_idx);

% Remove any word that's already in valid_labels
remaining_words = setdiff(sorted_words, valid_labels, 'stable');

% Concatenate prioritized labels with the rest
final_word_order = [valid_labels', remaining_words'];

% Reorder matrix columns based on final_word_order
[~, final_idx] = ismember(final_word_order, unique_words);
sorted_matrix = overall_matrix(:, final_idx);

% Rebuild headers and table
headers = [{'cat_label'}, final_word_order];
overall_table = cell2table(horzcat(labels, num2cell(sorted_matrix)), "VariableNames", headers);

freq_table{1} = overall_table;

% go through in subject level, count for each subject sheet
for s = 1:length(sub_list)
    disp(sub_list(s));
    sub_id = sub_list(s);
    sheet_idx = find(sheet_list==sub_id);

    % find all unique words for that subject
    sub_data = data(data{:,sub_col}==sub_id,:);

    % initialize sub matrix
    sub_matrix = zeros(length(cat_list),length(unique_words));

    for i = 1:size(sub_data,1)
        utterance = sub_data{i,utt_col};

        if isempty(utterance) 
            continue;
        end

        cat_idx = find(cat_list == sub_data{i,cat_col});

        if isempty(cat_idx)
            continue;
        end

        % expand utterance into word list
        utterance = erase(utterance, ';');
        utterance = regexprep(utterance, '\s+', ' ');
        utterance = strtrim(utterance);
        word_list = split(utterance);

        for j = 1:length(word_list)
            word = word_list{j};
            word_idx = find(strcmp(unique_words,word));
            % plus one to target position
            sub_matrix(cat_idx, word_idx) = sub_matrix(cat_idx, word_idx) + 1;

        end
    end

    % Reorder matrix columns and headers
    sorted_matrix = sub_matrix(:, final_idx);

    sub_table = cell2table(horzcat(labels,num2cell(sorted_matrix)),"VariableNames",headers);    

    freq_table{sheet_idx} = sub_table;

end


% Delete existing file to remove default Sheet1
if exist(output_file, 'file')
    delete(output_file);
    fprintf('Deleted existing file: %s\n', output_file);
end

for i = 1:length(freq_table)
    data = freq_table{i};
    subject_id = sheet_list(i);

    % Create sheet name
    if subject_id == 0
        sheetName = 'overall';
    else
        sheetName = sprintf('%d', subject_id);
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