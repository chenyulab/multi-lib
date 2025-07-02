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
%%%
function freq_table = count_word_word_pair_freq(input_csv, utt_col, group_col, group_label, output_dir, args)

% check if there is optional parameters
    if ~exist('args', 'var') || isempty(args)
        args = struct([]);
    end

    if isfield(args, 'keep_stopwords')
        keep_stopwords = args.keep_stopwords;
    else
        keep_stopwords = 0;
    end

    if isfield(args, 'exp_col')
        exp_col = args.exp_col;
    else
        exp_col = 1;
    end


    stopWords_list = stopWords;

    delete(gcp('nocreate'));
    parpool('Threads');
    
    output_folder = output_dir;
    
    data = readtable(input_csv);

    % get exp ids 
    exp_ids = unique(data{:,exp_col});

    if length(exp_ids) > 1
        warning('Warning: Multiple experiment IDs detected.')
    end

    % check if the data is grounped by subject level or object level
    if strcmp(group_label,'subject')
        sub_ids = data{:,group_col};
        exp_labels = strjoin(string(unique(sub2exp(sub_ids))),',');
        main_sheetname = sprintf('exp_%s_all-subject',exp_labels);

        group_ids = unique(sub_ids);
    elseif strcmp(group_label, 'category')
        main_sheetname = sprintf('exp_%d_all-category',exp_ids);

        group_ids = unique(data{:,group_col});

    else
        error("please provide a valid cat label: 'subject' or 'category' ")
    end
    
    all_text = strjoin(table2cell(data(:,utt_col)),' ');
    all_text = erase(all_text, ';');
    all_text = regexprep(all_text, '\s+', ' ');
    all_text = strtrim(all_text);
    
    all_words = split(all_text, ' ');
    unique_words = unique(all_words);
    
    if ~keep_stopwords
        unique_words = setdiff(unique_words, stopWords_list);
    end
    
    unique_words = cellstr(unique_words);
    
    
    % initialize freq table, overall freq matrix
    freq_table = {};
    overall_matrix = zeros(length(unique_words),length(unique_words) +2);
    
    % set up sheet id
    % row_id = 1 : size(data,1);
    sheet_list = zeros(1, size(data, 1)+1);
    
    % precompute a mapping from word
    word2idx = containers.Map(unique_words, 1:length(unique_words));
    
    % go through each row count for overall matrix
    for i = 1:size(data,1)
    
        utterance = data{i,utt_col};
    
        if isempty(utterance) || isempty(utterance{1})
            continue;
        end
    
        % expand utterance into word list
        utterance = erase(utterance, ';');
        utterance = regexprep(utterance, '\s+', ' ');
        utterance = strtrim(utterance);
        word_list = split(utterance);
    
        unique_words_list = unique(word_list);
    
        if ~keep_stopwords
            unique_words_list = setdiff(unique_words_list, stopWords_list);
        end
    
        idx_list = cellfun(@(w) word2idx(w), unique_words_list);
        
        for j = 1:length(unique_words_list)
            target_word = unique_words_list{j};
            word_idx_local = strcmp(word_list, target_word);
            word_idx_global = idx_list(j);
            target_freq = sum(word_idx_local);
        
            % Self-pair (diagonal)
            overall_matrix(word_idx_global, word_idx_global) = ...
                overall_matrix(word_idx_global, word_idx_global) + target_freq - 1;
        
            % Count single word
            overall_matrix(word_idx_global, end-1) = ...
                overall_matrix(word_idx_global, end-1) + target_freq;
        
            % Word pair co-occurrence (vectorized)
            co_idx = idx_list;
            co_idx(j) = [];  % exclude self
            overall_matrix(word_idx_global, co_idx) = ...
                overall_matrix(word_idx_global, co_idx) + target_freq;
        
            % Update word_pair_freq
            total_pair_freq = target_freq * length(co_idx) + (target_freq - 1);
            overall_matrix(word_idx_global, end) = ...
                overall_matrix(word_idx_global, end) + total_pair_freq;
        end
        
    end
    
    
    % Rebuild headers and table
    headers = [{'words_col'}, unique_words',{'word_freq','word_pair_freq'}];
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
    headers = [{'words_col'}, sorted_words', {'word_freq','word_pair_freq'}];
    overall_table = cell2table(horzcat(sorted_words, num2cell(sorted_overall_matrix)), "VariableNames", headers);
    
    % Store back into the first sheet
    freq_table{1} = overall_table;
    
    parfor i = 1:size(group_ids, 1)
        disp(i + 1)  % to match freq_table sheet index
        sheet_list(i+1) = group_ids(i);

        % Initialize matrix
        indiv_matrix = zeros(length(unique_words), length(unique_words) + 2);

        sub_data = data(data{:,group_col} == group_ids(i),:);

        for s = 1:size(sub_data,1)
            utterance = sub_data{s, utt_col};  
        
            if isempty(utterance) || isempty(utterance{1})
                % empty sheet
                continue;
            end
        
            % Clean and split the utterance
            utterance = erase(utterance, ';');
            utterance = regexprep(utterance, '\s+', ' ');
            utterance = strtrim(utterance);
            word_list = split(utterance);
        
            % Get unique words in this utterance
            unique_words_list = unique(word_list);
        
            if ~keep_stopwords
                unique_words_list = setdiff(unique_words_list, stopWords_list);
            end
        
            idx_list = cellfun(@(w) word2idx(w), unique_words_list);
            
            for j = 1:length(unique_words_list)
                target_word = unique_words_list{j};
                word_idx_local = strcmp(word_list, target_word);
                word_idx_global = idx_list(j);
                target_freq = sum(word_idx_local);
            
                % Self-pair (diagonal)
                indiv_matrix(word_idx_global, word_idx_global) = ...
                    indiv_matrix(word_idx_global, word_idx_global) + target_freq - 1;
            
                % Count single word
                indiv_matrix(word_idx_global, end-1) = ...
                    indiv_matrix(word_idx_global, end-1) + target_freq;
            
                % Word pair co-occurrence (vectorized)
                co_idx = idx_list;
                co_idx(j) = [];  % exclude self
                indiv_matrix(word_idx_global, co_idx) = ...
                    indiv_matrix(word_idx_global, co_idx) + target_freq;
            
                % Update word_pair_freq
                total_pair_freq = target_freq * length(co_idx) + (target_freq - 1);
                indiv_matrix(word_idx_global, end) = ...
                    indiv_matrix(word_idx_global, end) + total_pair_freq;
            end
        end
    
        % Sort matrix
        sorted_indiv_matrix = indiv_matrix(sort_idx, sort_idx);
        sorted_word_freq = indiv_matrix(sort_idx, end-1);
        sorted_word_pair_freq = indiv_matrix(sort_idx, end);
    
        sorted_indiv_matrix_full = [sorted_indiv_matrix, sorted_word_freq, sorted_word_pair_freq];
    

        
        % Build table
        indiv_table = cell2table(horzcat(sorted_words, num2cell(sorted_indiv_matrix_full)), "VariableNames", headers);
        freq_table{i+1} = indiv_table;
        
    end
    
    % Create the folder if it does not exist
    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
        fprintf('Created folder: %s\n', output_folder);
    end
    
    % Loop through freq_table and save each to a separate CSV file
    for i = 1:length(freq_table)
        data = freq_table{i};
        sheet_id = sheet_list(i);
    
        % Create file name
        if sheet_id == 0
            fileName = sprintf('%s.csv',main_sheetname);
        else
            if strcmp(group_label, 'category')
                cat_name = get_object_label(exp_ids,sheet_id);
                fileName = sprintf('%s_%d_%s.csv', group_label, sheet_id, cat_name);
            else
                fileName = sprintf('%s_%d.csv', group_label, sheet_id);
            end
        end
    
        filePath = fullfile(output_folder, fileName);
    
        % Debug info
        fprintf('Writing to file: %s\n', filePath);
    
        % Write only if data is non-empty
        if ~isempty(data) && width(data) > 0
            writetable(data, filePath);
        else
            warning('Data for sheet_id %d is empty. Skipping.', sheet_id);
        end
    end

end