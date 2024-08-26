clear;

expIDs = [12 351];
output_dir = 'M:\extracted_datasets\event_clips\data\wh_words';
keywords = {'what','where','who','which','when','why','how'};
keywordsID = [1:7];
subID_col = 1;
onset_col = 4;
offset_col = 7;
keyword_col = 9;

% for k = 1:length(keywords)
%     currKeyword = keywords{k};
%     disp(currKeyword);
% 
%     output_filename = sprintf('WHWord-%s.csv',currKeyword);
%     query_csv_speech(expIDs,cellstr(currKeyword),output_dir,output_filename);
% end
% 
% % trying to take a list of keywords
% output_filename = 'WHWord-all.csv';
% query_keywords(expIDs,keywords,output_dir,output_filename);



% 
% % read the csv file with all wh words instances
% input_filename = 'WHWord-all.csv';
% keyword_varname = 'cevent_speech_wh-words';
% 
% % read the csv file into a table
% data = readtable(fullfile(output_dir,input_filename));
% 
% % parse the subject list from the data
% subList = unique(data{:,1});
% 
% % iterate thru subjects and generate variable for each subject
% for s = 1:length(subList)
%     subID = subList(s);
% 
%     % find subject specific data
%     idx = find(data{:,subID_col}==subID);
%     % subData = data{idx,:};
% 
%     % extract onset and offset timestamps from data
%     subOnset = data{idx,onset_col};
%     subOffset = data{idx,offset_col};
%     subKeyword = data{idx,keyword_col};
% 
%     keyword_cev = [];
% 
%     for i = 1:length(keywords)
%         index = find(strcmp(subKeyword,keywords(i)));
% 
%         % concatenate found instances to the cevent matrix
%         keyword_cev = vertcat(keyword_cev,[subOnset(index) subOffset(index) repmat(i,length(index),1)]);
%     end
% 
%     % sort keyword cevent based on onset
%     keyword_cev = sortrows(keyword_cev,1);
% 
%     % record variable
%     record_additional_variable(subID,keyword_varname,keyword_cev);
% end



% call single variable stats
var_list = 'cevent_speech_wh-words';
extract_basic_stats(var_list,expIDs, size(keywords,2));
