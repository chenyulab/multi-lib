clear; 
exp_id = 27; 
num_objs = 24;
path = 'M:/extracted_datasets/project_csl';
data  = csvread(fullfile(path,sprintf('naming_exp%d.csv',exp_id)), 4,0);
target_col = 5;
prop_col = 8; 

sub_list = unique(data(:,1));

results_row = 0 ; 

for s = 1 : length(sub_list)
    index = find(data(:,1) == sub_list(s));
    sub_data = data(index,:);
    objs_list = unique(sub_data(:,target_col));

    for o = 1 : length(objs_list)
        target = objs_list(o);
        index1 = find(sub_data(:,target_col) == target);
        results_row = results_row+1;
        results(results_row,1) = sub_list(s);
        results(results_row,2) = target;
        results(results_row,3) = length(index1);
        results(results_row,4:4+num_objs-1) = sum((sub_data(index1,4)-sub_data(index1,3)) .*sub_data(index1, prop_col:prop_col+num_objs-1),1); 
    end
end
csvwrite(fullfile(path,sprintf('csl_accumulate_stats_exp%d.csv',exp_id)),results); 