%%%
% Author: Jane Yang
% Last Modifier: 3/23/2023
% This function tokenizes input string and outputs string's vocabulary and
% token details.
% 
% Input: subject ID
% Output: a table of token details, a string array of input string's 
%         vocabularies, a struct representation of speech transcription
%%%

function [tdetails,vocab,utterances] = preprocess_trans(subID)
    % read speech_transcription .txt file
    [raw_trans,utterances] = parse_speech_trans(subID);

    if size(raw_trans,1) ~= 0
       % tokenize speech_transcription
        documents = tokenizedDocument(raw_trans);
    
        % add part of speech details
        documents = addPartOfSpeechDetails(documents);
    
        % get token details --> return token detail table
        tdetails = tokenDetails(documents);
        vocab = (documents.Vocabulary)';
    else
        tdetails = [];
        vocab = [];
        utterances = [];
    end
end