%%%
% Author: Jane Yang
% Last Modifier: 3/27/2023
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
%%%

function overall_instance = extract_speech_in_situ(expID,cevent_var,category_list,target_words,output_filename,args)
    %% parameter checking
    % check if 'whence' and 'interval'
    if ~exist('args', 'var') || isempty(args)
        args = struct([]);
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
        % load trialInfo variable to get speech time
        trialInfo_path = get_info_file_path(sub_list(i));
        trialInfo = load(trialInfo_path);
        speechTime = trialInfo.trialInfo.speechTime;
    
        % convert original timestamp to system time -- TODO: not sure if
        % all raw speech transcriptions have timestamps that are
        % inconsistent with the system time
        for j = 1:numel(speech_var)
            speech_var(j).start = speech_var(j).start + speechTime;
            speech_var(j).end = speech_var(j).end + speechTime;
        end
    
        % get timestamps of cevent variable
        cevent = get_variable(sub_list(i),cevent_var);
        
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
                bt = onset(k);
                et = offset(k);
    
                % find utterance timestamps that falls within bt-et range
                utt_onset = [speech_var.start];
                match_idx = find(utt_onset >= bt & utt_onset <= et);
    
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
            % create instance entry: {'expID','subID','onset','offset','category','utterances'}
%             instance = [repmat(expID,size(onset,1),1) repmat(sub_list(i),size(onset,1),1) onset offset repmat(cat,size(onset,1),1) utt_list];    
        end

        %% create output CSV
        summary_table = array2table(overall_instance,'VariableNames',colNames);

        % don't write to a CSV file if the function is used as an intermediate
        % helper function
        if ~strcmp(output_filename,'')
            writetable(summary_table,output_filename);
        end
    end
end