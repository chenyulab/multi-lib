% Calculate Utterance Similarity using Sentence-BERT
%
% This demo extracts all speech utterances at the experiment level using
% `extract_speech_in_situ`, and computes similarity scores at different
% levels using `cal_utterance_similarity_by_sBERT`.
%
% output
% ├── expXX_utt_similarity.xlsx      % Experiment-level similarities
% │   ├── [overall exp-level sheet]
% │   └── [category-level sheets]
% └── {subID}_utt_similarity.xlsx    % Subject-level similarities
%     ├── [overall subject-level sheet]
%     └── [subject-category level sheets]
%
% Prerequisites:
% 0. Ensure Python (version 3.9–3.12) is installed.
% 1. Install the Sentence-Transformers module:
%       py -m pip install sentence-transformers
% 2. Find the Python executable path:
%       py -c "import sys; print(sys.executable)"

function demo_utterance_similarity(option)

py_path = 'C:\Users\YuLab\AppData\Local\Programs\Python\Python310\python.exe';  % ← Update to your Python path

switch option

    case 1
        expIDs = [351, 353, 91, 27];

        for s = 1:length(expIDs)
            expID = expIDs(s);

            % Extract all speech utterances for each experiment
            cevent_var = 'cevent_speech_utterance';
            category_list = 1:get_num_obj(expID)+1;  % including no-naming instance
            output_filename = fullfile(output_dir, sprintf('exp%d_all_speech_utterance.csv', expID));
            extract_speech_in_situ(expID, cevent_var, category_list, output_filename);
            
            % Compute semantic similarity of utterances
            keep_dups = true; % keep duplicate utterance
            output_dir = 'Z:\demo_output_files\utterance_sematic_similarity';
            cal_utterance_similarity_by_sBERT(output_filename, keep_dups, py_path, output_dir);
        end
    
end
