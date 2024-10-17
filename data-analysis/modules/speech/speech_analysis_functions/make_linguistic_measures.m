%%%
% Author: Jane Yang
% Last Modifier: 08/01/2024
% This function takes a word count summary CSV file containing the 
% frequency of each word appeared in the list of subjects and outputs a
% summary file including subID, age, total session time,
% total speech time, target_word_freq, #Token, #UniqueWord, #Utterance, 
% #Noun, #Verb, #Adjective, type/token ratio, mean length utterance, and MCDI?

%
% Input: subexpID        - a list of subjects or experiments
%        keywords_list    - a list of keywords to find the counts
%        output_filename - output filename
%
% Output: A CSV file including subID, age, total_session_time,
% total_speech_time, target_word_freq, #token, #uniqueWord, #utterance, 
% #noun, #verb, #adjective, type_token_ratio, mean utterance duration, 
% and, mean utterance token lengh
%
%
% Example function call: rtr_table = make_linguistic_measures(351, ["cup" "kettle"], 'exp351_cup-kettle_linguistic_measures.csv')
%%%

function rtr_table = make_linguistic_measures(subexpIDs, keywords_list, output_filename)
    % get a list of subjects
    subs = cIDs(subexpIDs);


    % initialize return table columns
    colNames = {'subID','age','total_session_time','total_speech_time'};
    % append column names based on the number of keywords
    for i = 1:length(keywords_list)
        colNames = horzcat(colNames,sprintf('num_%s',keywords_list{i}));
    end
    colNames = horzcat(colNames,'num_token','num_uniqueWord','num_utterance',...
                                'num_noun','num_verb','num_adjective',...
                                'type_token_ratio','mean_utterance_dur','mean_utterance_token_length');

    % hard-coding return table column index here
    subIDIdx = 1;
    ageIdx = 2;
    seshtimeIdx = 3;
    speechtimeIdx = 4;
    keywordcountStartIdx = 5;
    keywordcountEndIdx = keywordcountStartIdx + length(keywords_list) - 1;
    numTokenIdx = keywordcountEndIdx + 1;
    numUniqIdx = numTokenIdx + 1;
    numUttsIdx = numUniqIdx + 1;
    numNounsIdx = numUttsIdx + 1;
    numVerbsIdx = numNounsIdx + 1;
    numAdjIdx = numVerbsIdx + 1;
    numTypeTokenRatioIdex = numAdjIdx + 1;
    numMeanUttDurIdx = numTypeTokenRatioIdex + 1;
    numMeanUttLengthIdx = numMeanUttDurIdx + 1;
    

    
    % obtain keyword list and word summary table
    word_summary_output_filename = '.';
    summary_mtr = word_summary(subs,keywords_list,word_summary_output_filename);

    % prefill the return table with NaNs
    rtr = NaN(size(summary_mtr,1),length(colNames));

    % fill in the subID column
    new_subs = summary_mtr{:,1};
    rtr(:,subIDIdx) = new_subs;

    % get subjects' age
    rtr(:,ageIdx) = get_age_at_exp(rtr(:,1));

    % total session time
    rtr(:,seshtimeIdx) = summary_mtr{:,2};

    % target_word_freq, #token, #uniqueWord, #utterance, #noun, #verb, #adjective
    rtr(:,keywordcountStartIdx:numAdjIdx) = summary_mtr{:,3:end}; %%% TODO: may need to find a better way of indexing


    % iterate thru each subject to get other subject-level info
    for s = 1:length(new_subs)
        subID = new_subs(s); % current subject
    
        % total speech time
        speech_trans = read_speech_transcription(subID);
        total_speech_time = sum([speech_trans.end]' - [speech_trans.start]');
        rtr(s,speechtimeIdx) = total_speech_time;
         
        % type_token_ratio
        rtr(s,numTypeTokenRatioIdex) = rtr(s,numUniqIdx)/rtr(s,numTokenIdx); %%% TODO: need to find a better way of indexing

        
        % mean utterance dur
        mean_utts_dur = mean([speech_trans.end]' - [speech_trans.start]');
        rtr(s,numMeanUttDurIdx) = mean_utts_dur;

        % mean utterance token length
        uttsList = [];
        for i = 1:size(speech_trans, 2)
            utterance = speech_trans(i).words{1};
            numWords = length(strsplit(utterance,' '));
            uttsList = [uttsList;numWords];
        end

        % numChars = cellfun(@length, {speech_trans.words}');
        mean_utts_length = mean(uttsList);
        rtr(s,numMeanUttLengthIdx) = mean_utts_length;
    end

    % write to the csv file
    rtr_table = array2table(rtr,'VariableNames',colNames);
    writetable(rtr_table,output_filename);
end