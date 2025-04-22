function wordFreq =  get_utterance_word_frequency(utterance)
    % takes in cell array containing a string and returns unique counts and
    % word frequency 
    wordFreq = dictionary(string.empty,double.empty);

    split_words = strsplit(utterance, " ");
    
    for word = split_words
        cleaned_words = strsplit(word{1}, ";");

        for j = 1:width(cleaned_words)
            if ~ismember(cleaned_words{j}, stopWords) & ~isempty(cleaned_words{j})
                if isKey(wordFreq, cleaned_words{j})
                    wordFreq(cleaned_words{j}) = wordFreq(cleaned_words{j}) + 1;
                else
                    wordFreq(cleaned_words{j}) = 1;
                end
            end
        end
    end
end