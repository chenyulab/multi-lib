function [onset, offset] = get_extract_range(subID)
    root = get_subject_dir(subID);
    extract_range_file = fullfile(root,'supporting_files','extract_range.txt');
    range_file = fopen(extract_range_file,'r');

    if range_file ~= -1
        data = textscan(range_file, '[%f]');  % Works line by line
        fclose(range_file);

        values = data{1};  % Extract numbers
        if numel(values) >= 2
            onset = values(1);
            offset = values(2);
        else
            onset = NaN;
            offset = NaN;
            warning('No valid numbers found in extract_range.txt');
        end
    else
        warning('Failed to open extract_range.txt');
        onset = NaN;
        offset = NaN;
    end
end