%%%
% This function reads data from query_word function and creates cevent verb variable
% Author: Jane Yang
% modifier: Jingwen Pang
% last edited: 10/16/2024
% input:
%   - keyword_list: list of the keywords
%   - keyword_ids: corresponding keyword mapping ids
%   - data: output data from query_keyword function
%   - varname: output variable name
% output:
%   - corresponding cevent variables
% see demo_speech_analysis_functions case 8
%%%
function make_keywords_events(keyword_list, keyword_ids, data, varname)

% keywords = {'assemble','cut','close','drink','eat','get','grab','look','make','move','open','put','reach','rip','scoop','screw','spread','try','twist','wipe'};
subID_col = 1;
onset_col = 4;
offset_col = 7;
keyword_col = 9;

% parse the subject list from the data
subList = unique(data{:,1});

% iterate thru subjects and generate variable for each subject
for s = 1:length(subList)
    subID = subList(s);

    % find subject specific data
    idx = find(data{:,subID_col}==subID);

    % extract onset and offset timestamps from data
    subOnset = data{idx,onset_col};
    subOffset = data{idx,offset_col};
    subKeyword = data{idx,keyword_col};

    keyword_cev = [];

    for i = 1:length(keyword_list)
        index = find(strcmp(subKeyword,keyword_list(i)));

        % concatenate found instances to the cevent matrix
        keyword_cev = vertcat(keyword_cev,[subOnset(index) subOffset(index) repmat(keyword_ids(i),length(index),1)]);
    end

    % sort keyword cevent based on onset
    keyword_cev = sortrows(keyword_cev,1);

    % % record variable
    record_additional_variable(subID,varname,keyword_cev);
end



