% Author: Ruchi Shah
% Last modified: 03/29/2024
% Summary:
% This function creates a csv for a csv generated by
% query_csv_speech(), with pointers to frames
% Input:
%       input_filename  -- a csv generated by query_csv_speech()
%       output_filename -- the directory + filename to output to (a csv)
function create_positive_examples(input_filename, output_filename)
    csv = readtable(input_filename);
    subIDs = {};
    frame_paths = {};
    utterances = {};

   % interate through each bout
    for i = 1:size(csv,1)
        src_dir = csv{i,11};
        start_frame = csv{i,5};
        end_frame = csv{i,8};
        subID = csv{i,1};
        utterance = csv{i,10};

        % copy frames over as negative examples
        for f = start_frame:end_frame
            path = fullfile(src_dir,sprintf('img_%d.jpg',f));
            frame_paths{end+1} = path;
            subIDs{end+1} = subID;
            utterances{end+1} = utterance;

        end
    end

    data = table(subIDs', utterances', frame_paths','VariableNames', {'SubjectID', 'utterance', 'frame_file_path'});
    writetable(data, output_filename);
end