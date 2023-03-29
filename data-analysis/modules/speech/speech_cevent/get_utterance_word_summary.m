%%%
% Author: Jane Yang
% Last Modifier: 3/26/2023
% This function is a helper function for generating a summary row vector
% for any input utterance. It returns a row vector containing the number of 
% tokens, unique words, utterances, nouns, verbs, and adjectives in an 
% input utterance.
%
% Input: a string of speech utterance
% Output: a six-tuple row vector representing the number of tokens,
%         unique words, utterances, nouns, verbs, and adjectives of input.
%%%

function summary_vec = get_utterance_word_summary(utterance)
    if strcmp(utterance,"")
        % hard-coded an empty summary vector for empty input utterance
        % columns:
        % {'#token','#uniqueWords','#utterances','#noun','#verb','#adj'}
        summary_vec = zeros(1,6);
    else
        % tokenize utterance and get token details
        [tdetails,vocab] = preprocess_utterances(utterance);
    
        % calculate number of tokens
        num_token = size(tdetails.Token,1);
        
        % calculate number of unique words (vocabs)
        num_unique = size(vocab,1);
    
        % calculate number of utterances - count number of semicolon
        num_utterances = count(utterance,';');
    
        % calculate number of part of speech
        partOfSpeech_cats = categories(tdetails.PartOfSpeech); 
        counts_cat = countcats(tdetails.PartOfSpeech);
    
        % count number of nouns
        num_noun = counts_cat(strcmp(partOfSpeech_cats,'noun'));
    
        % count number of verbs
        num_verb = counts_cat(strcmp(partOfSpeech_cats,'verb'));
        
        % count number of adjectives
        num_adj = counts_cat(strcmp(partOfSpeech_cats,'adjective'));
    
        summary_vec = [num_token num_unique num_utterances num_noun num_verb num_adj];
    end
end