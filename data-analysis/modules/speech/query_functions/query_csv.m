%%% Helper function to generate csv file for queried words
function final_table = query_csv(word_list, expID_list,filename,window,cam)
    if nargin < 4
        window = 0;
    end

    % source camera default: cam07
    if nargin < 5
        cam = 7;
    end

    if numel(word_list) == 0
        error('[-] Error: Invalid word input. Please enter at least one word to query.')
    end

    if numel(expID_list) == 0
        error('[-] Error: Invalid experiment input. Please enter at least one experiment to query.')
    end

    if window < 0
        error('[-] Error: Window needs to be a non-negative number.')
    end

    colNames = {'subID','fileID','onset','onset_frame','offset','offset_frame','word','word_ID','utterances'};
  
    colNames{end+1} = 'source_video_path';

    % read the table containing wordID of all unique lemmatized words
    voc_table = readtable('voc_list_original.csv');

    % convert word_list to wordID_list before search for matching words in
    % transcription
    wordID_list = [];
    for word = word_list
        if sum(ismember(voc_table.word,word))
            wordID_list(end+1) = voc_table.wordID(find(ismember(voc_table.word,word)));
        else
            error('[-] Error: Couldn''t find word: %s does not exist in the vocabulary list\n',word);
        end
    end


    % read/parse speech transcription for each experiment
    speech_trans = [];

    
    sub_list = find_subjects('speech_trans_new',expID_list);
    
    overall_mtr = zeros(0,numel(colNames));
    
    for k = 1:numel(wordID_list)
        % initialize a matrix that will hold all the queried word timestamps
        rtr_matrix = zeros(0,numel(colNames));
         
        for i = 1:numel(sub_list)
            speech_trans = get_variable(sub_list(i),'speech_trans_new').uts;
            root = get_subject_dir(sub_list(i));

            for j = 1:numel(speech_trans)
                match_matrix = ismember(wordID_list(k),speech_trans(j).words);

                if sum(match_matrix)~=0
                    onset_list = speech_trans(j).bt;
                    offset_list = speech_trans(j).et;

                    % get beginning and end trial frame number
                    trial_timing = get_trials(sub_list(i));
                    trial_start = trial_timing(:,1);
                    trial_end = trial_timing(:,2);
                    within_trial = time2frame_num(onset_list, sub_list(i)) >= trial_start & time2frame_num(onset_list, sub_list(i)) <= trial_end;

                    if sum(within_trial == 1)
                        kid_info = get_subject_info(sub_list(i));
                        vid_folder_name = sprintf('cam%02d_frames_p\\',cam);
                        src_vid_path = fullfile(root,vid_folder_name);
                        timestamp = [onset_list,time2frame_num(onset_list, sub_list(i)), offset_list, time2frame_num(offset_list, sub_list(i))];
                        fileID = sprintf('__%d_%d',kid_info(3),kid_info(4));

                        utterances = "";

                        for id = 1:numel(speech_trans(j).words)
                            word_tmp = voc_table.word(find(ismember(voc_table.wordID,speech_trans(j).words(id))));
                            utterances = append(utterances,' ',word_tmp{1});
                        end
                        
                        utterances = strtrim(utterances);
                        instance = cat(2,sub_list(i),fileID,timestamp,word_list(k),wordID_list(k),utterances,src_vid_path);

                        % append to final return matrix
                        rtr_matrix = [rtr_matrix;instance];

                        overall_mtr = [overall_mtr;instance];
                    else
                        fprintf('Time %f is not within trial for subject %d!\n',onset_list,sub_list(i));
                    end
                end
            end
        end
        query_mtr{k} = rtr_matrix;
        % returns per exp. [subID, onset, offset, word, wordID,...]
        query_word_table = array2table(rtr_matrix,'VariableNames',colNames);
        writetable(query_word_table,word_list(k)+'.csv','WriteVariableNames', true);
    end




    % find timing intersections within time window constraint
    if (size(query_mtr{1},1) ~= 0)
        unique_sub = unique(query_mtr{1}(:,1));
        updated_mtr = [];
    
        curr_mtr = query_mtr{1};
        for i = 2 : size(query_mtr,2)
            for j = 1:numel(unique_sub)
                word1_mtr = curr_mtr(curr_mtr(:,1)==unique_sub(j),:);
                word2_mtr = query_mtr{i}(query_mtr{i}(:,1)==unique_sub(j),:);
    
                if numel(word2_mtr) ~=0
                    diff_mtr = str2double(word2_mtr(:,3)).' - str2double(word1_mtr(:,3));
                    [match_ind_word1,match_ind_word2] = find(diff_mtr <=window & diff_mtr >=0);
    
                    if (match_ind_word1 ~=0 & match_ind_word2 ~=0)
                        updated_mtr = [updated_mtr; [word1_mtr(match_ind_word1,1:end-1) word2_mtr(match_ind_word2,3:end)]];
                    end
                end
            end

            % check if any common has been found, break out of the loop if not
            
            curr_mtr = updated_mtr;
            updated_mtr = [];

            if (size(curr_mtr,2) < 3+6*i)
                fprintf('No instances found within timing constraints: within %d.',window);
                curr_mtr = [];
                break;
            end
        end
    end


    final_colNames = {'subID','fileID'};

    
    % if querying multiple words, expand the column list
    for i = 1:numel(word_list)
          word_col = {sprintf('onset%d',i),sprintf('onset%d_frame',i),sprintf('offset%d',i),sprintf('offset%d_frame',i),sprintf('word%d',i),sprintf('word%d_ID',i),sprintf('utterances%d',i)};
          final_colNames = [final_colNames word_col];
    end

    final_colNames{end+1} = 'source_video_path';

    final_table = array2table(curr_mtr,'VariableNames',final_colNames);
    writetable(final_table,filename,'WriteVariableNames', true);
end
