%%%
% Author: Jane Yang
% Last Modifier: 3/28/2023
% Demo function of group_speech_in_situ(). This function parses the
% dictionary of input experiment, obtains objID list and target words from
% the dictionary, calls group_speech_in_situ(). and saves output CSV files 
% in specified direcotry.
% 
% Input: expID, cevent variable name, grouping option,
%        a list of target words, output filename, grouping option, and
%        option 'whence' and 'interval' arguments for shifting timestamps.
% Output: generates CSV files correspondingly, returns objIDs and target
%         words list parsed from experiment's dictionary.
%
% Example function call: demo_group_speech_in_situ(12,'cevent_eye_roi_sustained-3s_child','subject','.\roi-3s_sub-level',args)
%%%

function [objID,names] = demo_group_speech_in_situ(expID,cevent_var,option,output_dir,args)
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
    
    % parse dictionary
    root = fullfile(get_multidir_root(),sprintf('experiment_%d',expID));
    dictionary_entry = fullfile(root,sprintf('exp_%d_dictionary.xlsx',expID));

    dict = readtable(dictionary_entry);
    objID = table2array(dict(:,3));
    raw_names = table2array(dict(:,4));

    % parse object names -- 'target words' argument
    for i = 1:numel(raw_names)
        names(i,:) = {string(strsplit(char(raw_names(i)),', '))};
    end

    % call group_speech_in_situ
    for i = 1:numel(objID)
        category = objID(i);
        target_words = string(names{i,1});
        output_filename = fullfile(output_dir,sprintf('exp%d_grouped-%s-level_obj%d_words-%s.csv',expID,option,category,strjoin(target_words,'-')));
        
        grouped_instance = group_speech_in_situ(expID,cevent_var,category,target_words,output_filename,option);
    end
end