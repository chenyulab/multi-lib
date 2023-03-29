%%%
% Author: Jane Yang
% Last Modifier: 3/23/2023
% This function tokenizes input string and outputs string's vocabulary and
% token details.
% 
% Input: a string of utterance
% Output: a table of token details, a string array of input string's 
%         vocabularies
%%%

function [tdetails,vocab] = preprocess_utterances(utterance_str)
    % tokenize speech_transcription
    documents = tokenizedDocument(utterance_str);

    % add part of speech details
    documents = addPartOfSpeechDetails(documents);

    % remove punctuations
    documents = erasePunctuation(documents);

    % get token details --> return token detail table
    tdetails = tokenDetails(documents);
    vocab = (documents.Vocabulary)';
end