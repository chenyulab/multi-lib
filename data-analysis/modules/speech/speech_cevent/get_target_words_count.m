%%% This function is a helper function to generate a row vector of word
%%% count of the target words in an input utterance. It returns a row
%%% vector containing the count of each target word in the input utterance.

function count_vec = get_target_words_count(target_words,utterance)
    % initialize a target word count row vector
    count_vec = zeros(1,numel(target_words));

    % calculate basic token measures per matching instance
    utt_word_count_table = wordCloudCounts(utterance);
    
    % iterate thru target words list to find matching count
    for i = 1:numel(target_words)
        % find target words word count
        match_idx = find(ismember(utt_word_count_table.Word,target_words(i)));

        if numel(match_idx) ~= 0
            target_word_count = utt_word_count_table.Count(match_idx);
            count_vec(i) = target_word_count;
        end
    end
end