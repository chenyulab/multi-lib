%%%
% Author: Jane Yang
% Last Modifier: 3/15/2023
% This function generates a wordcloud for each subject, saving wordclouds
% to specified output directory.
% 
% Input: subID or expID, wordclouds output directory
% Output: .PNG files of wordcloud for each subject
%%%

function generate_wordcloud(subexpID,output_dir)
    flattened_list = [];

    %% generate a list of subjects that have a speech transcription file
    for i = 1:numel(subexpID)
        if size(cIDs(subexpID(i)),1) == 1
            [all_words,utterances] = parse_speech_trans(cIDs(subexpID(i)));
            if size(all_words,1) ~= 0
                flattened_list(end+1,1) = cIDs(subexpID(i));
            end
        elseif size(cIDs(subexpID(i)),1) > 1
            list = cIDs(subexpID(i));
            for j = 1:size(list,1)
                [all_words,utterances] = parse_speech_trans(list(j));
                if size(all_words,1) ~= 0
                    flattened_list(end+1,1) = list(j);
                end
            end
        end
    end
    
    %% generate one wordcloud for each subject
    for j = 1:size(flattened_list,1)
        speech_dir = fullfile(get_subject_dir(flattened_list(j)), 'speech_transcription_p');
        sub_info = get_subject_info(flattened_list(j));
        speech_entry = dir(fullfile(speech_dir, sprintf('speech_%d.txt',sub_info(4))));   
        speech_path = fullfile(speech_dir, speech_entry.name);
    
        % read speech_transcription .txt file
        raw_trans_str = extractFileText(speech_path);

        % generate word cloud
        wordcloud(raw_trans_str);
        title(num2str(flattened_list(j)));
        saveas(gcf,[output_dir 'wordcloud_' num2str(flattened_list(j)) '.png']);
    end
end