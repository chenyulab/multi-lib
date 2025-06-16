%%%
% Author: Jingwen Pang
% Date: 6/16/2025
% 
% This function reads a row headers and column headers from the first sheet of word matrix file 
% calculates pairwise word similarity scores and outputs the result as a .csv file in the same format as the input sheet.
%%%
function cal_word_similarity(input_excel, output_csv)
    % Load the built-in Word2Vec model
    fprintf('Loading word embedding model...\n');
    w2v_model = fastTextWordEmbedding;

    % Read only the first sheet of the Excel file
    data = readtable(input_excel, 'Sheet', 1, 'ReadVariableNames', true);
    
    % Extract row names and column names
    row_names = data{:, 1};  % First column values
    col_names = data.Properties.VariableNames(2:end);  % Column headers after first

    n_rows = length(row_names);
    n_cols = length(col_names);

    % Initialize similarity matrix
    sim_matrix = NaN(n_rows, n_cols);

    % Calculate cosine similarity for each cell
    for i = 1:n_rows
        row_word = string(row_names{i});
        for j = 1:n_cols
            col_word = string(col_names{j});
            try
                vec1 = word2vec(w2v_model, row_word);
                vec2 = word2vec(w2v_model, col_word);
                sim = dot(vec1, vec2) / (norm(vec1) * norm(vec2));
            catch
                sim = NaN;  % Skip if any word is not in the vocabulary
            end
            sim_matrix(i, j) = sim;
        end
    end

    % Construct output table
    output_table = array2table(sim_matrix, 'VariableNames', col_names);
    output_table = addvars(output_table, row_names, 'Before', 1, 'NewVariableNames', data.Properties.VariableNames{1});

    % Write to CSV
    writetable(output_table, output_csv);
    fprintf('Similarity matrix saved to: %s\n', output_csv);
end
