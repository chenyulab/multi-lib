%%%
%
% This function takes text instances and gives the count of each word in
% the instance. It also computes the number of tokens, unique words , utterances,
% nouns, verbs, and adjectives in the instance. 
%
% Author: Elton Martinez
% Modifier: 
% Last modified: 4/22/2025
%
% Input parameters:
%   - file_in = path the input file
%   
%   - file_out = desired name of the output file, csv or txt endings are
%                valid 
%
%   - key_words = array of key words []. If not empty only the count of these
%                 will be computed, else all words will be counted. For empty
%                 case, we just pass an empty [];
%
%   - extraStopWords = cell array of words to excluded, if non then just
%                      pass an empty {}
%
%   - text_col_num = the numeric location of the text column relative to the 
%                    input file, note if just passing one column it will break 
%
%   - id_col_nums = the numeric location of the instance identification
%                  column. Eg if subject level then the subjects column
%                  *by default, users can input a single column number can
%                  it will be assigned to 'id' column at beigining
%                  *if user want to keep multiple columns and the header names in the sheet,
%                  they need to define in this way:
%                  {'header_name_1', column_number_1, 'header_name_2', column_number_2}
%                  e.g. {'subID', 2, 'objID', 3}
%
%

function data = count_word_speech_in_situ(file_in, file_out, key_words, extraStopWords, text_col_num, id_col_nums)
    
    % read table
    df = readtable(file_in, delimiter=",");

    % get the vocabulary 
    if isempty(key_words)
        unqWords = {};

        for i = 1:height(df)
            temp_vocab = get_utterance_word_frequency(df{i,text_col_num}{1}, extraStopWords);
            unqWords = vertcat(unqWords, keys(temp_vocab));
        end
        unqWords = unqWords'; % transpose the column to row
        unique_tokens = unique(unqWords);
    else
        unique_tokens = unique(key_words);
    end
    
    % prealocate the table 
    varNames =  string(unique_tokens);
    word_summary_vars = ["#Token","#UniqueWord","#Utterance","#Noun","#Verb","#Adjective"];
    % check id_col_nums
    if isnumeric(id_col_nums) && isscalar(id_col_nums)
        varNames = horzcat("id", word_summary_vars, varNames);
    elseif iscell(id_col_nums)
        is_valid = mod(numel(id_col_nums), 2) == 0;
        orig_headers = {};
        if is_valid
            for i = 1:2:length(id_col_nums)
                orig_headers = [orig_headers,id_col_nums{i}];
            end
            varNames = horzcat(orig_headers, word_summary_vars, varNames);
        else
            error("check your input formating: {'header_name_1', column_number_1, 'header_name_2', column_number_2}")
        end
    else
        error('please input either a single number or a cell array')
    end

    m = numel(varNames);
    
    varTypes = cell(1, m);
    varTypes(1) = {'string'};
    varTypes(2:end) = {'double'};
    
    n = height(df);
    data = table('Size', [n m], 'VariableTypes',varTypes,'VariableNames', varNames);
    
    % check id_col_nums
    if isnumeric(id_col_nums) && isscalar(id_col_nums)
        % add data to csv 
        data.id = df{:,id_col_nums};
    elseif iscell(id_col_nums)
        is_valid = mod(numel(id_col_nums), 2) == 0;
        if is_valid
            for i = 1:2:length(id_col_nums)
                data.(id_col_nums{i}) = df{:,id_col_nums{i+1}};
            end
        else
            error("check your input formating: {'header_name_1', column_number_1, 'header_name_2', column_number_2}")
        end
    else
        error('please input either a single number or a cell array')
    end
     
    % get the counts for each instance & update the table 
    for i = 1:n
       % preprocess utterance 
       temp_utterance = df{i,text_col_num}{1};
       % not sure if this line is needed.. might not be most efficient 
       temp_tokens = regexprep(temp_utterance, ";", " ");
       temp_tokens = split(temp_utterance, " ");
       % get rid of empty tokens 
       mask = cellfun(@(x) ~isempty(x), temp_tokens);
       temp_tokens = temp_tokens(mask);
       
       % ignore empty words 
       words = numel(temp_tokens);
       if words == 0 || isempty(temp_tokens{1})
        continue 
       end
        
       % get instance utterances 
       summary_vec = get_utterance_word_summary(temp_utterance);
       
       for z = 1:numel(word_summary_vars)
           data{i, word_summary_vars{z}} = summary_vec(z);
       end

       % get the counts for instance 
       for j = 1:words
           target = temp_tokens{j};
           % check if word is in the vocab, might have since the vocab
           % filters stop words 
           if sum(ismember(unique_tokens,target)) == 1
                data{i, target} = data{i, target} + 1; 
           end
       end
    end
    
    % save file 
    writetable(data,file_out);
    fprintf("Saved data under %s\n", file_out)
end