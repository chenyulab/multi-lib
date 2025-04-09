%%%
% This function take an extracted speech file, expanded speech utterance into
% word level, append category word to each category values, and calculate 
% the word similarity betweem category word and each word in speech utterances.
% 
% input parameter:
%   - input_filename (string)
%       - speech file or grouped speech file, must include exp id, category
%         value columns, and speech utterance column
%   - output_filename (string)
%
%   optional variables:
%       *all the default column number are based on the output file from
%       extract_speech_in_situ
%       - args.expID_col (int)
%           - input file exp id column number
%       - args.subID_col (int)
%           - input file subject id column number, if there is no sub id
%             column, then set it as nan
%       - args.catValue_col (int)
%           - input file category value column number
%       - args.speechWord_col (int)
%           - input file speech word column number
%       - args.stopWords (string cell array)
%           - list of stops words that will be excluded during calculation,
%             the default word list is coming from matlab library 
%       - args.excludeSubjects (int)
%           - list of subjects that will be excluded during analysis
%   
% output file
%   - csv file, categotory word append after cateogry value, similarity
%   score append after expanded speech utterances
% 
% example call:
%   cal_word_similarity('exp_351_transition_cat-2.csv','exp_351_transition_cat-2_similarity.csv')
%%%
function expanded_data = cal_word_similarity(input_filename,output_filename,args)


    if ~exist('args', 'var') || isempty(args)
        args = struct();
    end
    
    % Define column indices with a default if not specified in args
    if ~isfield(args, 'expID_col')
        args.expID_col = 1;
    end
    
    if ~isfield(args, 'subID_col')
        args.subID_col = 2;
    end
    
    if ~isfield(args, 'catValue_col')
        args.catValue_col = 7;
    end
    
    if ~isfield(args, 'speechWord_col')
        args.speechWord_col = 9;
    end
    
    if ~isfield(args, 'stopWords')
        args.stopWords = stopWords;
    end
    
    if ~isfield(args, 'excludeSubjects')
        args.excludeSubjects = [];
    end
    
    % Assign values from args to variables for convenience
    expID_col = args.expID_col;
    subID_col = args.subID_col;
    catValue_col = args.catValue_col;
    speechWord_col = args.speechWord_col;
    stopwords_list = args.stopWords;
    excludeSubjects = args.excludeSubjects;

    table_data = readtable(input_filename);
    headers = table_data.Properties.VariableNames;
    % insert cat word and similarity col followed catValue and speechWord
    headers{speechWord_col} = 'speechWord';
    headers = [headers(1:catValue_col), {'catWord'}, headers(catValue_col+1:end)];
    headers = [headers(1:speechWord_col+1), {'similarity'}, headers(speechWord_col+2:end)];
    
    emb = fastTextWordEmbedding;
    expanded_data = {};
    
    for i = 1:size(table_data,1)
        row_data = table_data(i,:);
        cat_value = table_data{i,catValue_col};
        text = table_data{i,speechWord_col};
        exp_id = table_data{i,expID_col};
        cat_label = get_object_label(exp_id,cat_value);
        if ~isnan(subID_col)
            sub_id = table_data{i,subID_col};
            if ismember(sub_id,excludeSubjects)
                continue
            end
        end

        % check if the utterance is empty
        if isempty(text{1})
            row_data{1,speechWord_col} = {NaN};
            row = [row_data(1,1:catValue_col),{cat_label},row_data(1,catValue_col+1:end)];
            row = [row(1,1:speechWord_col+1),{NaN},row(1,speechWord_col+2:end)];
            expanded_data = [expanded_data;row];
            continue;
        end
    
        words = split(text);
        % go through each words in the utterance
        for j = 1:length(words)
            word = words{j};
            if strcmp(word(end),';')
                word = word(1:end-1);
            end
            % check if the word is stop word
            if ismember(word,stopwords_list)
                row_data{1,speechWord_col} = {NaN};
                row = [row_data(1,1:catValue_col),{cat_label},row_data(1,catValue_col+1:end)];
                row = [row(1,1:speechWord_col+1),{NaN},row(1,speechWord_col+2:end)];
                expanded_data = [expanded_data;row];
                continue
            end
            vec1 = word2vec(emb, cat_label); 
            vec2 = word2vec(emb, word);
            similarity = cosineSimilarity(vec1, vec2);

            row_data{1,speechWord_col} = {word};
            row = [row_data(1,1:catValue_col),{cat_label},row_data(1,catValue_col+1:end)];
            row = [row(1,1:speechWord_col+1),{similarity},row(1,speechWord_col+2:end)];
            expanded_data = [expanded_data;row];
        end
    
    end

    % write data into table
    expanded_data.Properties.VariableNames = headers;
    writetable(expanded_data,output_filename);
end