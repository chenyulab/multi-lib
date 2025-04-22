%%% This function is a helper function to generate a row vector of word
%%% count of the target words in an input utterance. It returns a row
%%% vector containing the count of each target word in the input utterance.
function count_vec = count_target_words(target_words, utterance)
    % Initialize a target word count row vector
    count_vec = zeros(1, numel(target_words));

    % Iterate through target words list
    for i = 1:numel(target_words)
        target_word = target_words{i}; % Keep original case

        if any(strcmpi(target_word, stopWords))
            % If the target word is a stop word, count it manually
            % Use regex to match whole words (case-insensitive)
            words = split(lower(utterance));
            count = sum(strcmpi(words, target_word));
            count_vec(i) = count;
        else
            % Prepend target word to avoid undercounting due to forms
            mod_utterance = target_word + " " + utterance;

            % Use wordCloudCounts to get counts
            utt_word_count_table = wordCloudCounts(mod_utterance);

            % Find index of the target word in the word count table
            match_idx = find(strcmp(utt_word_count_table.Word, target_word));

            if ~isempty(match_idx)
                % Subtract the artificially added count
                count_vec(i) = max(utt_word_count_table.Count(match_idx) - 1, 0);
            end
        end
    end
end