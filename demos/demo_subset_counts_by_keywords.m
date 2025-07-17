%%%
% Author: Jingwen Pang
% Date: 7/16/2025
% 
% Description:
% given an excel/csv file with headers, subset row-column/column to match a provided word list.
% 
% Inputs:
% Word matrix file: CSV or Excel format
% Word list: A list of words to align the matrix with
% Flag:
%   1 = Remap both rows and columns # check with input file
%   2 = Remap columns only
% Columns to keep: Additional columns to retain and append to the end of the output
% 
% Output:
% A remapped data where the header aligns exactly with the word list; other words in the input file will be removed.
% If a word in the provided word list is missing in the input data, its column/row will be filled with NaN.
%%%
function demo_subset_counts_by_keywords(option)

output_dir = 'Z:\Jingwen\cooccurance_functions\data'; % make sure you use '' instead of ""
switch option

    case 1
        % count all object names from speech data in one experiment
        % get full version word count matrix for all subjects in exp 15
        subexpIDs = [15];
        output_filename = fullfile(output_dir,'case1_count_all_words.csv');
        count_words_by_subject(subexpIDs,output_filename);

        % extract the object label column
        input_file = output_filename;
        word_list = get_object_label(subexpIDs,1:get_num_obj(subexpIDs)); % get exp 12 object labels
        flag = 2; % 1 - subset both row and col, 2 - col only
        col_to_keep = ''; 
        output_filename = fullfile(output_dir,'case1_count_object_words.csv');
        subset_counts_by_keywords(input_file,word_list,flag,col_to_keep,output_filename);
        

    case 2
        % filtering a word count excel data with speech words + mcdi word list
        %% extract the words when child is attending to toys from exp 12
        subexpID = [12];
        cevent_var = 'cevent_inhand_child'; 
        num_obj = get_num_obj(subexpID);
        category_list = 1:num_obj; % all objects
        output_filename = fullfile(output_dir,'case2_speech_in_child_inhand.csv');
        extract_speech_in_situ(subexpID,cevent_var,category_list,output_filename)
        
        %% count cat - word pair frequency in subject level
        input_csv = output_filename;
        sub_col = 2;
        cat_col = 6;
        utt_col = 8;
        output_excel = fullfile(output_dir,'case2_speech_in_child_inhand_cat_word.xlsx');
        count_cat_word_pair_freq(input_csv,sub_col,cat_col,utt_col,output_excel);
        
        %% filter the subset of words
        input_file = output_excel;
        output_file = fullfile(output_dir,'case2_speech_in_child_inhand_cat_word_filtered.xlsx');
        
        flag = 2; % 1 - subset both row and col, 2 - col only
        col_to_keep = '';
        
        % get word list (speech words + mcdi words)
        % get all the object speech word from mapping file
        num_obj = get_num_obj(subexpID);
        cat_list = [1:num_obj]; % all objects
        labels = get_object_label(subexpID,cat_list)';
        
        map_fileList = dir(fullfile(get_multidir_root,sprintf('experiment_%d',subexpID),'object_word_pairs.xlsx'));
        word_object_mapping_filename = map_fileList.name;
        mapping = readtable(fullfile(map_fileList.folder,word_object_mapping_filename));
        
        names = mapping.name;
        N = arrayfun(@(k) sum(arrayfun(@(j) isequal(names{k}, names{j}), 1:numel(names))), 1:numel(names));
        unique_naming = names(N==1);
        
        % get all the words from mcdi word list
        mcdi_wordlist_file = fullfile(get_multidir_root,'MCDI_wordlist.csv');
        mcdi_wordlist = readtable(mcdi_wordlist_file);
        mcdi_words = mcdi_wordlist.item_definition;
        
        % remove repeated words and merge speech words with mcdi words
        mcdi_words(ismember(mcdi_words, unique_naming)) = [];
        mcdi_words = unique(mcdi_words);
        word_list = [unique_naming;mcdi_words];
        
        subset_counts_by_keywords(input_file, word_list, flag, col_to_keep, output_file);

    case 3
        % filtering a word count csv data with speech words + mcdi word list

        %% extract the words when child is attending to toys from exp 15
        subexpID = [15];
        cevent_var = 'cevent_eye_roi_child';
        category_list = 1:get_num_obj(subexpID); % all toys in exp
        output_filename = fullfile(output_dir,'case3_child_looking.csv');
        extract_speech_in_situ(subexpID,cevent_var,category_list,output_filename)
        
        %% count word - word pair frequency in subject level
        input_csv = fullfile(output_dir,'case3_child_looking.csv');
        utt_col = 8;
        group_col = 2; % sub id column in this case
        group_label = 'subject'; % group in subject for each individual sheet
        output_folder = fullfile(output_dir,'case3_child_looking_word-word_subject');
        count_word_word_pair_freq(input_csv, utt_col, group_col, group_label, output_folder)
        
        %% filter the subset of words
        input_file = fullfile(output_folder,'exp_15_all-subject.csv');
        output_file = fullfile(output_dir,'case3_child_looking_word-word_subject.csv');
        
        flag = 1; % 1 - subset both row and col, 2 - col only
        col_to_keep = 'word_freq'; % keep word frequency column, append at the end of output file
        
        % get word list (speech words + mcdi words)
        % get all the object speech word from mapping file
        num_obj = get_num_obj(subexpID);
        cat_list = [1:num_obj]; % all objects
        labels = get_object_label(subexpID,cat_list)';
        
        map_fileList = dir(fullfile(get_multidir_root,sprintf('experiment_%d',subexpID),'object_word_pairs.xlsx'));
        word_object_mapping_filename = map_fileList.name;
        mapping = readtable(fullfile(map_fileList.folder,word_object_mapping_filename));
        
        names = mapping.name;
        N = arrayfun(@(k) sum(arrayfun(@(j) isequal(names{k}, names{j}), 1:numel(names))), 1:numel(names));
        unique_naming = names(N==1);
        
        % get all the words from mcdi word list
        mcdi_wordlist_file = fullfile(get_multidir_root,'MCDI_wordlist.csv');
        mcdi_wordlist = readtable(mcdi_wordlist_file);
        mcdi_words = mcdi_wordlist.item_definition;
        
        % remove repeated words and merge speech words with mcdi words
        mcdi_words(ismember(mcdi_words, unique_naming)) = [];
        mcdi_words = unique(mcdi_words);
        word_list = [unique_naming;mcdi_words];
        
        subset_counts_by_keywords(input_file, word_list, flag, col_to_keep, output_file);
        

end