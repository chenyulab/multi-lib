%%% This function is a helper function to generate a row vector of word
%%% count of the target words in an input utterance. It returns a row
%%% vector containing the count of each target word in the input utterance.
function count_vec = get_target_words_count(target_words, utterance)
    % Initialize a target word count row vector
    count_vec = zeros(1, numel(target_words));

    % Iterate through target words list
    for i = 1:numel(target_words)
        target_word = target_words{i}; % Keep original case

        % Create a modified utterance by prepending the target word
        mod_utterance = target_word + " " + utterance;

        % Get word counts from the modified utterance
        utt_word_count_table = wordCloudCounts(mod_utterance);

        % Find index of the target word in the word count table
        match_idx = find(strcmp(utt_word_count_table.Word, target_word));

        if ~isempty(match_idx)
            % Subtract the artificially added count (from prepending)
            count_vec(i) = max(utt_word_count_table.Count(match_idx) - 1, 0);
        end
    end
end