%
% using the information in a score file to return a score of a particular
% item from a subject. For example, a score can reflect whether an item
% is learned or unlearned, known or unknown
%
% e.g. score = get_item_score_by_sub(1514,10,'scoretable')
%      score = get_item_score_by_sub(35142,11,'scoretable_name')
% 
% if there is no information about that item from that subject
% score is assigned to be -1 
% 

function score = get_item_score_by_sub(sub_id, item_id,score_type)

exp_dir = get_experiment_dir(sub_id);
exp_id = floor(sub_id/100);
num_item = get_num_obj(sub_id);

data_file = sprintf('%s/exp%d_%s.csv',exp_dir,exp_id,score_type); 
data = csvread(data_file,1,0);


sub_idx = find(data(:,1) == sub_id);

if isempty(sub_idx)
    score = -1; 
else
    if item_id <= num_item  
        score = data(sub_idx,item_id+1);
    else
        score = -1; 
    end
end
    


