function rtr_list = get_num_obj(subexpID,varargin)
% default: return the local number of stimulis
% get_num_obj([58 59 65 351])
% 
% ans =
% 
%     27     4    18    27
% 
% add optional parameter: return the global number of stimulis
% get_num_obj([58 59 65 351],1)
% 
% ans =
% 
%     27    16    18    27

subs = cIDs(subexpID);
exp_id = unique(sub2exp(subs));

stim = fullfile(get_multidir_root, 'stimulus_table_total_n.xlsx');
stim_data = readtable(stim);

rtr_list = [];
for e = 1:length(exp_id)
    exp = exp_id(e);
    row = stim_data(stim_data.experiment_id == exp,:);
    if isempty(row)
        warning(sprintf('exp_%d is not found in stimuli table', exp))
        total_n = 0;
    else
        if isempty(varargin)
            total_n = row.number_of_objs_local;
        else
            total_n = row.number_of_objs_global;
        end
    end
    rtr_list = [rtr_list, total_n];
end