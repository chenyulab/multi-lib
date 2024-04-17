%%
% Author: Jane Yang
% Last modified: 12/05/2023
% This function takes in a list of subjects, a speech keyword, and optional
% arguments for manipulating timestamps, outputting a detailed csv 
% containing instances where the target keyword was found in speech 
% transcription. 
%
% Input: Name                       Description
%        expIDs                     a list of expIDs
%
%        word_list                  a list of target word(s) to query
%
%        output_filename            output filename for the returned csv      
%
%        args.cam                   the source camera the event clips use,
%                                   default is cam07 (kid's view)
%
%        args.whence                string, 'start', 'end', or 'startend'
%                                   this parameter, when combined with args.interval, 
%                                   allows you to shift the args.cevent_name window times by a certain amount. 
%                                   The shift can be respect to the start, end, or full event.
%
%        args.interval              array of 2 numbers, [t1 t2], 
%                                   where t1 and t2 refer to the offset to apply in each args.cevent_name window times.
%
% Output: a csv file containing timestamp and source camera information for
% instancs found.
% 
% Example function call: rtr_table = query_keywords([12],{'babyname'},'M:\event_clips\test','test-babyname.csv',args)

function rtr_table = query_keywords(expIDs,word_list,output_dir,output_filename,args)
    % check if optional argument exists
    if ~exist('args', 'var') || isempty(args)
        args = struct([]);
        whence = '';
        interval = [0 0];
    end

    if isfield(args,'whence') && isfield(args,'interval')
        whence = args.whence;
        interval = args.interval;
    elseif isfield(args,'whence') && ~isfield(args,'interval')
        error('Please enter an interval parameter with whence parameter.');
    end

    if isfield(args,'cam')
        cam = args.cam;
    else
        cam = 7; % default to cam07 --> kid's view
    end

    if numel(word_list) == 0
        error('[-] Error: Invalid word input. Please enter at least one word to query.')
    end

    if numel(expIDs) == 0
        error('[-] Error: Invalid experiment input. Please enter at least one experiment to query.')
    end

    % initialize column names for return table
    %%% TODO: change to a more flexible way of initializing column names
    %%% later --> for multiple words
    colNames = {'subID','fileID',...
                'onset1_transcription_time','onset1_system_time','onset1_frame',...
                'offset1_transcription_time','offset1_system_time','offset1_frame',...
                'word1','utterances1','source_video_path','source_audio_path','extract_range_onset'};

    % get a list of subjects that has a speech transcription
    subs = list_subjects(expIDs);
    
    % iterate through each target word
    for w = 1:length(word_list)
        % initialize a return table
        rtr_table = table();

        % save current target word to query
        curr_target_word = word_list(w);

        % iterate through subjects in the experiment list
        for s = 1:size(subs,1)
            subID = subs(s);
            root = get_subject_dir(subID);
            subInfo = get_subject_info(subID);
            fileID = cellstr(sprintf('__%d_%d',subInfo(3),subInfo(4)));
            kidID = subInfo(end);
            speechFile = fullfile(root,'speech_transcription_p',sprintf('speech_%d.txt',kidID));

            % check if the subject has a speech transcription file
            if ~isfile(speechFile)
                sprintf('Subject %d does not have a speech transcription file, skipping over subject %d!',subID);
            else
                speech = readtable(speechFile); % parse speech transcription file into a table
                utts = speech{:,3};
                onset = speech{:,1};
                offset = speech{:,2};

                % initialize an empty array to hold indices for matching
                % utterances
                index = [];


                % iterate thru each utterance
                for i = 1:size(utts,1)
                    currUtt = utts(i);
                    % split the string into words
                    words = split(currUtt,' ');

                    % iterate through target word list and find matches
                    num_match = sum(strcmp(words,curr_target_word));

                    % check if there's any matching
                    if num_match ~= 0
                        % create instances for matching cases
                        index = [index;i];
                    end
                end
                % find the utterances that contains the word
                match_utts = utts(index);
                match_onset = onset(index);
                match_offset = offset(index);

                % check if need to modify timestamps
                if ~isempty(whence)
                    if strcmp(whence,'start')
                        modified_onset = match_onset + interval(1);
                        modified_offset = match_onset + interval(2);
                    elseif strcmp(whence,'end')
                        modified_onset = match_offset + interval(1);
                        modified_offset = match_offset + interval(2);
                    elseif strcmp(whence,'startend')
                        modified_onset = match_onset + interval(1);
                        modified_offset = match_offset + interval(2);
                    end

                    % match_cevent = [];
                    match_onset = modified_onset;
                    match_offset = modified_offset;
                end

                % convert matched utterance timestamps in speech
                % transcription to system time
                timingInfo = get_timing(subID);
                speechTime = timingInfo.speechTime;
                trial_times = get_trial_times(subID);
                match_system_onset = match_onset + speechTime;
                match_system_offset = match_offset + speechTime;
                
                
                % intialize an empty array to store the combined within
                % trial indices
                trial_index_combined = [];
                % iterate through trials 
                for i = 1:size(trial_times,1)
                    trial_index = find(match_system_onset >= trial_times(i,1) & match_system_onset <= trial_times(i,2)); % onset&offset both within trial
                    trial_index_combined = [trial_index_combined;trial_index];
                end
                
                % filter out-of-trial instances
                match_onset = match_onset(trial_index_combined);
                match_offset = match_offset(trial_index_combined);
                match_utts = match_utts(trial_index_combined);
                match_system_onset = match_system_onset(trial_index_combined);
                match_system_offset = match_system_offset(trial_index_combined);

                % find corresponding timestamps in frame number
                match_onset_frames = time2frame_num(match_system_onset,subID);
                match_offset_frames = time2frame_num(match_system_offset,subID);

                % find video source path
                source_vid_path = cellstr(fullfile(root,sprintf('cam%02d_frames_p',cam)));

                % find audio source path
                audio_root = fullfile(root,'speech_r');
                audio_fileList = dir(fullfile(audio_root,'*.wav'));
                % check if audio file exists
                if ~isempty(audio_fileList)
                    % set the first audio file in the directory as source audio
                    source_aud_path = cellstr(fullfile(audio_fileList(1).folder,audio_fileList(1).name));
                else
                    sprintf('Subject %s does not have an audio file!',subID);
                    source_aud_path = {''};
                end
                

                % get extract range onset
                extract_range_file = fullfile(root,'supporting_files','extract_range.txt');
                range_file = fopen(extract_range_file,'r');
                extract_range_onset = fscanf(range_file,'[%f]');

                % setting up subject-level entry table
                subID_col = repmat(subID,length(match_onset),1);
                fileID_col = repmat(fileID,length(match_onset),1);
                word_col = repmat(curr_target_word,length(match_onset),1);
                source_vid_path_col = repmat(source_vid_path,length(match_onset),1);
                source_aud_path_col = repmat(source_aud_path,length(match_onset),1);
                extract_range_onset_col = repmat(extract_range_onset,length(match_onset),1);

                % create subject-level entry
                sub_entry = table(subID_col,fileID_col,...
                                  match_onset,match_system_onset,match_onset_frames,...
                                  match_offset,match_system_offset,match_offset_frames,...
                                  word_col,match_utts,source_vid_path_col,source_aud_path_col,...
                                  extract_range_onset_col,'VariableNames',colNames);
                % append to return table
                rtr_table = [rtr_table;sub_entry];
            end
        end
        % save table to a csv file
        writetable(rtr_table,fullfile(output_dir,output_filename),'WriteVariableNames', true);
    end
end
