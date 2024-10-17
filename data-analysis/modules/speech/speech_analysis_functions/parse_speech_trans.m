%%%
% Author: Jane Yang
% Editor: Jingwen Pang
% Last Modifier: 9/25/2024
% This function is a helper function for parsing raw speech transcription
% .TXT file in each subject. It takes subject ID as input, find and parse
% the speech_KID.txt file for the input subject. The function returns an
% char array of concatenated utterances in the speech transcription file,
% as well as returning a struct representing the speech transcription file.
% The returned struct contains the onset and offset of the utterance and
% list each utterance.
% 
% Input: subject ID
% Output: a char array of all utterances in the speech transcription
% concatenated together, a strut representation of speech transcription
%%%


function [all_words,utterances] = parse_speech_trans(subID, trial_time_mtr) 
    % Parse a speech transcription file
    speech_starting_time = 30;
    frame_rate = get_rate(subID);

    speech_dir = fullfile(get_subject_dir(subID), 'speech_transcription_p');
    sub_info = get_subject_info(subID);
    speech_entry = dir(fullfile(speech_dir, sprintf('speech_%d.txt',sub_info(4))));
    speech_path = fullfile(speech_dir, speech_entry.name);

    % get the speech time: if extract range txt file exist, pioritize using
    % it, if not, using the speech time in trial info
    extract_range_file = fullfile(get_subject_dir(subID),'supporting_files','extract_range.txt');
    if exist(extract_range_file, 'file') == 2
        range_file = fopen(extract_range_file,'r');
        extract_range_onset = fscanf(range_file,'[%f]');
        speechTime = speech_starting_time - extract_range_onset/frame_rate;
    else
        trialInfo_path = get_info_file_path(subID);
        trialInfo = load(trialInfo_path);
        speechTime = trialInfo.trialInfo.speechTime;
    end

    if isfile(speech_path)
        speech_file = fopen(speech_path);
        
        utterances = [];
        L = 0;
        all_words = '';
        
        while (1)
            line = fgetl(speech_file);
            
            % L = L + 1;
            
            if line == -1
                break
            end
        
            [timestamp,~,~,nextindex] = sscanf(line, '%f');

            % get subject's trial time
            if ~exist("trial_time_mtr","var")
                trial_time_mtr = get_trial_times(subID);
            end

            % check if an utterance is within trial
            flag = 0;
            for i = 1:size(trial_time_mtr,1)
                if timestamp(1) + speechTime >= trial_time_mtr(i,1) && timestamp(1) + speechTime <= trial_time_mtr(i,2)
                    flag = 1;
                end
            end

            if flag
                L = L + 1;
                utterances(L).start = timestamp(1);
                utterances(L).end = timestamp(2);
                utterances(L).words = line(nextindex:end);
                all_words = strcat(all_words, {' '},utterances(L).words);
            end
        end
    
        all_words = char(strtrim(all_words));
    
        fclose(speech_file);
    else
        fprintf('Subject %d does not have a speech transcription file.\n',subID);
        all_words = [];
        utterances = [];
    end
end