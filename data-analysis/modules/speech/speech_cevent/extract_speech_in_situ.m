%%%
% Author: Jane Yang
% Last Modifier: 11/16/2023
% This function selects relevant target category instances in a cevent 
% variable and finds the utterances based on cevent variable's timestamps.
% 
% Input: expID, cevent variable name, category (objID), 
%        a list of target words, output filename, and
%        option 'whence' and 'interval' arguments for shifting timestamps.
% Output: a table containing expID, subID, onset and offset of cevent,
%         category (objID), target words frequency, aggregated utterances,
%         and utterances summary information ('#Token','#UniqueWord',
%         '#Utterance','#Noun','#Verb','#Adjective','utterances'). 
%         A .CSV file is generated based on the output table.
%
% Example function call: extract_speech_in_situ(12,'cevent_eye_roi_sustained-3s_child',1,["helmet","hat"],'test_new-overlap-rule.csv',args)
%%%

function overall_instance = extract_speech_in_situ(expID,cevent_var,category_list,target_words,output_filename,args)
    %% parameter checking
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


    % get a list of subjects that has the cevent variable
    sub_list = find_subjects(cevent_var,expID);
    
    % generate column names
    colNames = {'expID','subID','onset','offset','category'};
    for i = 1:numel(target_words)
        colNames{end+1} = char(target_words(i));
    end
    colNames = horzcat(colNames,{'#Token','#UniqueWord','#Utterance','#Noun','#Verb','#Adjective','utterances'});


    overall_instance = [];
    
    %% find cevent timestamps matching utterances
    for i = 1:size(sub_list,1)
        %% parse speech transcription file
        [~,speech_var] = parse_speech_trans(sub_list(i));
    
        % skip the subject if no speech transcription was found
        if size(speech_var,1) == 0
            continue
        end
    
    
        %% convert timestamps in speech transcription file to system time
        speechTime = get_timing(sub_list(i)).speechTime;
    
        % convert original timestamp to system time -- TODO: not sure if
        % all raw speech transcriptions have timestamps that are
        % inconsistent with the system time
        for j = 1:numel(speech_var)
            speech_var(j).start = speech_var(j).start + speechTime;
            speech_var(j).end = speech_var(j).end + speechTime;
        end
    
        % get timestamps of cevent variable
        cevent = get_variable_by_trial_cat(sub_list(i),cevent_var);
        
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
                match_idx = union(index3,index6);
                disp(match_idx);
    
                sub_utt = "";
    
                for m = 1:numel(match_idx)
                    utt1 = speech_var(match_idx(m)).words;
                    sub_utt = sub_utt + utt1 + "; ";
                end

                utt_list = [utt_list;cellstr(sub_utt)];
                % create one instance per instance in cevent_var
                instance = [expID sub_list(i) bt et cat];

                % calculate basic token measures per matching instance
                count_vec = get_target_words_count(target_words,sub_utt);

                % append target words count to instance row
                instance = horzcat(instance,count_vec);

                % calculate other summary measures to append to instance
                summary_vec = get_utterance_word_summary(sub_utt);
                % append utterance word summary to instance row
                instance = horzcat(instance,summary_vec,sub_utt);

                % append new instance to a list of instances
                overall_instance = [overall_instance;instance];
            end 
        end
    end
    %% create output CSV
    summary_table = array2table(overall_instance,'VariableNames',colNames);

    % don't write to a CSV file if the function is used as an intermediate
    % helper function
    if ~strcmp(output_filename,'')
        writetable(summary_table,output_filename);
    end
end