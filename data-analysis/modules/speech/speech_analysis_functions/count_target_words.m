%%% This function is a helper function to generate a row vector of word
%%% count of the target words in an input utterance. It returns a row
%%% vector containing the count of each target word in the input utterance.
function count_vec = count_target_words(target_words, utterance)

    lower_utt = lower(utterance);
    mod_utterance = strjoin(target_words, ' ') + " " + utterance;
    utt_word_count_table = wordCloudCounts(mod_utterance);
    utt_word_count_table.Word = lower(utt_word_count_table.Word);
    word_map = containers.Map(utt_word_count_table.Word, utt_word_count_table.Count);

    % Split utterance manually for stop word counting
    word_list = split(lower_utt);

    count_vec = zeros(1, numel(target_words));

    for i = 1:numel(target_words)
        target_word = lower(target_words{i});

        if any(strcmp(target_word, stopWords))
            % Manually count stop word
            count_vec(i) = sum(strcmp(word_list, target_word));
        else
            % Use wordCloudCounts, subtract 1 for prepended word
            if isKey(word_map, target_word)
                count_vec(i) = max(word_map(target_word) - 1, 0);
            else
                count_vec(i) = 0;
            end
        end
    end

end