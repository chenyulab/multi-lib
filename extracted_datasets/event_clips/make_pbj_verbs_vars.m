%%%
% Author: Jane Yang
% Last modified: 06/09/2024
%
% Description: This scripts takes in a csv file containing the timing
% information about a PBJ verb and turns the instances into a cevent
% variable.
%%%

clear;

expIDs = [58 353];

% define a directory where all input CSV files are located
input_dir = 'csv';

% define a path to the mapping file
mapping_file = 'M:\experiment_58\verb_mapping.csv';

% read mapping file
mapping = readtable(mapping_file);

% find all relevant csv files from the directory
fileInfo = dir(fullfile(input_dir,'pbj_verbs*.csv'));
fileList = {fileInfo.name}';

% hard-coded onset/offset column index
subID_col = 1;
onset_col = 4;
offset_col = 7;

% iterate thru each csv file to generate one cevent variable for each file
for i = 1:length(fileList)
    currFile = fullfile(input_dir,fileList{i});

    % read file to table
    data = readtable(currFile);

    % find a list of subjects
    subList = unique(data{:,subID_col});

    % iterate thru each subject and create a pbj verb cevent var for each
    % subject
    for s = 1:length(subList)
        subID = subList(s);

        % find subject specific data
        subData = data{data{:,subID_col}==subID,[subID_col onset_col offset_col]};

        % extract onset and offset timestamps from data
        onset = subData(:,2);
        offset = subData(:,3);
    
        % extract verb keyword from the filename
        split = strsplit(fileList{i},{'_','.'});
        verb = split{end-1};
    
        % use verb keyword to find the category value for the cevent var
        category = mapping{strcmp(mapping{:,1},verb),2};
    
        % create PBJ verb cevent var
        cev = [];
        cev(:,1:2) = horzcat(onset,offset);
        cev(:,3) = repmat(category,size(cev,1),1);
    
        % save variable
        varname = sprintf('cevent_speech_naming_local-id-%s',verb);
        % record_additional_variable(subID,varname,cev);
    end
end



% call extract multiple measure
verb_vars = {'cevent_speech_naming_local-id-cut','cevent_speech_naming_local-id-eat','cevent_speech_naming_local-id-get',...
            'cevent_speech_naming_local-id-grab','cevent_speech_naming_local-id-look','cevent_speech_naming_local-id-make',...
            'cevent_speech_naming_local-id-open','cevent_speech_naming_local-id-put',',cevent_speech_naming_local-id-spread',...
            'cevent_speech_naming_local-id-try','cevent_speech_naming_local-id-wipe','cevent_speech_naming_local-id-reach'};

for v = 1:length(verb_vars)
    varname = verb_vars{v}; % current base variable
    split = strsplit(varname,{'_','-'});
    verb = split{end};

    % find a list of subjects that have the variable
    subexpIDs = find_subjects(varname,expIDs);

    if ~isempty(subexpIDs)
        var_list = {'cevent_eye_roi_child','cevent_eye_roi_parent','cevent_inhand_child','cevent_inhand_parent'};
    
        filename = fullfile(input_dir,sprintf('extracted_%s.csv',verb));

        args.cevent_name = varname;
        args.cevent_values = unique(mapping{:,2});
        extract_multi_measures(var_list, subexpIDs, filename,args);
    else
        fprintf('No subject has the variable %s.\n',varname);
    end
end