%%%
%
% This function takes text instances finds the local and global instance pairs
% and its corresponding word frequency 
% 
%
% Author: Elton Martinez
% Modifier: 
% Last modified: 3/3/2025
%
% Input parameters:
%   - file_in = path the input file
%   - text_col_num = the numeric location of the text column relative to the 
%              input file, note if just passing one column it will break 
%   - file_out = desired name of the output file, this function writes to  
%               multiple sheet within one file so use an xlsx ending 
%            
%
 
function extract_speech_pair_in_situ(file_in, text_col_num, file_out)
    % matlab makes noise when you write to a xlsx sheet
    warning('off', 'MATLAB:xlswrite:AddSheet') ;
    
    % read transcription 
    df = readtable(file_in, Delimiter=",");
    
    % initialize global pairs 
    pairs = cell(1,4);
    pairs{1,1} = 'NaN';
    pairs{1,2} = 'NaN';
    pairs{1,3} = 0;
    pairs{1,4} = 0;
    count = 1;
    
    % clean & prealocate xls file 
    pairs_df = array2table(pairs(2:end,:),'VariableNames',{'pair1','pair2','freq1','freq2'});
    writetable(pairs_df,file_out,'Sheet',1,'WriteMode','replacefile');
    
    % initialize word-freq dictionary 
    wordFreq = dictionary(string.empty,double.empty);
    pairDict = dictionary(string.empty,double.empty);
    
    % iterate through each instance of the df 
    for i = 1:height(df)
        % get the unique pairs for each instance 
        instance = df{i, text_col_num}{1};

        [inst_pairs, inst_wordFreq] = extract_word_pairs(instance);
        inst_words = keys(inst_wordFreq);

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
        % append each pair and update the word-freq dict 
        f = waitbar(0,'1','Name','appending pairs...',...
        'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
        
        inst_unq_pairs = zeros(height(inst_pairs),1);
        for j = 1:height(inst_pairs)
            
            % get pair data 
            word1 = inst_pairs{j, 1};
            word2 = inst_pairs{j, 2};

            % check if that pair is globally unique or not
            word_pair = word1+word2;
            
            if ~isKey(pairDict, word_pair)
                inst_unq_pairs(j) = 1;
                pairDict(word_pair) = 1;
            end

            waitbar(j/height(inst_pairs), f, sprintf('pairs %d/%d',j, height(inst_pairs)))

        end
        % add unique pairs to global unique pairs
        pairs = vertcat(pairs, inst_pairs(logical(inst_unq_pairs),:));
        
        % save only non empty instance pairs 
        count = count + 1;
        pairs_df = array2table(inst_pairs,'VariableNames',{'pair1','pair2','freq1','freq2'});
        writetable(pairs_df,file_out,'Sheet',count)
        
        delete(f)
    end
    
    % iterate through all the words and update the 
    % frequency for all words across pairs 
    for n = 2:height(pairs)
        pairs{n,3} = wordFreq(pairs{n,1});
        pairs{n,4} = wordFreq(pairs{n,2});
    end

    % write global pairs 
    pairs_df = array2table(pairs(2:end,:),'VariableNames',{'pair1','pair2','freq1','freq2'});
    writetable(pairs_df,file_out,'Sheet',1);
    fprintf("Saved file as %s\n", file_out)
end


function [pairs, wordFreq] = extract_word_pairs(utterance)
    % transform transcript rows into cell rows into a
    % flatten cell array 
    %df = readtable(file_in);
    wordFreq = get_utterance_word_frequency(utterance);
    uqWords = keys(wordFreq);
    uqWords = sort(uqWords);

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
            idx = idx + 1;
        end
    end
end
