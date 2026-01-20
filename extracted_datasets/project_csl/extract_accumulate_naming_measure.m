function extract_accumulate_naming_measure(exp_id, num_objs)
%
% oupput file: 
% 1 column: subj id
% 2 column: naming id (ROI id) 
% 3 column: # of naming instances 
% 4 column: target looking prop
% 5 column: 1/o whether the most looked one is target
% 6 column: target - most competitive distractor 
% 7 column: target -- average distractor  
% 8 column: target-competitor measure 

%exp_id = 91;
%num_objs = 24; 
% data = csvread(sprintf('individual_stats_exp%d.csv',exp_id)); 
% 
% histogram(data(:,18),"Normalization","probability"); 
% histogram(data(:,14),"Normalization","probability"); 
% histogram(data(:,12),"Normalization","probability"); 
% Calculate indiviudal instances 
% for i = 1 : size(data,1)
%     if data(i,14) > data(i,19)
%         data(i,20) = (data(i,14)-data(i,19))/data(i,14);
%     else 
%         data(i,20) = (data(i,14)-data(i,19))/data(i,19);
%     end
% 
% end
% csvwrite(sprintf('individual_stats_exp%d.csv',exp_id),data);


% calculate accumulated results 
path = 'M:/extracted_datasets/project_csl';
data2 = csvread(fullfile(path,sprintf('csl_accumulate_stats_exp%d.csv',exp_id))); 
header_col = 3; 
for i = 1 : size(data2,1) 
    results(i,1) = data2(i,1);
    results(i,2) = data2(i,2); 
    results(i,3) = data2(i,3); % # of naming 
    

    target = data2(i, header_col+data2(i,2));
    overall = sum(data2(i,header_col+1:header_col+num_objs)); 
    if overall >0
        prop_target = target/overall;
    else 
        prop_target = 0;
    end 
    results(i,4) = prop_target; % target proportion 

    [value idx] = max(data2(i,header_col+1:header_col+num_objs)); 
    if idx == data2(i,2)
        results(i,5) = 1; % the most looked is target 
    else 
        results(i,5) = 0;
    end
      
    others_idx = setxor([1:num_objs],data2(i,2));
    competitor = max(data2(i,header_col+others_idx)); 
    if overall >0
        results(i,6) = (target - competitor)/overall; % target - most competitive distractor 
        results(i,7) = (target - (overall-target)/(num_objs-1))/overall; % target -- average distractor  
        
        if target > competitor
            results(i,8) = (target-competitor)/target; % composite score 
        else
            results(i,8) = (target-competitor)/competitor; 
        end

    else 
        results(i,6) = 0;
        results(i,7) = 0; 
    end 
end

%csvwrite(sprintf('exp%d_cs_agg_stats.csv',exp_id),results)
t = array2table(results); 
t.Properties.VariableNames  ={'subject ID','target ROI','# of events',...
    'time on target', 'most looked == target','target-competitor', 'target-average others',...
    'metric'};
writetable(t,fullfile(path,sprintf('exp%d_cs_agg_stats.csv',exp_id)));

