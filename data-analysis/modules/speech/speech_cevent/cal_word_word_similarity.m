%%%
% This function take an word pairs file, calculate 
% the word similarity betweem two words and append simialrity score.
% 
% input parameter:
%   - input_filename (string)
%       - speech file or grouped speech file, must include exp id, category
%         value columns, and speech utterance column
%   - word_col1 (int)
%       - word 1 column number in input file
%   - word_col2 (int)
%       - word 1 column number in input file
%   - output_filename (string)
%
% output file
%   - csv/excel file, similarity score appended at the end of each row
% 
%%%
function cal_word_word_similarity(input_filename,word_col1,word_col2,output_filename)

    % determine if it is excel file or csv file
    [~, ~, ext] = fileparts(input_filename);

    if strcmpi(ext, '.csv')
        % If it's a CSV file, just read it
        data = readtable(input_filename);
        % append similarity score
        rtr_data = append_similarity_score(data,word_col1,word_col2);
        writetable(rtr_data, output_filename, 'Sheet', sheetName);

    elseif strcmpi(ext, '.xlsx')
        % If it's an Excel file, read each sheet
        [~, sheets] = xlsfinfo(input_filename);
        for i = 1:length(sheets)
            sheetName = sheets{i};
            disp(sheetName)
            data= readtable(input_filename, 'Sheet', sheetName);
            % append similarity score
            rtr_data = append_similarity_score(data,word_col1,word_col2);
            writetable(rtr_data, output_filename, 'Sheet', sheetName);
        end
    else
        error('Unsupported file type: %s', ext);
    end


end

% helper function that append similarity score into a table
function rtr_data = append_similarity_score(table_data, word_col1, word_col2)
    emb = fastTextWordEmbedding;
    
    if isempty(table_data)
        warning('Input table is empty!');
        rtr_data = table(); % return empty table
        return;
    end

    similarity_scores = zeros(size(table_data,1), 1);  % preallocate

    for i = 1:size(table_data, 1)
        word1 = table_data{i, word_col1};
        word2 = table_data{i, word_col2};

        vec1 = word2vec(emb, word1); 
        vec2 = word2vec(emb, word2);
        similarity_scores(i) = cosineSimilarity(vec1, vec2);
    end

    % Add similarity column to original table
    rtr_data = table_data;
    rtr_data.similarity = similarity_scores;
end