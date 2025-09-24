% This function convert variable data back to datavyu coding file
% Author: Jingwen Pang
% Date: 9/24/2025
% input:
%   - subexpIDs
%   - variables
%   - output_filename (no path)
%   - (optional)mapping_file: file that map category value back to label, 
%       if this parameter is not exist, then the label column is empty
% Output:
%   output file will saved in each subject_folder's supporting_files folder
% example call: 
%   convert_var_to_datavyu_label(353,{'cevent_speech_verb_word-id_parent'},'verb_coding_file.csv', 'verb_mapping.csv')
function convert_var2datavyu_label(subexpIDs,variables,output_filename, mapping_file)

    frame_rate = 30;
    start_time = 30;

    subIDs = cIDs(subexpIDs);
    
    % extract_list = [2,3,10,11,15,17,20];
    
    for s = 1:length(subIDs)
        subID = subIDs(s);
    
     % get mapping_filenames from experiment directory
     sub_info = get_subject_info(subID);
     mapping_root = fullfile(get_multidir_root(),['experiment_' num2str(sub_info(2))]);
     % check if there are multiple mapping files
     mapping_filename= fullfile(mapping_root,mapping_file);
    
    timing = get_timing(subID);
    
    speech_time = timing.motionTime;
    
    extract_range_file = fullfile(get_subject_dir(subID),'supporting_files','extract_range.txt');
    range_file = fopen(extract_range_file,'r');
    
    if range_file ~= -1
        extract_range_onset = fscanf(range_file, '[%f]');
        fclose(range_file); % Close the file after reading
    else
        error('Failed to open extract_range.txt');
    end
    
    
    % Initialize an empty cell array to store the results
    resultArray = {};
    skip_subject = false;
    
    for v = 1:length(variables)
        var = variables{v};  % Current variable name
        try
        data = get_variable(subID, var);  % Retrieve the data based on subID and var
        catch ME
            skip_subject = true;
            break;
        end

        if isempty(data)
            skip_subject = true;
            break;  % exit variable loop
        end

        % % extract the rows that contains those values
        % rows_to_keep = ismember(data(:,3), extract_list);
        % data = data(rows_to_keep, :);
        % 
        % 
        % if isempty(data)
        %     skip_subject = true;
        %     break;  % exit variable loop
        % end
        
        % Adjust the first two columns of data
        data(:,1) = (data(:,1) - speech_time) * 1000;
        data(:,2) = (data(:,2) - speech_time) * 1000;
       
        
        % Convert the data to cell arrays
        col1 = num2cell(data(:,1));
        col2 = num2cell(data(:,2));
        if exist("mapping_filename","var")
            mapping = readtable(mapping_filename);

            % Extract label and category from mapping
            label_map = string(mapping{:,1});   % e.g., "ba", "be", ...
            cat_map   = mapping{:,2};           % e.g., 19, 27, ...
            
            % col3 contains category values
            col3_value = data(:,3);
            
            % Preallocate result
            col3 = strings(size(col3_value));
            
            % Map each category number back to its label
            [~,loc] = ismember(col3_value, cat_map);
            col3 = cellstr(label_map(loc));

        else
            col3 = {''};
        end
        
        % Determine the maximum number of rows in the current resultArray and new columns
        maxRows = max([size(resultArray, 1), size(col1, 1), size(col2, 1), size(col3, 1)]);
        
        % Pad the resultArray and new columns to ensure they all have the same number of rows
        if size(resultArray, 1) < maxRows
            resultArray(end+1:maxRows, :) = {[]};  % Pad with empty cells
        end
        if size(col1, 1) < maxRows
            col1(end+1:maxRows, :) = {NaN};  % Pad with NaNs for missing data
        end
        if size(col2, 1) < maxRows
            col2(end+1:maxRows, :) = {NaN};  % Pad with NaNs for missing data
        end
        if size(col3, 1) < maxRows
            col3(end+1:maxRows, :) = {''};  % Pad with empty strings for missing labels
        end

        
        % Concatenate the new columns to the resultArray
        resultArray = [resultArray, col1, col2, col3];
    end
    
    if skip_subject
        % fprintf('%d skipped because it is empty\n',subID);
        fprintf('no variable or data is empty in %d\n',subID);
        continue;  % go to next subject
    end
    
    % Convert the result array to a table
    T = cell2table(resultArray);
    
    T = T(:,2:end);
    
    % Optionally, set the variable names for the table columns
    numColumns = size(T, 2);
    j = 1;
    for i = 1:3:numColumns
        T.Properties.VariableNames{i} = sprintf('onset_%s', variables{j});
        T.Properties.VariableNames{i+1} = sprintf('offset_%s', variables{j});
        T.Properties.VariableNames{i+2} = sprintf('value_%s', variables{j});
        j = j + 1;
    end
    
    output_dir = fullfile(get_subject_dir(subID),'supporting_files');
    
    % Save the table to a CSV file
    
    writetable(T, fullfile(output_dir,output_filename));
    fprintf('%d coding file saved',subID);


    end
end