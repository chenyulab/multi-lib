%%
% Author: Jane Yang
% Eidtor: Jingwen Pang
% Last modified: 11/11/2024
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
%        args.cam                   integer, the source camera the event clips use,
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
% See case 4, 8 in demo_speech_analysis_functions
%     case 1, 2, 6 in demo_query_csv_speech_or_event

function obj_rtr_table = query_keywords(expIDs,word_list,output_filename,args)
    speechTime = 30;
    frame_rate = 30;
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
    colNames = {'subID','fileID',...
                'onset_transcription_time','onset_system_time','onset_frame',...
                'offset_transcription_time','offset_system_time','offset_frame',...
                'word','utterances','source_video_path','source_audio_path','extract_range_onset'};

    % get a list of subjects that has a speech transcription
    subs = list_subjects(expIDs);
    
    % initialize a keywords return table
    obj_rtr_table = table();
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

            % get all the utterance that is within the trial
            [~,speech_str] = parse_speech_trans(subID);  % parse speech transcription file into a table
            if ~isempty(speech_str)
                speech = struct2table(speech_str);
                utts = speech{:,3};
                onset = speech{:,1};
                offset = speech{:,2};

                % initialize an empty array to hold indices for matching
                % utterances
                index = [];


                % iterate thru each utterance
                for i = 1:size(utts,1)
                    currUtt = utts(i);
                    % create a fake utterance to avoid other form of the target word
                    % e.g 'i am eating' count as 'eating', but 'eat i
                    % am eating' count eat as 2
                    fake_currUtt = [curr_target_word,' ',currUtt];
                    % split the string into words
                    word_table = wordCloudCounts(fake_currUtt);

                    % iterate through target word list and find matches
                    idx_match = strcmp(word_table.Word,curr_target_word);
                    num_match = table2array(word_table(idx_match,"Count"));
                    % check if there's any matching (exclude the appended keyword)
                    if num_match > 1
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

                % get extract range onset
                extract_range_file = fullfile(root,'supporting_files','extract_range.txt');
                range_file = fopen(extract_range_file,'r');

                if range_file ~= -1
                    extract_range_onset = fscanf(range_file, '[%f]');
                    fclose(range_file); % Close the file after reading
                else
                    error('Failed to open extract_range.txt');
                end

                % convert matched utterance timestamps in speech
                % transcription to system time
                match_system_onset = match_onset + speechTime - round(extract_range_onset/frame_rate,3);
                match_system_offset = match_offset + speechTime - round(extract_range_onset/frame_rate,3);
                

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
        obj_rtr_table = [obj_rtr_table;rtr_table];
    end
    writetable(obj_rtr_table,output_filename,'WriteVariableNames', true);
end
