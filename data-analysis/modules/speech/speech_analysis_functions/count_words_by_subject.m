%%%
% Author: Jane Yang
% Editor: Jingwen Pang
% Last Modifier: 05/09/2025
% This function returns a CSV file containing the frequency of each word
% appeared in the subjects.
% 
% Input: subID or expID, output_filename
% Output: a table of summary word count of all subjects (used for other function).
%         A transposed .CSV file will be generated based on summary word count table.
%%%

function [summary_count] = count_words_by_subject(subexpIDs,output_filename)
    flattened_list = [];
    common = [];
    
    %% generate a list of subjects that have a speech transcription file
    for i = 1:numel(subexpIDs)
        if size(cIDs(subexpIDs(i)),1) == 1
            [all_words,utterances] = parse_speech_trans(cIDs(subexpIDs(i)));
            if size(all_words,1) ~= 0
                flattened_list(end+1,1) = cIDs(subexpIDs(i));
            end
        elseif size(cIDs(subexpIDs(i)),1) > 1
            list = cIDs(subexpIDs(i));
            for j = 1:size(list,1)
                [all_words,utterances] = parse_speech_trans(list(j));
                if size(all_words,1) ~= 0
                    flattened_list(end+1,1) = list(j);
                end
            end
        end
    end

    %% obtain a cell array containing parsed transcription from subject
    for j = 1:size(flattened_list,1)
        % parse speech_transcription .txt file, if exist
        [all_words,utterances] = parse_speech_trans(flattened_list(j));
        
        % get word frequency
        wordCount_table = wordCloudCounts(all_words);
        wordCount_mtr = table2array(wordCount_table);
        
        % sort each word count matrix for easier comparison later
        wordCount_mtr = sortrows(wordCount_mtr);
        
        % append to cell array
        individuals{j} = wordCount_mtr;
    end

    
    %% generate a return word count matrix
    if (size(individuals,2)==1)
        summary_count = individuals{1,1};
    elseif (size(individuals,2)>1)
        % find common words
        common = intersect(individuals{1,1}(:,1),individuals{1,2}(:,1));
        all = [];
        for k = 3:size(individuals,2)
            common = intersect(common,individuals{1,k}(:,1));
            if isempty(common)
                break;
            end
            all = [all;individuals{1,k}(:,1)];
        end
    
        % find a list of all words appeared in all transcriptions
        all = [individuals{1,1}(:,1);individuals{1,2}(:,1);all];
    
        % find a list of words except common words
        diff = setdiff(all,common);
    
        % set a word template for individuals word count matrix
        template = [common;diff];
    
        % construct new word count matrix
        for a = 1:size(individuals,2)
            % initialize frequency
            count = zeros(size(template));
    
            % fill in common words' count
            common_idx = ismember(individuals{1,a}(:,1),common);
            count(1:size(common,1)) = str2double(individuals{1,a}(common_idx,2));
    
            % fill in the rest word counts
            diff_og_idx = ismember(individuals{1,a}(:,1),diff);
            diff_template_idx = ismember(template,setdiff(individuals{1,a}(:,1),common));
    
            count(diff_template_idx) = str2double(individuals{1,a}(diff_og_idx,2));
    
    
            % save to summary matrix
            summary_count(:,a) = count;
        end
    
        summary_count = [template summary_count];
    end

    %% write return matrix to a CSV file
    colNames = {'word'};
    for sub = 1:size(flattened_list,1)
        colNames{end+1} = num2str(flattened_list(sub));
    end

    summary_count = array2table(summary_count,'VariableNames',colNames);

    % don't write to a CSV file if the function is used as an intermediate
    % helper function
    if ~strcmp(output_filename,'')
        % transpose table if write into a csv file
        summary_count_transposed = transpose_table(summary_count);
        writetable(summary_count_transposed,output_filename);
    end
end


function T_transposed = transpose_table(T)
% Transpose a table, assigning valid and unique headers (e.g., Spanish word cloud)

    % Extract subject IDs (from column names)
    subject_list = T.Properties.VariableNames(2:end)';

    % Get word list from first column
    word_list_raw = table2cell(T(:,1))';

    % Convert all to char vectors (in case some are strings)
    word_list_char = cellfun(@char, word_list_raw, 'UniformOutput', false);

    % Ensure valid MATLAB variable names (sanitize accents, symbols, etc.)
    word_list_valid = matlab.lang.makeValidName(word_list_char, 'ReplacementStyle', 'delete');

    % Ensure uniqueness (no duplicate column names)
    word_list_unique = matlab.lang.makeUniqueStrings(word_list_valid, {}, namelengthmax);

    % Create full header row
    header = [{'subID'}, word_list_unique];

    % Transpose data: subject names become first column, rest is data
    data = table2cell(T(:,2:end))';
    full_data = [subject_list, data];

    % Convert to table with cleaned header
    T_transposed = cell2table(full_data, 'VariableNames', header);
end