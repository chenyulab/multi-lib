%%%
% Author: Jane Yang
% Last Modifier: 4/12/2024
% This function returns a CSV file containing the frequency of each word
% appeared in the subjects.
%
% Input: subID or expID, output_filename
% Output: a cell array containing word count table of each subject, a
%         string array containing the common words of subjects, and a table
%         of summary word count of all subjects. A .CSV file will be
%         generated based on summary word count table.
%%%

function rtr = get_word_count_matrix(subexpID,output_filename)
% TODO: check whether subexpID & output_filename were given

    % initialize an empty cell array to hold individual subject's word
    % count table
    individuals = {};
    
    
    subIDs = cIDs(subexpID);
    
    % iterate thru subjects
    for i = 1:size(subIDs,1)
        sub = subIDs(i);
        subInfo = sid2kid(sub);
        kidID = subInfo(2);

        % load subject's trial timestamp info
        trial_times = get_trial_times(sub);
    
        % get path to subject's speech transcription
        transFile = fullfile(get_subject_dir(sub),'speech_transcription_p',sprintf('speech_%d_system-time.txt',kidID));
    
        % check if subject has a speech transcription file
        if isfile(transFile)
            % parse transcription file
            trans = readtable(transFile);

            % only select within-trial utterances
            trial_index_combined = [];
            % iterate through trials 
            for t = 1:size(trial_times,1)
                trial_index = find(trans{:,1} >= trial_times(t,1) & trans{:,2} <= trial_times(t,2)); % onset&offset both within trial
                trial_index_combined = [trial_index_combined;trial_index];
            end
            trans = trans(trial_index_combined,:);

            words = string(strjoin(trans{:,end})); % join all utterances into a string array
            words = strsplit(words," "); % split into string arrays by space
    
            % lemmatize words in utterances
            updatedWords = normalizeWords(words,'Style','lemma','Language','en');
    
            % get subject-level word count
            subWordCount = wordCloudCounts(updatedWords);
            individuals{i} = sortrows(subWordCount,1); % sorted alphabetically
        else
            % speech transcription file doesn't exist
            sprintf("Subject %s does not have a speech transcription file.\n",sub);
            individuals{i} = table(); % use an empty table to indicate empty speech transcription file
        end
    end
    
    
    if size(subIDs,1)>1 % if the subject list has more than one subject
        % % iterate thru individual subject's word count table, find common
        % % words, and construct a bigger matrix for all subjects
        %
        % find common words across subjects
        common = intersect(individuals{1}{:,1},individuals{2}{:,1});
        all = vertcat(individuals{1}{:,1},individuals{2}{:,1});
        for k = 3:size(individuals,2)
            currTable = individuals{k};
            % check for empty individual subject's word count table
            if ~isempty(currTable)
                common = intersect(common,currTable{:,1});
                if isempty(common)
                    break;
                end
                all = [all;currTable{:,1}];
            end
        end
        % get all unique words across subjects
        all = unique(all);
    
        % find a list of non-common words across subjects
        nonCommon = setdiff(all,common);
    
        % initialize a NxM matrix, where N is the number of unique words across
        % subjects and M is the number of input subjects
        wordCountMtr = zeros(size(all,1),size(subIDs,1));
    
    
        % iterate thru each subject
        % construct return matrix for word counts across subjects
        % Follow by this order: common words --> non-common words
        for i = 1:size(subIDs,1)
            subTable = individuals{i};
            
            if ~isempty(subTable) % check if the subject has a non-empty speech transcription file
                % find count for common words
                subCommon = subTable{ismember(subTable{:,1},common),2};
        
                subNonCommon = zeros(size(nonCommon));
        
                % find count for noncommon words
                % subNonCommon = subTable{ismember(subTable{:,1},nonCommon),2};
                subNonCommonWords = nonCommon(ismember(nonCommon,subTable{:,1}));
                subNonCommonIdx = find(ismember(nonCommon,subTable{:,1}));
                subNonCommonCount = subTable{ismember(subTable{:,1},nonCommon),2};
                subNonCommon(subNonCommonIdx) = subNonCommonCount;
                subNonCommon(setdiff([1:size(subNonCommon)],subNonCommonIdx)) = 0;
        
                % construct subject-level word count matrix
                subWordCountMtr = vertcat(subCommon,subNonCommon);
        
                % save to overall (across all subjects) word count matrix
                wordCountMtr(:,i) = subWordCountMtr;
            else
                wordCountMtr(:,i) = zeros(size(all));
            end
        end
    
        % TODO: put together an overall return table
        % set table row to subID
        allWords = vertcat(common,nonCommon);
        rtr = horzcat(allWords,wordCountMtr);
        rtr = array2table(rtr);
        rtr.Properties.VariableNames = horzcat({'Word'},cellstr(string(subIDs')));
        %
        % wordTable = vertcat(common,nonCommon);
        % wordCountTable = table(wordCountMtr);
        % wordCountTable.Properties.VariableNames = cellstr(string(subIDs'));
        % rtr = join(wordTable,wordCountTable);
    
    else % only has one subject
        rtr = individuals{1};
        rtr = renamevars(rtr,["Word" "Count"],["Word" num2str(subIDs(1))]);
    end
    
    % get part of speech for each word in the matrix
    documents = tokenizedDocument(rtr{:,1});
    documents = addPartOfSpeechDetails(documents);
    tdetails = tokenDetails(documents);
    rtr = horzcat(rtr,tdetails(:,end));

    % write to csv
    writetable(rtr,output_filename);
end