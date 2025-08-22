%%%
% Author: Jingwen Pang
% Date: 8/14/2025
% Remap row/column labels in a word matrix to match a provided word list.
% 
% Inputs:
% Word matrix file: CSV or Excel format
% Word list: A list of words to align the matrix with
% 
% Output:
% A remapped word matrix where the header aligns exactly with the word list; other words in the input file will be removed.
% If a word in the list is missing in the word matrix, its column/row will be filled with NaN.
%%%
function filter_cat2word_freq(input_file, output_file, word_list)

   [~, ~, ext] = fileparts(input_file);

    switch lower(ext)
        case '.csv'
            data = readtable(input_file,'PreserveVariableNames',true);
            filtered_data = extract_word_matrix(data, word_list);
            writetable(filtered_data, output_file);

        case '.xlsx'
            [~, sheetNames] = xlsfinfo(input_file);
            if isempty(sheetNames)
                error('No sheets found in "%s".', input_file);
            end
            for i = 1:numel(sheetNames)
                sheet = sheetNames{i};
                disp(['Processing sheet: ' sheet]);
                data = readtable(input_file, 'Sheet', sheet, 'PreserveVariableNames',true);
                filtered_data = extract_word_matrix(data, word_list);

                if i == 1
                    writetable(filtered_data, output_file, 'Sheet', sheet);
                else
                    writetable(filtered_data, output_file, 'Sheet', sheet, 'WriteMode','overwritesheet');
                end
            end

        otherwise
            error('Unsupported file type: %s', ext);
    end
end


function output_data = extract_word_matrix(data, word_list)
    col2skip = 2;   % always keep first 2 columns (IDs / metadata)

    % Ensure word_list is valid names (for matching)
    target_names = matlab.lang.makeValidName(word_list);

    % Get all variable names except metadata
    col_headers = data.Properties.VariableNames;
    col_headers_main = col_headers(col2skip+1:end);

    % Match requested words to available columns
    [tf, loc] = ismember(target_names, col_headers_main);

    if any(~tf)
        warning('Some words not found and skipped: %s', strjoin(word_list(~tf), ', '));
    end

    % Keep only matched columns
    keep_idx = loc(tf) + col2skip;   % shift for skipped columns
    new_main_cols = data(:, keep_idx);

    % Combine with the always-kept metadata columns
    col2keep = data(:, 1:col2skip);
    output_data = [col2keep new_main_cols];
end