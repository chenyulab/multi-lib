%%%
% Author: Jingwen Pang
% last modified: 3/20/2025
% 
% This function take the speech in situ csv file and group them based in
% subject-object level, subject level, and object level
%
%
%
% example call:
%   input_csv_name = 'exp351_cevent-roi_speech-babyname.csv';
%   group_speech_in_situ(input_csv_dir)
% 
%%%
function [table_sub, table_cat, table_sub_cat] = group_speech_in_situ(input_csv,args)
    % remove extension
    file_label = input_csv(1:end-4);

    if ~exist('args', 'var') || isempty(args)
        args = struct();
    end

    if ~isfield(args, 'exp_col')
        args.exp_col = 2;
    end
    
    if ~isfield(args, 'sub_col')
        args.sub_col = 1;
    end
    
    if ~isfield(args, 'cat_col')
        args.cat_col = 5;
    end
    
    if ~isfield(args, 'trial_time_col')
        args.trial_time_col = 8;
    end

    if ~isfield(args, 'utt_col')
        args.utt_col = -1;
    end
    exp_col = args.exp_col;
    sub_col = args.sub_col;
    cat_col = args.cat_col;
    trial_time_col = args.trial_time_col;
    
    data = readtable(input_csv);
    
    exp_ids = unique(table2array(data(:,exp_col)));
    sub_ids = unique(table2array(data(:,sub_col)));
    cat_values = unique(table2array(data(:,cat_col)));
    
    for e = 1:length(exp_ids)
        exp_id = exp_ids(e);
        exp_data = data(data{:,exp_col}==exp_id,:);
    
        sub_cat = {};
        sub = {};
        cat = {};
    
        % subject level
        for s = 1:length(sub_ids)
            sub_id = sub_ids(s);
            sub_data = exp_data(exp_data{:,sub_col}==sub_id,:);
            trial_time = sub_data{1,trial_time_col};

            % subject-category level
            for c = 1:length(cat_values)
                cat_value = cat_values(c);
                cat_data = sub_data(sub_data{:,cat_col}==cat_value,:);
                
                if ~isempty(cat_data)
                    num_instance = size(cat_data,1);
                    
                    % remove empty text
                    if args.utt_col == -1
                        clean_utt = table2cell(cat_data(:,end));
                    else
                        clean_utt = table2cell(cat_data(:,args.utt_col));
                    end
                    clean_utt = clean_utt(~cellfun('isempty', clean_utt));
        
                    utterances = strjoin(clean_utt,' ');
                    sub_cat = [sub_cat;{sub_id,exp_id,cat_value,trial_time,num_instance,utterances}];
                end
            end
    
            num_instance = size(sub_data,1);
    
            % remove empty text
            clean_utt = table2cell(sub_data(:,end));
            clean_utt = clean_utt(~cellfun('isempty', clean_utt));
    
            utterances = strjoin(clean_utt,' ');
            sub = [sub;{sub_id,exp_id,trial_time,num_instance,utterances}];
    
        end
    
        % category level
        for c = 1:length(cat_values)
            cat_value = cat_values(c);
            cat_data = exp_data(exp_data{:,cat_col}==cat_value,:);
    
            num_instance = size(cat_data,1);
                
            % remove empty text
            clean_utt = table2cell(cat_data(:,end));
            clean_utt = clean_utt(~cellfun('isempty', clean_utt));
    
            utterances = strjoin(clean_utt,' ');
            cat = [cat;{exp_id,cat_value,num_instance,utterances}];
    
        end
    
        % write output file into table
        sub_cat_name = sprintf("%s_subject-category.csv",file_label);
        col_names = {'subID','expID','category', 'trial_time', 'instance#', 'utterances'};
        table_sub_cat = cell2table(sub_cat, 'VariableNames', col_names);
        writetable(table_sub_cat, sub_cat_name);
    
        sub_name = sprintf("%s_subject.csv",file_label);
        col_names = {'subID','expID','trial_time', 'instance#', 'utterances'};
        table_sub = cell2table(sub, 'VariableNames', col_names);
        writetable(table_sub, sub_name);
    
        cat_name = sprintf("%s_category.csv",file_label);
        col_names = {'expID','category', 'instance#', 'utterances'};
        table_cat = cell2table(cat, 'VariableNames', col_names);
        writetable(table_cat, cat_name);
    
    
    end
end