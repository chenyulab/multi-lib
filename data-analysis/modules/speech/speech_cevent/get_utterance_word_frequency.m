function wordFreq =  get_utterance_word_frequency(utterance, excluded_words)
    % takes in cell array containing a string and returns unique counts and
    % word frequency 
    wordFreq = dictionary(string.empty,double.empty);
    
    utterance_clean = regexprep(utterance, '[^\w\s]', '');     % remove punctuation
    utterance_clean = strtrim(utterance_clean);                % remove leading/trailing spaces
    split_words = strsplit(utterance_clean);  
    
    for word = split_words
        cleaned_words = strsplit(word{1}, ";");
        % sometimes if an utterance is merge word1;word2 might happen 
        for j = 1:width(cleaned_words)
            % check that it's not empty nor a word 
            if ~isempty(cleaned_words{j}) || numel(cleaned_words{j}) > 1
                % check that it's not a stop word 
                if ~ismember(cleaned_words{j}, excluded_words)
                    % add to dictionary if not present otherwise update
                    % count 
                    if isKey(wordFreq, cleaned_words{j})
                        wordFreq(cleaned_words{j}) = wordFreq(cleaned_words{j}) + 1;
                    else
                        wordFreq(cleaned_words{j}) = 1;
                    end
                end
            end
        end
    end
end