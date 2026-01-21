function make_child_utterance_by_whisper(subIDs)
    for s = 1:length(subIDs)
        subID = subIDs(s);
        % check whether input transcription is in Spanish
        if ~exist('isSpanishhave_obj', 'var')
            isSpanishhave_obj = 0;
        end
        
        % get input whisper transcription file from speech_transcription folder from the subject
        root = get_subject_dir(subID);
        subTable = read_subject_table();
        kidID = subTable(subTable(:,1)==subID,4);
        trans_fileList = dir(fullfile(root,'speech_transcription_p',sprintf('speech_%d_child.txt',kidID)));
    
        if ~isempty(trans_fileList)
            input_filename = trans_fileList.name;
            
            % get word-object mapping file from the experiment folder
            sub_info = get_subject_info(subID);
            expID = sub_info(2);
            map_fileList = dir(fullfile(get_multidir_root,sprintf('experiment_%d',expID),'object_word_pairs_child.xlsx'));
    
            word_object_mapping_filename = map_fileList.name;
            
            % parse input transcription file
            % [~,utterances] = speech_trans_to_array(fullfile(trans_fileList.folder,input_filename));
            trans_table = readtable(fullfile(trans_fileList.folder,input_filename));
            onset = table2array(trans_table(:,1));
            offset = table2array(trans_table(:,2));
            utterances = table2array(trans_table(:,3));
            
            % load trialInfo
            trialInfo_path = get_info_file_path(subID);
            trialInfo = load(trialInfo_path);
            
            % obtain speechTime for timing conversion
            speechTime = trialInfo.trialInfo.speechTime;
            
            % correct transcription timestamp to system time
            onset = onset + speechTime;
            offset = offset + speechTime;
            
            % parse word-object mapping file
            mapping = readtable(fullfile(map_fileList.folder,word_object_mapping_filename));
    
            % get number of object
            word_obj_name = mapping.obj;
            unique_word_obj_name = unique(word_obj_name);
            n_of_obj = get_num_obj(expID);
            
            % initialize an array for holding matching naming instances
            cevent_naming = [];
            cevent_utterance = [];
            cevent_vocalx_only = [];
            cevent_non_naming_only = [];
            cevent_vocalx_non_naming = [];
            
            % check which words in word-object mapping can be a superordinate word,
            % e.g. animal --> can map to any animal stimuli
            names = mapping.name;
            N = arrayfun(@(k) sum(arrayfun(@(j) isequal(names{k}, names{j}), 1:numel(names))), 1:numel(names));
            unique_elements = names(N==1);
            unique_elements_objID = mapping.obj_id(N==1);
            % duplicated_elements = unique(names(N>1)); % output blank for objID if finds a superordinate word
    
            
            % iterate thru each utterance
            for i = 1:length(utterances)
                
                currUtt = utterances(i);
                % split the string into words
                words = split(currUtt,' ');
        
                have_obj = 0;
                % iterate through target word list and find matches
                for j = 1:height(unique_elements)
                    num_match = sum(strcmp(words,unique_elements(j)));
        
                    % check if there's any matching
                    if num_match ~= 0
                        % create instances for matching cases
                        naming_id = repmat(unique_elements_objID(j),num_match,1);
                        match_entry = horzcat(repmat(onset(i),num_match,1),repmat(offset(i),num_match,1),repmat(unique_elements_objID(j),num_match,1));
                        cevent_naming = vertcat(cevent_naming,match_entry);
                        cevent_utterance = vertcat(cevent_utterance,match_entry);
                        have_obj = 1;
                    end
                end
    
                % non-naming
                if have_obj == 0
                    match_entry = horzcat(onset(i),offset(i),(n_of_obj + 1));
                    cevent_utterance = vertcat(cevent_utterance,match_entry);
    
                    % group non-naming utterance into 3 category based on vocalx
                    if isscalar(unique(words))
                        if strcmp(unique(words),'vocalx')
                            cevent_vocalx_only = vertcat(cevent_vocalx_only,match_entry);
                        else
                            cevent_non_naming_only = vertcat(cevent_non_naming_only,match_entry);
                        end
                    elseif contains('vocalx',words)
                        cevent_vocalx_non_naming = vertcat(cevent_vocalx_non_naming,match_entry);
                    else
                        cevent_non_naming_only = vertcat(cevent_non_naming_only,match_entry);
                    end
    
                end
            end
    
            % get trial time
            trial_times = get_trial_times(subID);
            begin_time = trial_times(1,1);
            end_time = trial_times(end,2);
    
            rate = get_rate(subID);
            % record naming variable
            cstream_naming = cevent2cstream(cevent_naming,begin_time,1/rate,0,end_time);
            record_additional_variable(subID,'cevent_speech_naming_local-id_child',cevent_naming);
            record_additional_variable(subID,'cstream_speech_naming_local-id_child',cstream_naming);
    
            % record utterance variable
            cstream_utterance = cevent2cstream(cevent_utterance,begin_time,1/rate,0,end_time);
            record_additional_variable(subID,'cevent_speech_utterance_child',cevent_utterance);
            record_additional_variable(subID,'cstream_speech_utterance_child',cstream_utterance);
    
            % record speech_vocalx-only variable
            cstream_vocalx_only = cevent2cstream(cevent_vocalx_only,begin_time,1/rate,0,end_time);
            record_additional_variable(subID,'cevent_speech_vocalx-only_child',cevent_vocalx_only);
            record_additional_variable(subID,'cstream_speech_vocalx-only_child',cstream_vocalx_only);        
    
            % record speech_non-naming-only variable
            cstream_non_naming_only = cevent2cstream(cevent_non_naming_only,begin_time,1/rate,0,end_time);
            record_additional_variable(subID,'cevent_speech_non-naming-only_child',cevent_non_naming_only);
            record_additional_variable(subID,'cstream_speech_non-naming-only_child',cstream_non_naming_only);  
    
            % record speech_vocalx-and-non-naming variable
            cstream_vocalx_non_naming = cevent2cstream(cevent_vocalx_non_naming,begin_time,1/rate,0,end_time);
            record_additional_variable(subID,'cevent_speech_vocalx-and-non-naming_child',cevent_vocalx_non_naming);
            record_additional_variable(subID,'cstream_speech_vocalx-and-non-naming_child',cstream_vocalx_non_naming);
        else
            fprintf('Subject %d does not have a valid speech transcription .txt file.\n',subID);
        end
    end
end