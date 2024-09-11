%%%
% Author: Jane Yang
% Last Modifier: 3/22/2023
% This function genenerates a speech summary table of input subjects 
% or experiment. It also generates a CSV file outputs the frequency of 
% target words, #Token, #UniqueWord, #Utterance, #Noun, #Verb, 
% and #Adjective.
% 
% Input: subID or expID, a list of target words (string array), output
%        filename in string
% Output: a speech summmary table containing subID, target words frequency,
%         #Token, #UniqueWord, #Utterance, #Noun, #Verb, and #Adjective. A
%         .CSV file is generated based on the output table.
%%%

function summary_mtr = word_summary(subexpID,target_words,output_filename)
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

    colNames = horzcat({'subID','sessionTime'},cellstr(target_words),{'#Token','#UniqueWord','#Utterance','#Noun','#Verb','#Adjective'});
    summary_mtr = [];

    for j = 1:size(flattened_list,1)
        % process transcription
        [tdetails,vocab,utterances] = preprocess_trans(flattened_list(j));

        % get speech session time
        sessionTime = utterances(end).end - utterances(1).start;

        % calculate number of tokens
        num_token = size(tdetails.Token,1);
        
        % calculate number of unique words (vocabs)
        num_unique = size(vocab,1);

        % calculate number of utterances
        num_utterances = size(utterances,2);

        % calculate number of part of speech
        % get part of speech categories
        partOfSpeech_cats = categories(tdetails.PartOfSpeech);
        % get counts
        counts_cat = countcats(tdetails.PartOfSpeech);

        % count number of nouns
        num_noun = counts_cat(strcmp(partOfSpeech_cats,'noun'));

        % count number of verbs
        num_verb = counts_cat(strcmp(partOfSpeech_cats,'verb'));
        
        % count number of adjectives
        num_adj = counts_cat(strcmp(partOfSpeech_cats,'adjective'));

        %% get count of target words
        % initialize target word count row vector
        word_count_vec = zeros(1,numel(target_words));
        
        % get overall word count matrix for current subject
        [~,~,summary_count] = get_word_count_matrix(flattened_list(j),'');

        % find count of each matching target word
        for t_id = 1:numel(target_words)
            target_match_idx = find(ismember(summary_count.word,target_words(t_id)));
            if numel(target_match_idx ~= 0)
                word_count_vec(t_id) = str2double(summary_count{target_match_idx,2});
            end
        end

        %% create new entry to append to the summary matrix
        entry = horzcat(flattened_list(j),sessionTime,word_count_vec);
        entry = horzcat(entry,num_token,num_unique,num_utterances,num_noun,num_verb,num_adj);

        summary_mtr = [summary_mtr;entry];
    end

    summary_mtr = array2table(summary_mtr,'VariableNames',colNames);

    if ~strcmp(output_filename,'.') % only write to file if the output file is valid
        writetable(summary_mtr,output_filename);
    end
end