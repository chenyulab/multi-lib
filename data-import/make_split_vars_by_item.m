function make_split_vars_by_item(subexpIDs, var_list, sub_item_file, scores, label)
% Author: Chen Yu
% last edited: 08/29/2024
% This functions reads different scoretable in each experiment folder and splits variables based on the
% score. score table can be different types: learned_toy, learned_word etc.
%
% input parameters:
%   subexpIDs: subject id or experiment id
%   var_list: list of variable that need to be splited
%   sub_item_file: the scoretable
%   scores: score list
%   label: output variable label
% output:
%   splited variables
%       - variable_name_label_score_agent.mat
%
% example call:
%   subexpIDs = [1510 1511 1514];
%   var_list = {'cevent_inhand_child','cevent_eye_roi_parent'};
%   sub_item_file = 'M:\experiment_15\exp15_scoretable.xlsx';
%   scores = [0 1 2];
%   label ='learned';
%
%   make_split_vars_by_item(subexpIDs, var_list, sub_item_file, scores, label)
%   make_split_vars_by_item([1510 1511 1514], {'cevent_inhand_child','cevent_eye_roi_parent'}, ...
%   'M:\experiment_15\exp15_scoretable.xlsx', [ 0 1 2], 'learned')


subs = cIDs(subexpIDs);

% read the sub-item info
sub_item = xlsread(sub_item_file);
sub_list = sub_item(:,1);
num_objs = get_num_obj(floor(sub_list(1)/100));

for s = 1 : length(subs)
    for v = 1 : length(var_list)
        if has_variable(subs(s),var_list{v})
            base_data = get_variable(subs(s), var_list{v});
            sub_idx = find(sub_item(:,1) ==subs(s));
            for i = 1: length(scores)
                rois = find(sub_item(sub_idx,2:num_objs+1)==scores(i));

                idx_all =[];
                if ~isempty(rois)
                    for r = 1 : length(rois)
                        idx = find(base_data(:,3) == rois(r));
                        idx_all = [idx_all; idx];
                    end
                end

                data{i} = base_data(idx_all,:);
                data{i} = sortrows(data{i},1);

                if contains(var_list{v},'_child')
                    var_split = strsplit(var_list{v},'_child');
                    agent='child';
                elseif contains(var_list{v},'_parent')
                    var_split = strsplit(var_list{v},'_parent');
                    agent='parent';
                end
                var_name_base = sprintf('%s_%s-%d_%s',var_split{1},label,scores(i),agent);
                record_additional_variable(subs(s),var_name_base,data{i});

            end
        end
    end


end

