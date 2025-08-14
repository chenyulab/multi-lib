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
function filter_cat2word_freq(input_file, expID, word_list, output_file)

    word_mapping = get_exp_word_list(expID, word_list);
    word_id_list = cell2mat(word_mapping(:,1))'; % word id column
    
    
    % read input data file
    [~, ~, ext] = fileparts(input_file);  % Get file extension
    
    if strcmpi(ext, '.csv')
        % Read CSV file
        data = readtable(input_file,'PreserveVariableNames', true);

        % Check if flag == 1 and first column contains numeric values
        if flag == 1 && isnumeric(data{1,1})
            error('The first column contains numeric values. Row headers should not be numerical when using flag 1. Try flag 2 to remap column headers only.');
        end
    
        filtered_data = extract_word_matrix(data,word_list, word_id_list);
    
        writetable(filtered_data,output_file);
    
    
    elseif strcmpi(ext, '.xlsx')
        % Read all sheets in Excel file
        [~, sheetNames] = xlsfinfo(input_file);
        
        
        for i = 1:length(sheetNames)
            sheet = sheetNames{i};
            disp(sheet);
            data = readtable(input_file, 'Sheet', sheet);
    
            filtered_data = extract_word_matrix(data,word_list, word_id_list);
            
            writetable(filtered_data, output_file, 'Sheet', sheet);
        end
    else
        error('Unsupported file type: %s', ext);
    end

end



function output_data = extract_word_matrix(data, word_list, word_id_list)
    col2skip = 2;
    col2keep = data(:, 1:col2skip);
    col_headers = data.Properties.VariableNames;
    col_headers_main = col_headers(col2skip+1:end); % variable names for word columns
    col_word_id = str2double(col_headers_main);     % extract word IDs from column headers

    % Initialize new columns (will fill one-by-one)
    new_data = NaN(height(data), length(word_id_list));  % default with NaNs

    for i = 1:length(word_id_list)
        word_id = word_id_list(i);
        if word_id == 0
            new_data(:, i) = 0;  % Placeholder for missing word
        else
            new_data(:, i) = data{:, word_id + col2skip};  % skip ID/instance columns
        end
    end

    % Convert to table and assign word_list as headers
    new_main_cols = array2table(new_data, 'VariableNames', matlab.lang.makeValidName(word_list));

    % Combine with label columns
    main_with_labels = [col2keep new_main_cols];

    output_data = main_with_labels;

end
