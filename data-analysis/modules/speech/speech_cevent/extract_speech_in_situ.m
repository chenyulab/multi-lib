%%%
% Author: Jane Yang
% Modifier: Jingwen Pang
% Last Modifier: 6/16/2025
% This function selects relevant target category instances in a cevent 
% variable and finds the utterances based on cevent variable's timestamps.
% 
% Input:
%   subexpID
%       -- int, experiment id or list of subjects
%
%   cevent_var
%       -- string, cevent variable name -- Defines the windows of time to 
%          extract data from.
%
%   categoty_list (1 x n matrix)
%
%   output_filename
%       -- string, output filename
%
%   args.overlap_percentage (int)
%       -- overlap_percentage define the overlap proportion between cevent data and
%          speech utterance, keep the utterance that is 
%          (overlap between cevent and utterance)/(cevent_length) > threhold
%
%   args.whence
%       -- string, 'start', 'end', or 'startend'
%       -- this parameter, when combined with args.interval, allows you to 
%          shift the args.cevent_name window times by a certain amount. 
%          The shift can be respect to the start, end, or full event.
%
%   args.interval
%       -- array of 2 numbers, [t1 t2], where t1 and t2 refer to the offset
%          to apply in each args.cevent_name window times.
%       -- e.g., [-5 1] and whence = 'start', then we take the onset of 
%          each cevent and add -5 seconds to get new onset. Likewise, we 
%          add 1 second to onset to get new offset.
%       -- therefore, if the original event was [45 55], then
%          if args.whence = 'start', then new event is [40 46]
%          if args.whence = 'end', then new event is [50 56]
%          if args.whence = 'startend', then new event is [40 56]
%
%   args.target_words
%       -- string cell array, list of keywords you want to extract
% 
%   args.extract_mode
%     -- string, define how you want to extract the utterance based on
%        target words
%        'individual': extract utterances contain any of the target words
%        'combine': extract utterances contain all the target words
%        'sequence': extract utterance contains target words in sequence
% 
% 
% Output: a table containing expID, subID, trial time ,onset and offset of 
%         cevent, category (objID), keywords, aggregated utterances,
%         and. 
%         A .CSV file is generated based on the output table.
%%%

function [extracted_data] = extract_speech_in_situ(subexpID,cevent_var,category_list,output_filename,args)
  
    colNames = {'subID','expID','onset','offset','category','trialsID','instanceID','trial_length','keywords','utterances'};
    sub_list = cIDs(subexpID);
    frame_rate = 30;
    defaultSpeechTime = 30;
    is_speech_timewindow = 0;

    %% parameter checking
    % check if 'whence' and 'interval'
    if ~exist('args', 'var') || isempty(args)
        args = struct([]);
    end

    if strcmp(cevent_var,'') && ~isfield(args, 'whence')
        is_speech_timewindow = 1;
    elseif strcmp(cevent_var,'') && isfield(args, 'whence')
        is_speech_timewindow = 2;
    end


    % threshold for filtering cevent instances overlap
    if isfield(args, 'min_dur')
        min_dur = args.min_dur;
    else
        min_dur = 0;
    end

    if isfield(args, 'max_dur')
        max_dur = args.max_dur;
    else
        max_dur = inf;
    end

    if isfield(args, 'overlap_percentage')
        overlap_percentage = args.overlap_percentage;
    else
        overlap_percentage = 0;
    end

    if isfield(args, 'whence')
        whence = args.whence;
    else
        whence = '';
    end

    if isfield(args, 'interval')
        interval = args.interval;
    else
        interval = [0 0];
    end

    if ~ isfield(args, 'target_words')
        target_words = {};
    else
        target_words = args.target_words;

        % Split each word by '+' and ' ', flatten result
        split_words = cellfun(@(w) regexp(w, '[+ ]', 'split'), target_words, 'UniformOutput', false);
        all_words = [split_words{:}];
        
        % Get unique keywords
        keyword_headers = unique(all_words);
    end

    overall_instance = [];
    overall_keywords_count = [];
    
    
    %% find cevent timestamps matching utterances
    for i = 1:size(sub_list,1)
        disp(sub_list(i));
        expID = sub2exp(sub_list(i));


        % get trial info
        trial_info = get_variable(sub_list(i),'cevent_trials');
        
        %% parse speech transcription file
        [~,speech_var] = parse_speech_trans(sub_list(i));
    
        % skip the subject if no speech transcription was found
        if size(speech_var,1) == 0
            continue
        end
    
        %% convert timestamps in speech transcription file to system time
        % speechTime = get_timing(sub_list(i)).speechTime; 
        extract_range_file = fullfile(get_subject_dir(sub_list(i)),'supporting_files','extract_range.txt');
        range_file = fopen(extract_range_file,'r');

        if range_file ~= -1
            extract_range_onset = fscanf(range_file, '[%f]');
            fclose(range_file); % Close the file after reading
        else
            error('Failed to open extract_range.txt');
        end

        trials = get_trial_times(sub_list(i));
        trial_length = sum(trials(:,2) - trials(:,1));

    
        % convert original timestamp to system time -- TODO: not sure if
        % all raw speech transcriptions have timestamps that are
        % inconsistent with the system time
        for j = 1:numel(speech_var)
            
            speech_var(j).start = speech_var(j).start + defaultSpeechTime - round(extract_range_onset/frame_rate,3);
            speech_var(j).end = speech_var(j).end + defaultSpeechTime - round(extract_range_onset/frame_rate,3);

            trial_id = find_trial_id(trial_info, speech_var(j).start);

            if is_speech_timewindow == 1
                instance = {sub_list(i), expID, speech_var(j).start, speech_var(j).end, 0, trial_id, j, trial_length};
                sub_utt = speech_var(j).words;
                instance = [instance, {'None'}, {sub_utt}];
                
                if ~isempty(target_words)
                    % calculate basic token measures per matching instance
                    
                    count_vec = count_target_words(keyword_headers,speech_var(j).words);
                    
                    overall_keywords_count = [overall_keywords_count;count_vec];
                end
                overall_instance = [overall_instance;instance];
                
            elseif is_speech_timewindow == 2
                onset = speech_var(j).start;
                offset = speech_var(j).end;
                % shift timestamps accordingly
                if strcmp(whence,'start')
                    old_onset = onset;
                    onset = onset + interval(1);
                    offset = old_onset + interval(2);
                elseif strcmp(whence,'end')
                    old_offset = offset;
                    offset = offset + interval(2);
                    onset = old_offset + interval(1);
                elseif strcmp(whence,'startend')
                    onset = onset + interval(1);
                    offset = offset + interval(2);
                end

                utt_list = [];
                % iterate each cevent
                %% find timestamps that matches the category
                for k = 1:size(onset,1)
                    overlap_prop1 = [];
                    overlap_prop2 = [];
                    bt = onset(k);
                    et = offset(k);

        
                    % find utterance timestamps that falls within bt-et range
                    utt_onset = [speech_var.start];
                    utt_offset = [speech_var.end];
                    dur = utt_offset - utt_onset; % duration of the speech utterance
                    % case 1: naming started after base cevent + with >50%
                    % overlap --> onset of naming is in between onset/offset of
                    % base cevent
                    index1 = find(utt_onset >= bt & utt_onset <= et);
                    overlap_prop1 = abs(utt_onset(index1) - et) /(et - bt);
                    index2 = overlap_prop1 > overlap_percentage;
                    index3 = index1(index2);
    
                    % case 2: naming started before base cevent + with >50%
                    % overlap --> offset of naming is in between onset/offset of
                    % base cevent
                    index4 = find(utt_offset >= bt & utt_offset <= et);
                    overlap_prop2 = (utt_offset(index4)-bt) /(et - bt);
                    index5 = overlap_prop2 > overlap_percentage;
                    index6 = index4(index5);
    
                    % case 3: naming overlap base cevent --> onset is before
                    % base event onset and the offset is after event offset
                    index7 = find(utt_onset <= bt & utt_offset >= et);
                    match_idx = union(union(index3,index6),index7);
        
                    sub_utt = "";
        
                    for m = 1:numel(match_idx)
                        utt1 = speech_var(match_idx(m)).words;
                        sub_utt = sub_utt + utt1 + "; ";
                    end
    
                    utt_list = [utt_list;cellstr(sub_utt)];
                    % create one instance per instance in cevent_var
                    instance = [sub_list(i) expID bt et 0 trial_id j trial_length];
    
                    if ~isempty(target_words)
                        % calculate basic token measures per matching instance
                        count_vec = count_target_words(keyword_headers,sub_utt);
                        overall_keywords_count = [overall_keywords_count;count_vec];
                    end
    
                    % append utterance to the end
                    instance = horzcat(instance,sub_utt);     
                    % append new instance to a list of instances
                    overall_instance = [overall_instance;instance];
    
                end
            end
        end

    
        if ~is_speech_timewindow
            % get timestamps of cevent variable
            cevent = get_variable_by_trial_cat(sub_list(i),cevent_var);
            if isempty(cevent)
                warning('%d variable data is empty!',sub_list(i))
                continue
            end

            % Append sequential index as a new column (instanceID)
            cevent = [cevent, (1:size(cevent,1))'];
            
            %% iterate thru categories
            for id = 1:numel(category_list)
                cat = category_list(id);
                
                % find category relevant instances in cevent_var
                onset = cevent(cevent(:,3)==cat,1);
                offset = cevent(cevent(:,3)==cat,2);
                instance_ids = cevent(cevent(:,3)==cat, 4);

                onset_raw = onset;
    
                % shift timestamps accordingly
                if strcmp(whence,'start')
                    old_onset = onset;
                    onset = onset + interval(1);
                    offset = old_onset + interval(2);
                elseif strcmp(whence,'end')
                    old_offset = offset;
                    offset = offset + interval(2);
                    onset = old_offset + interval(1);
                elseif strcmp(whence,'startend')
                    onset = onset + interval(1);
                    offset = offset + interval(2);
                end
    
                utt_list = [];
                % iterate each cevent
                %% find timestamps that matches the category
                for k = 1:size(onset,1)
                    overlap_prop1 = [];
                    overlap_prop2 = [];
                    bt = onset(k);
                    et = offset(k);

                    bt_raw = onset_raw(k);

                    % check cevent duration
                    cevent_dur = et - bt;
                    if cevent_dur < min_dur || cevent_dur > max_dur
                        continue
                    end

                    trial_id = find_trial_id(trial_info, bt_raw);
                    
        
                    % find utterance timestamps that falls within bt-et range
                    utt_onset = [speech_var.start];
                    utt_offset = [speech_var.end];
                    dur = utt_offset - utt_onset; % duration of the speech utterance
                    % case 1: naming started after base cevent + with >50%
                    % overlap --> onset of naming is in between onset/offset of
                    % base cevent
                    index1 = find(utt_onset >= bt & utt_onset <= et);
                    overlap_prop1 = abs(utt_onset(index1) - et)/(et - bt);
                    index2 = overlap_prop1 > overlap_percentage;
                    index3 = index1(index2);
    
                    % case 2: naming started before base cevent + with >50%
                    % overlap --> offset of naming is in between onset/offset of
                    % base cevent
                    index4 = find(utt_offset >= bt & utt_offset <= et);
                    overlap_prop2 = (utt_offset(index4)-bt)/(et - bt);
                    index5 = overlap_prop2 > overlap_percentage;
                    index6 = index4(index5);
    
                    % case 3: naming overlap base cevent --> onset is before
                    % base event onset and the offset is after event offset
                    index7 = find(utt_onset <= bt & utt_offset >= et);
                    match_idx = union(union(index3,index6),index7);
        
                    sub_utt = "";
        
                    for m = 1:numel(match_idx)
                        utt1 = speech_var(match_idx(m)).words;
                        sub_utt = sub_utt + utt1 + "; ";
                    end
    
                    utt_list = [utt_list;cellstr(sub_utt)];
                    % create one instance per instance in cevent_var
                    instance = [sub_list(i) expID bt et cat trial_id instance_ids(k) trial_length];
    
                    if ~isempty(target_words)
                        % calculate basic token measures per matching instance
                        count_vec = count_target_words(keyword_headers,sub_utt);
                        overall_keywords_count = [overall_keywords_count;count_vec];
                    end
    
                    % append utterance to the end
                    instance = horzcat(instance,sub_utt);     
    
                    % append new instance to a list of instances
                    overall_instance = [overall_instance;instance];
    
                end
            end
        end
        
        
    end
    

    if ~isempty(overall_instance)
    if ~isempty(target_words)
        % check the first element in this function determine the
        % extract_mode
        extracted_data = extract_data_by_mode(target_words, overall_instance, overall_keywords_count, keyword_headers);
    else
        extracted_data = overall_instance;
        extracted_data(:,end+1) = extracted_data(:,end);
        extracted_data(:,end-1) = {'None'};
    end
    if ~isempty(extracted_data)

        [~, order] = sort(str2double(extracted_data(:,4)));
        extracted_data = extracted_data(order, :);
        extracted_data = sortrows(extracted_data,1);  % sort based on the subject id
    end

    else
        extracted_data = [];
    end


    % don't write to a CSV file if the function is used as an intermediate
    % helper function
    if ~strcmp(output_filename,'')
        summary_table = array2table(extracted_data,'VariableNames',colNames);
        writetable(summary_table,sprintf('%s.csv',output_filename(1:end-4)));
    end

end


function extracted_all = extract_data_by_mode(word_list, overall_instance, overall_keywords_count, keyword_headers)
    extracted_all = {};  % collect all extracted data
    for w = 1:length(word_list)
        word_entry = word_list{w};
        if contains(word_entry, '+')
            target_words = split(word_entry, '+');
            extract_mode = 'combine';
        elseif contains(word_entry, ' * ')
            % Wildcard pattern: e.g., "a * bear"
            target_words = split(word_entry, ' ');
            extract_mode = 'wildcard_sequence';
        elseif contains(word_entry, ' ')
            target_words = split(word_entry, ' ');
            extract_mode = 'sequence';
        else
            target_words = {word_entry};
            extract_mode = 'individual';
        end

        % Get indices of keywords in the header (skip for wildcard)
        if ~strcmp(extract_mode, 'wildcard_sequence')
            idx_keywords_raw = cellfun(@(w) find(strcmp(keyword_headers, w), 1, 'first'), target_words, 'UniformOutput', false);
            idx_keywords = cell2mat(idx_keywords_raw);
        end

        % Extract based on mode
        if strcmp(extract_mode, 'individual')
            idx = overall_keywords_count(:, idx_keywords) > 0;
            extracted_data = overall_instance(idx, :);
            matched_words = target_words;

        elseif strcmp(extract_mode, 'combine')
            idx = overall_keywords_count(:, idx_keywords(1)) > 0;
            for i = 2:length(idx_keywords)
                idx = idx & (overall_keywords_count(:, idx_keywords(i)) > 0);
            end
            extracted_data = overall_instance(idx, :);
            matched_words = repmat({strjoin(target_words, '+')}, sum(idx), 1);
        elseif strcmp(extract_mode, 'sequence')
            sequence_phrase = strjoin(target_words, ' ');
            idx = contains(overall_instance(:, end), sequence_phrase);
            extracted_data = overall_instance(idx, :);
            matched_words = repmat({strjoin(target_words, ' ')}, sum(idx), 1);
        elseif strcmp(extract_mode, 'wildcard_sequence')
            first_word = lower(target_words{1});
            last_word = lower(target_words{end});

            % Step 1: Use 'combine'-style check to get utterances that contain both words
            idx_first = overall_keywords_count(:, strcmp(keyword_headers, first_word)) > 0;
            idx_last  = overall_keywords_count(:, strcmp(keyword_headers, last_word)) > 0;
            idx = idx_first & idx_last;

            filtered_data = overall_instance(idx, :);
            matched_rows = false(size(filtered_data, 1), 1);

            % Step 2: For each matching row, check if there's exactly one word between first and last
            for i = 1:size(filtered_data, 1)
                utterance = lower(filtered_data{i, end});  % Get utterance text
                words = split(utterance);

                for j = 1:(length(words)-2)
                    if strcmp(words{j}, first_word) && strcmp(words{j+2}, last_word)
                        matched_rows(i) = true;
                        break;
                    end
                end
            end

            % Keep only rows with exact wildcard match
            extracted_data = filtered_data(matched_rows, :);
            matched_words = repmat({strjoin(target_words, ' ')}, sum(matched_rows), 1);
        else
            error('Unknown extract_mode: %s', extract_mode);
        end

        % Append matched word(s) as a new column
        if ~isempty(extracted_data)
            extracted_data(:, end+1) = extracted_data(:, end);  % duplicate last col
            extracted_data(:, end-1) = matched_words;
            extracted_all = [extracted_all; extracted_data];
        end
    end
end

function trial_id = find_trial_id(trial_info, onset_time)


    idx = onset_time >= trial_info(:,1) & onset_time <= trial_info(:,2);

    if any(idx)
        trial_id = trial_info(idx, 3);
    else
        trial_id = 0; % or 0 or -1, depending on how you want to handle "no match"
    end
end