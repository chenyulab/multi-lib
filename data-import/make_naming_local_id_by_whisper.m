%%%
% Author: Jane Yang
% Last Modified: 11/03/2023
% This function reads in a speech transcription .txt file and a word-object
% mapping .csv file, outputting a .csv or .txt file containing instances
% where a target object referent word was mentioned in the speech utterance.
% If a target word appears multiple times in one utterance, multiple
% instances will be recorded in the output file. Object ID for
% superordinate words, e.g. "animal" can refer to multiple stimuli, 
% is IGNORED for now.
%
% Input: subID --> subject ID
%        word_object_mapping_filename --> Nx3 .csv file containing
%                                         word-object mapping info of an
%                                         experiment
%
% Output: generate cevent/cstream_naming_local_id variables under subject's
% derived folder
% 
% Sample word_object_mapping_filename: 'exp351_word_object_pairs.csv' 
%                                       obj	obj_id	name
%                                       face	1	face
%                                       kettle	2	kettle
%                                       cat	    3	cat
%                                       cat	    3	kitty
%                                       cat	    3	animal
%
% Helper function called: speech_trans_to_array.m
% 
% Example function call: make_naming_local_id_by_whisper(35101)
% for Spanish transcriptions: make_naming_local_id_by_whisper(35101,1)
%%%

function [cevent_naming,cstream_naming] = make_naming_local_id_by_whisper(subID,isSpanishFlag)
    % check whether input transcription is in Spanish
    if ~exist('isSpanishFlag', 'var')
        isSpanishFlag = 0;
    end
    
    % get input whisper transcription file from speech_transcription folder from the subject
    root = get_subject_dir(subID);
    subTable = read_subject_table();
    kidID = subTable(subTable(:,1)==subID,4);
    trans_fileList = dir(fullfile(root,'speech_transcription_p',sprintf('speech_%d.txt',kidID)));

    if ~isempty(trans_fileList)
        input_filename = trans_fileList.name;
        
        % get word-object mapping file from the experiment folder
        sub_info = get_subject_info(subID);
        expID = sub_info(2);
        if ismember(expID,[77,78,79])
            map_fileList = dir(fullfile(get_multidir_root,'experiment_77','exp77_object_word_pairs.xlsx'));
        elseif ismember(expID,80)
            map_fileList = dir(fullfile(get_multidir_root,sprintf('experiment_%d',expID),'exp80_object_word_pairs.xlsx'));
        elseif ismember(expID,58)
            map_fileList = dir(fullfile(get_multidir_root,sprintf('experiment_%d',expID),'exp58_object_word_pairs.xlsx'));
        else
            if ~isSpanishFlag % English transcription
                map_fileList = dir(fullfile(get_multidir_root,sprintf('experiment_%d',expID),'object_word_pairs.xlsx'));
            else % Spanish transcription
                map_fileList = dir(fullfile(get_multidir_root,sprintf('experiment_%d',expID),'object_word_pairs_spanish.xlsx'));
            end
        end

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
        
        % initialize an array for holding matching naming instances
        cevent_naming = [];
        
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
    
            % iterate through target word list and find matches
            for j = 1:height(unique_elements)
                num_match = sum(strcmp(words,unique_elements(j)));
    
                % check if there's any matching
                if num_match ~= 0
                    % create instances for matching cases
                    match_entry = horzcat(repmat(onset(i),num_match,1),repmat(offset(i),num_match,1),repmat(unique_elements_objID(j),num_match,1));
                    cevent_naming = vertcat(cevent_naming,match_entry);
                end
            end
        end
        % get trial time
        trial_times = get_trial_times(subID);
        begin_time = trial_times(1,1);
        end_time = trial_times(end,2);

        rate = get_rate(subID);
        cstream_naming = cevent2cstream(cevent_naming,begin_time,1/rate,0,end_time);
        record_variable(subID,'cevent_speech_naming_local-id',cevent_naming);
        record_variable(subID,'cstream_speech_naming_local-id',cstream_naming);
    else
        fprintf('Subject %d does not have a valid speech transcription .txt file.\n',subID);
    end
end