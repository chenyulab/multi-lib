%%%
% Author: Jingwen Pang
% Date: 8/13/2025
% 
% This function processes an instance-level speech file and a specified utterance column. It reads all utterances and constructs an n × (n + 2) frequency matrix, where:
% n + 1 counts individual word frequencies.
% n + 2 counts word pair co-occurrence frequencies.
% It outputs:
% An overall sheet with aggregated results.
% Subject-level sheets.
% 
%%%
function freq_table = count_word2word_freq(input_csv, utt_col, group_col, group_label, output_dir, args)

% check if there is optional parameters
    if ~exist('args', 'var') || isempty(args)
        args = struct([]);
    end

    if isfield(args, 'exp_col')
        exp_col = args.exp_col;
    else
        exp_col = 2;
    end

    stopWords_list = stopWords;

    delete(gcp('nocreate'));
    parpool('Threads');
    
    output_folder = output_dir;
    
    data = readtable(input_csv);

    % get exp ids 
    exp_id = unique(data{:,exp_col});

    if length(exp_id) > 1
        error('Error: Multiple experiment IDs detected.')
    end

    all_word_list = get_exp_word_list(exp_id);
    

    % check if the data is grounped by subject level or object level
    if strcmp(group_label,'subject')
        sub_ids = data{:,group_col};
        exp_labels = strjoin(string(unique(sub2exp(sub_ids))),',');
        main_sheetname = sprintf('exp_%s_all-subject',exp_labels);

        group_ids = unique(sub_ids);
    elseif strcmp(group_label, 'category')
        main_sheetname = sprintf('exp_%d_all-category',exp_id);

        group_ids = unique(data{:,group_col});

    else
        error("please provide a valid cat label: 'subject' or 'category' ")
    end

    % -- Vocabulary (IDs + words) --
    all_word_list = get_exp_word_list(exp_id);
    unique_words = all_word_list(:,2);
    unique_ids   = all_word_list(:,1); %#ok<NASGU>
    V = numel(unique_words);

    % -- Map word -> index --
    word2idx = containers.Map(unique_words, 1:V);

    % -- Track words we’ve already warned about (to avoid spam) --
    warned_unknown = containers.Map('KeyType','char','ValueType','logical');
    
    
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
        [valid_words_list, valid_idx_list, word_list] = get_valid_tokens(utterance);
        
        % Now loop only through valid words
        for j = 1:length(valid_words_list)
            target_word = valid_words_list{j};
            word_idx_local = strcmp(word_list, target_word);
            word_idx_global = valid_idx_list(j);
            target_freq = sum(word_idx_local);
        
            % Self-pair (diagonal)
            overall_matrix(word_idx_global, word_idx_global) = ...
                overall_matrix(word_idx_global, word_idx_global) + target_freq - 1;
        
            % Count single word
            overall_matrix(word_idx_global, end-1) = ...
                overall_matrix(word_idx_global, end-1) + target_freq;
        
            % Word pair co-occurrence
            co_idx = valid_idx_list;
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
    
    % Store back into the first sheet
    freq_table{1} = overall_table;
    
    for i = 1:size(group_ids, 1)
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
        
            % expand utterance into word list
            [valid_words_list, valid_idx_list, word_list] = get_valid_tokens(utterance);
            
            if isempty(valid_idx_list)
                continue;
            end

            % Accumulate counts for each valid target word
            for j = 1:numel(valid_words_list)
                target_word = valid_words_list{j};
                word_idx_local = strcmp(word_list, target_word);
                word_idx_global = valid_idx_list(j);
                target_freq = sum(word_idx_local);

                % Self-pair (diagonal)
                indiv_matrix(word_idx_global, word_idx_global) = ...
                    indiv_matrix(word_idx_global, word_idx_global) + max(target_freq - 1, 0);

                % Single word frequency
                indiv_matrix(word_idx_global, end-1) = ...
                    indiv_matrix(word_idx_global, end-1) + target_freq;

                % Co-occurrence with others
                co_idx = valid_idx_list;
                co_idx(j) = [];
                if ~isempty(co_idx)
                    indiv_matrix(word_idx_global, co_idx) = ...
                        indiv_matrix(word_idx_global, co_idx) + target_freq;
                end

                % Total pair freq
                total_pair_freq = target_freq * numel(co_idx) + max(target_freq - 1, 0);
                indiv_matrix(word_idx_global, end) = ...
                    indiv_matrix(word_idx_global, end) + total_pair_freq;
            end
        end
        
        % Build table
        % indiv_table = cell2table(horzcat(sorted_words, num2cell(sorted_indiv_matrix_full)), "VariableNames", headers);
        indiv_table = cell2table(horzcat(unique_words, num2cell(indiv_matrix)), "VariableNames", headers);
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
                cat_name = get_object_label(exp_id,sheet_id);
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



function [valid_words_list, valid_idx_list, word_list_clean] = get_valid_tokens(utt)
        % Clean & split
        utt = erase(utt, ';');
        utt = regexprep(utt, '\s+', ' ');
        utt = strtrim(utt);
        if isempty(utt)
            valid_words_list = {};
            valid_idx_list = [];
            word_list_clean = strings(0,1);
            return;
        end
        word_list_clean = split(utt);

        % Unique tokens in this utterance
        unique_words_list = unique(word_list_clean);

        % Keep only words in vocab; warn once per unknown
        valid_words_list = {};
        valid_idx_list = [];
        for jj = 1:numel(unique_words_list)
            w = unique_words_list{jj};
            if isKey(word2idx, w)
                valid_words_list{end+1} = w; 
                valid_idx_list(end+1) = word2idx(w);
            else
                if ~isKey(warned_unknown, w)
                    warned_unknown(w) = true;
                    warning('Skipping word "%s": not in vocabulary list.', w);
                end
            end
        end
end

end


