%%%
% Author: Jane Yang
% Modifier: Jingwen Pang
% Last Modifier: 3/4/2025
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
%   args.threshold (int)
%       -- threshold for filtering cevent instances that are less than N 
%          seconds long
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
%       -- string, define how you want to extract the utterance based on
%          target words
%          'individual': extract utterances contain any of the target words
%          'combine': extract utterances contain all the target words
%          'sequence': extract utterance contains target words in sequence
% 
% Output: a table containing expID, subID, trial time ,onset and offset of 
%         cevent, category (objID), keywords, aggregated utterances,
%         and. 
%         A .CSV file is generated based on the output table.
%%%

function extracted_data = extract_speech_in_situ(subexpID,cevent_var,category_list,output_filename,args)
  
    colNames = {'expID','subID','trial time','onset','offset','category','keywords','utterances'};
    sub_list = cIDs(subexpID);
    expID = unique(sub2exp(sub_list));
    frame_rate = 30;
    defaultSpeechTime = 30;

    %% parameter checking
    if strcmp(cevent_var,'')
        cevent_var = 'cevent_speech_utterance';
    end

    % check if 'whence' and 'interval'
    if ~exist('args', 'var') || isempty(args)
        args = struct([]);
    end

    % threshold for filtering cevent instances that are less than N seconds long
    if isfield(args, 'threshold')
        threshold = args.threshold;
    else
        threshold = 0;
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

    if isfield(args, 'target_words')
        target_words_list = args.target_words;
        num_wordlist = length(target_words_list);
    else
        target_words_list = {};
        num_wordlist = 1;
    end

for w = 1:num_wordlist
    extract_mode = 'individual';
    if isempty(target_words_list)
        target_words = {};
    else
        target_words = target_words_list{w};
        target_words_split1 = split(target_words,'+');
        if length(target_words_split1) > 1
            extract_mode = 'combine';
            target_words = target_words_split1;
        else
            target_words_split2 = split(target_words,' ');
            if length(target_words_split2) > 1
                extract_mode = 'sequence';
                target_words = target_words_split2;
            else
                extract_mode = 'individual';
                target_words = {target_words};
            end
        end
    end


    overall_instance = [];
    overall_keywords_count = [];
    


    %% find cevent timestamps matching utterances
    for i = 1:size(sub_list,1)
        disp(sub_list(i));
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
        end
    
        % get timestamps of cevent variable
        cevent = get_variable_by_trial_cat(sub_list(i),cevent_var);
        if isempty(cevent)
            continue
        end
        
        %% iterate thru categories
        for id = 1:numel(category_list)
            cat = category_list(id);
            
            % find category relevant instances in cevent_var
            onset = cevent(cevent(:,3)==cat,1);
            offset = cevent(cevent(:,3)==cat,2);

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
                overlap_prop1 = abs(utt_onset(index1) - et)./dur(index1);
                index2 = overlap_prop1 > threshold;
                index3 = index1(index2);

                % case 2: naming started before base cevent + with >50%
                % overlap --> offset of naming is in between onset/offset of
                % base cevent
                index4 = find(utt_offset >= bt & utt_offset <= et);
                overlap_prop2 = (utt_offset(index4)-bt)./dur(index4);
                index5 = overlap_prop2 > threshold;
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
                instance = [expID sub_list(i) trial_length bt et cat];

                if ~isempty(target_words)
                    % calculate basic token measures per matching instance
                    count_vec = get_target_words_count(target_words,sub_utt);
    
                    overall_keywords_count = [overall_keywords_count;count_vec];
                end

                % append utterance to the end
                instance = horzcat(instance,sub_utt);     

                % append new instance to a list of instances
                overall_instance = [overall_instance;instance];

            end
        end


    end

    % extract the data based on the keyword
    if ~isempty(target_words)
        if length(target_words) == 1
            idx = overall_keywords_count(:,1) > 0;
            extracted_data = overall_instance(idx,:);
            extracted_data(:,end+1) = extracted_data(:,end);
            extracted_data(:,end-1) = target_words{1};            
        else
            
            
            if strcmp(extract_mode,'individual')
                idx = overall_keywords_count(:,1) > 0;
                for i = 2:length(target_words)
                    idx_2 = overall_keywords_count(:,i) > 0;
                    idx = idx | idx_2;
                end
                extracted_data = overall_instance(idx,:);
                extracted_keywords_count = overall_keywords_count(idx,:);
                extracted_keywords_count(extracted_keywords_count ~= 0) = 1;
                extracted_data(:,end+1) = extracted_data(:,end);
                for i = 1:size(extracted_data,1)
                    extracted_data(i,end-1) = {strjoin(target_words(extracted_keywords_count(i,:) == 1), ',')};
                end
            elseif strcmp(extract_mode,'combine')
                idx = overall_keywords_count(:,1) > 0;
                for i = 2:length(target_words)
                    idx_2 = overall_keywords_count(:,i) > 0;
                    idx = idx & idx_2;
                end
                extracted_data = overall_instance(idx,:);
                extracted_data(:,end+1) = extracted_data(:,end);
                extracted_data(:,end-1) = {strjoin(target_words, ',')};
            elseif strcmp(extract_mode,'sequence')
                sequence_words = strjoin(target_words,' ');
                idx = contains(overall_instance(:,end),sequence_words);
                extracted_data = overall_instance(idx,:);
                extracted_data(:,end+1) = extracted_data(:,end);
                extracted_data(:,end-1) = {strjoin(target_words, ',')};
            else
                error('please input a valid selection (and/or)')
            end
            

        end
    else
        extracted_data = overall_instance;
        extracted_data(:,end+1) = extracted_data(:,end);
        extracted_data(:,end-1) = {'None'};
    end

    [~, order] = sort(str2double(extracted_data(:,4)));
    extracted_data = extracted_data(order, :);
    extracted_data = sortrows(extracted_data,2);

    %% create output CSV
    summary_table = array2table(extracted_data,'VariableNames',colNames);

    % don't write to a CSV file if the function is used as an intermediate
    % helper function
    if ~strcmp(output_filename,'')
        if ~isempty(target_words_list)
            writetable(summary_table,sprintf('%s_%s.csv',output_filename(1:end-4),target_words_list{w}));
        else
            writetable(summary_table,sprintf('%s.csv',output_filename(1:end-4)));
        end
    end
end
end