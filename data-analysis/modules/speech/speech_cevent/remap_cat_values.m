%%%
% Author: Jingwen Pang
% Date: 4/17/2025 (Updated)
%
% This function reads a CSV file and remaps category values in a specified
% column based on a mapping table.
%
% Input:
%   - input_csv       : string, input CSV file name
%   - cat_col         : integer, column index of the category to remap
%   - mapping_table   : n x 2 numeric matrix, [original_val mapped_val]
%   - output_csv      : string, output CSV file name
%   - args (optional) : struct with optional fields:
%       - start_row : integer, number of header lines to skip (default = 0)
%
% Output:
%   - A CSV file with the specified category values remapped
%%%

function remap_cat_values(input_csv, cat_col, mapping_table, output_csv, args)

    % Default args
    if ~exist('args', 'var')
        args = struct();
    end
    if ~isfield(args, 'start_row')
        args.start_row = 0;
    end

    % Validate mapping_table
    if size(mapping_table, 2) ~= 2
        error("Mapping table must be an n x 2 matrix.");
    end

    % Read data from CSV
    data = readtable(input_csv, 'NumHeaderLines', args.start_row);

    % Extract category column
    old_vals = table2array(data(:, cat_col));

    % Prepare mapping
    original_vals = mapping_table(:, 1);
    mapped_vals   = mapping_table(:, 2);

    % Find mapping indices
    [tf, loc] = ismember(old_vals, original_vals);
    
    % Warn about unmatched values
    if any(~tf)
        warning("Some values in the category column were not found in the mapping list and were left unchanged.");
    end

    % Apply mapping
    new_vals = old_vals;
    new_vals(tf) = mapped_vals(loc(tf));
    data{:, cat_col} = new_vals;

    % Save result
    writetable(data, output_csv);

end
