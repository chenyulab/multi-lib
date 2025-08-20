%%%
% Author: Jingwen Pang
% Date: 7/16/2025
% Remap row/column labels in a word matrix to match a provided word list.
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
% A remapped word matrix where the header aligns exactly with the word list; other words in the input file will be removed.
% If a word in the list is missing in the word matrix, its column/row will be filled with NaN.
%%%
function subset_counts_by_keywords(input_file, word_list, flag, placeholder, col_to_keep, output_file)
    

    % read input data file
    [~, ~, ext] = fileparts(input_file);  % Get file extension
    
    if strcmpi(ext, '.csv')
        % Read CSV file
        data = readtable(input_file,'PreserveVariableNames', true);

        % Check if flag == 1 and first column contains numeric values
        if flag == 1 && isnumeric(data{1,1})
            error('The first column contains numeric values. Row headers should not be numerical when using flag 1. Try flag 2 to remap column headers only.');
        end
    
        filtered_data = extract_word_matrix(data,word_list,flag, placeholder, col_to_keep);
    
        writetable(filtered_data,output_file);
    
    
    elseif strcmpi(ext, '.xlsx')
        % Read all sheets in Excel file
        [~, sheetNames] = xlsfinfo(input_file);
        
        for i = 1:length(sheetNames)
            sheet = sheetNames{i};
            disp(sheet)
            data = readtable(input_file, 'Sheet', sheet);

            % Check if flag == 1 and first column contains numeric values
            if flag == 1 && isnumeric(data{1,1})
                error(['Sheet "' sheet '" contains numeric row headers. Row headers should not be numerical when using flag 1. Try flag 2 to remap column headers only.']);
            end
    
            filtered_data = extract_word_matrix(data,word_list,flag, placeholder, col_to_keep);
            
            writetable(filtered_data, output_file, 'Sheet', sheet);
        end
    else
        error('Unsupported file type: %s', ext);
    end

end



function output_data = extract_word_matrix(data, word_list, flag, placeholder, col_to_keep)

    row_labels = data{:,1};
    col_headers = data.Properties.VariableNames;

    % Prepare filtered data
    col_headers_main = col_headers(2:end); % Exclude first column (row labels)
    data_main = data(:, 2:end);
    row_names = data{:,1};

    % Extract and reorder columns
    if flag == 1 || flag == 2
        if placeholder == 1
            new_main_cols = array2table(NaN(height(data), length(word_list)), 'VariableNames', word_list);
        else
            new_main_cols = array2table(zeros(height(data), length(word_list)), 'VariableNames', word_list);
        end
        for i = 1:length(word_list)
            idx = find(strcmp(col_headers_main, word_list{i}), 1);
            if ~isempty(idx)
                new_main_cols{:, i} = data{:, idx+1}; % +1 to skip row label column
            end
        end
    else
        new_main_cols = data(:, 2:end); % keep original
    end

    % Extract and reorder rows
    if flag == 1
        if placeholder == 1
            new_main_rows = array2table(NaN(length(word_list), width(new_main_cols)), ...
                                    'VariableNames', new_main_cols.Properties.VariableNames);
        else
            new_main_rows = array2table(zeros(length(word_list), width(new_main_cols)), ...
                                    'VariableNames', new_main_cols.Properties.VariableNames);
        end
        new_row_names = cell(length(word_list), 1);
        for i = 1:length(word_list)
            idx = find(strcmp(row_labels, word_list{i}), 1);
            new_row_names{i} = word_list{i};
            if ~isempty(idx)
                new_main_rows(i, :) = new_main_cols(idx, :);
            end
        end
    else
        new_main_rows = new_main_cols;
        new_row_names = row_labels;
    end


    if exist('new_row_names', 'var')
        main_with_labels = [table(new_row_names, 'VariableNames', col_headers(1)) new_main_rows];
    else
        main_with_labels = [table(row_labels, 'VariableNames', col_headers(1)) new_main_cols];
    end


    % === Append extra columns only if col_to_keep is provided ===
    if isempty(col_to_keep)
        output_data = main_with_labels;
    else
        keep_cols_append = ismember(col_headers, col_to_keep);
        keep_cols_append(1) = false; % exclude row label column
        append_part = data(:, keep_cols_append);

        % Check if size matches; if not, skip appending
        if height(append_part) ~= height(main_with_labels)
            warning('Skipped appending extra columns due to row count mismatch.');
            output_data = main_with_labels;
        else
            output_data = [main_with_labels append_part];
        end
    end
end
