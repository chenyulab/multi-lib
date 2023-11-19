%%%
% Author: Jane Yang
% Last Modifier: 3/27/2023
% This function calls extract_speech_in_situ and group data into subject
% or experiment level, outputting target word count and showing distribution
% of words.
% 
% Input: expID, cevent variable name, category (object ID), 
%        a list of target words, output filename, grouping option, and
%        option 'whence' and 'interval' arguments for shifting timestamps.
% Output: a table containing expID, subID, category (objID), 
%         target words frequency, aggregated utterances. A .CSV file is 
%         generated based on the output table.
%%%


function grouped_instance = group_speech_in_situ(expID,cevent_var,category,target_words,output_filename,option,args)
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

    % generate column names
    colNames = {'expID','subID','category'};
    for i = 1:numel(target_words)
        colNames{end+1} = char(target_words(i));
    end
    colNames{end+1} = 'utterances';

    colNames_exp = {'expID','category'};
    for i = 1:numel(target_words)
        colNames_exp{end+1} = char(target_words(i));
    end
    colNames_exp{end+1} = 'utterances';


    grouped_instance = [];
    % group instances at level specified by 'option' argument
    if strcmp(option,'subject')
        overall_instance = extract_speech_in_situ(expID,cevent_var,category,target_words,'',args);

        % list unique subjects in the return table
        sub_list = str2double(unique(overall_instance(:,2)));

        for i = 1:numel(sub_list)
            % get all instances for current subject
            sub_instance = overall_instance(strcmp(overall_instance(:,2),string(sub_list(i))),:);

            % group utterances together per subject
            combined_utt = strtrim(strjoin(sub_instance(:,end)));

            % count target word frequency
            count_vec = get_target_words_count(target_words,strjoin(sub_instance(:,end)));

            % generate an instance entry per subject
            instance = [expID sub_list(i) category count_vec combined_utt];

            % append new instance to a list of instances
            grouped_instance = [grouped_instance;instance];

            %%% TODO: get combined utterances word count and show
            %%% distribution

            % % get word count for all words in the combined utterance
            % combined_utt_count_table = wordCloudCounts(combined_utt); 
            % 
            % % generate word cloud
            % wordcloud(combined_utt);
            % title(num2str(sub_list(i)));
            % saveas(gcf,['wordcloud_' num2str(sub_list(i)) '_obj' num2str(category) '.png']);
        end
    elseif strcmp(option,'experiment')
        overall_instance = extract_speech_in_situ(expID,cevent_var,category,target_words,'',args);

        % trival step, get unique experiment ID just in case
        exp_list = str2double(unique(overall_instance(:,1)));
        
        for i = 1:numel(exp_list)
            % get all instances for current subject
            sub_instance = overall_instance(strcmp(overall_instance(:,1),string(exp_list(i))),:);

            % group utterances together per subject
            combined_utt = strtrim(strjoin(sub_instance(:,end)));

            % count target word frequency
            count_vec = get_target_words_count(target_words,strjoin(sub_instance(:,end)));

            % generate an instance entry per subject
            instance = [exp_list(i) category count_vec combined_utt];
            % append new instance to a list of instances
            grouped_instance = [grouped_instance;instance];

            %%% TODO: get combined utterances word count and show
            %%% distribution

            % % get word count for all words in the combined utterance
            % combined_utt_count_table = wordCloudCounts(combined_utt);
            % 
            % % generate word cloud
            % wordcloud(combined_utt);
            % title("exp"+num2str(exp_list(i)));
            % saveas(gcf,['wordcloud_' 'exp_' num2str(exp_list(i)) '_' num2str(category) '.png']);
        end
    else
        fprintf('Please specify a level of grouping: choose to group data in subject-level or experiment-level\n.');
    end

    % write output CSV file
    if strcmp(option,'subject')
        grouped_instance = array2table(grouped_instance,'VariableNames',colNames);
    elseif strcmp(option,'experiment')
        grouped_instance = array2table(grouped_instance,'VariableNames',colNames_exp);
    end
    
    % don't write to a CSV file if the function is used as an intermediate
    % helper function
    if ~strcmp(output_filename,'')
        writetable(grouped_instance,output_filename);
    end
end