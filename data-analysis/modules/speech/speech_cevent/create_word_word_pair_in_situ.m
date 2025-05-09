%%%
%
% This function takes text instances finds the local and global instance pairs
% and its corresponding word frequency 
% 
%
% Author: Elton Martinez
% Modifier: Elton Martinez
% Last modified: 5/6/2025
%
% Input parameters:
%   - file_in: path the input file
% 
%   - text_col_num: the numeric location of the text column relative to the 
%              input file, note if just passing one column it will break 
%  
%   - extraStopWords: a string array of words to ignore when counting
%               pairs. Common stop words are already accounted for. If you
%               want to see all the stopwords type stopWords in matlab.
%              
%
%   - file_out: desired name of the output file, this function writes to  
%               multiple sheet within one file so use an xlsx ending 
%            
 
function create_word_word_pair_in_situ(file_in, text_col_num, extraStopWords, file_out)
    % matlab makes noise when you write to a xlsx sheet
    warning('off', 'MATLAB:xlswrite:AddSheet') ;
    
    % read transcription 
    df = readtable(file_in, Delimiter=",");
    
    % initialize global pairs 
    pairs = cell(1,5);
    pairs{1,1} = 'NaN';
    pairs{1,2} = 'NaN';
    pairs{1,3} = 0;
    pairs{1,4} = 0;
    pairs{1,5} = 0;
    count = 1;
    
    % clean & prealocate xls file 
    pairs_df = array2table(pairs(2:end,:),'VariableNames',{'pair1','pair2','freq1','freq2','pair_freq'});
    writetable(pairs_df,file_out,'Sheet',1,'WriteMode','replacefile');
    
    % initialize word-freq dictionary 
    wordFreq = dictionary(string.empty,double.empty);
    pairFreq = dictionary(string.empty,double.empty);

     f = waitbar(0,'1','Name','appending pairs...',...
        'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
    
    % iterate through each instance of the df 
    for i = 1:height(df)
        % get the unique pairs for each instance 
        instance = df{i, text_col_num}{1};
        
        % add extra stop words parameter
        [inst_pairs, inst_wordFreq, inst_pairFreq] = extract_word_pairs(instance, extraStopWords);
        inst_words = keys(inst_wordFreq);
        inst_pairs_concat = keys(inst_pairFreq);
        inst_unq_pairs = zeros(height(inst_pairs),1);

        % add pair count 
        count_column = cell(height(inst_unq_pairs),1);
        inst_pairs  = [inst_pairs count_column];

        % ignore empty instances
        if isempty(instance) || isscalar(inst_words)
            count = count + 1;
            continue 
        end
        
        % add instance key words to global key words 
        for k = 1:height(inst_words)
            word = inst_words{k};
            if isKey(wordFreq, word)
                wordFreq(word) = wordFreq(word) + inst_wordFreq(word);
            else
                wordFreq(word) = inst_wordFreq(word);
            end
        end
        
        for k = 1:height(inst_pairs_concat)
            pair = inst_pairs_concat{k};
            inst_pairs{k,5} = inst_pairFreq(pair);

            if isKey(pairFreq, pair)
                pairFreq(pair) = pairFreq(pair) + inst_pairFreq(pair);
            else
                pairFreq(pair) = inst_pairFreq(pair);
                inst_unq_pairs(k) = 1;

            end
        end
          
        % add unique pairs to global unique pairs
        pairs = vertcat(pairs, inst_pairs(logical(inst_unq_pairs),:));
        
        % save only non empty instance pairs 
        count = count + 1;
        pairs_df = array2table(inst_pairs,'VariableNames',{'pair1','pair2','freq1','freq2','pair_freq'});
        writetable(pairs_df,file_out,'Sheet',count)

        waitbar(i / height(df), f, sprintf("computing pairs: %d/%d",i, height(df)));
    end

    delete(f)

    
    % iterate through all the words and update the 
    % frequency for all words across pairs 
    for n = 2:height(pairs)
        pairs{n,3} = wordFreq(pairs{n,1});
        pairs{n,4} = wordFreq(pairs{n,2});

        pair_concat = pairs{n,1} + pairs{n,2};
        pairs{n,5} = pairFreq(sort(pair_concat{1}));
    end

    % write global pairs 
    pairs_df = array2table(pairs(2:end,:),'VariableNames',{'pair1','pair2','freq1','freq2','pair_freq'});
    writetable(pairs_df,file_out,'Sheet',1);
    fprintf("Saved file as %s\n", file_out)
end

function [pairs, wordFreq, pairFreq] = extract_word_pairs(utterance, extraStopWords)
    % transform transcript rows into cell rows into a
    % flatten cell array 
    wordFreq = get_utterance_word_frequency(utterance, extraStopWords);
    uqWords = keys(wordFreq);
    uqWords = sort(uqWords);
    
    % initialize pair count
    pairFreq = dictionary(string.empty,double.empty);

    % initialize pair cell array
    uqNum = 1:numel(uqWords);
    pairs = cell(sum(uqNum)-numel(uqNum), 4);
    
    % get unique pairs , iterate through all unique words 
    idx = 1;
    for i = 1:numel(uqWords)
        % for every step shift the window of unique words
        % in order to only get new pairs 
        inner = numel(uqWords(i+1:end));
        for j = 1:inner
            % j here is not relative to i so the 
            % location of the target words in i is i+j
            word1 = uqWords(i);
            word2 = uqWords(i+j);

            pairs{idx, 1} = word1;
            pairs{idx, 2} = word2;

            pairs{idx, 3} = wordFreq(word1);
            pairs{idx, 4} = wordFreq(word2);
            
            pair = string(sort([word1{1}, word2{1}]));


            if isKey(pairFreq, pair)
               pairFreq(pair) = pairFreq(pair) + 1;
            else
               pairFreq(pair) = 1;
            end
            
            idx = idx + 1;
        end
    end
end