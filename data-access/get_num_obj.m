function rtr_list = get_num_obj(subexpIDs,varargin)
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

% subs = cIDs(subexpIDs);
% exp_ids = unique(sub2exp(subs));

exp_ids = [];

for s = 1:length(subexpIDs)
    id = subexpIDs(s);
    try
        sub_list = list_subjects(id);  % try to get subject list
        exp_ids = [exp_ids, id];
    catch
        exp_ids = [exp_ids, sub2exp(id)];
    end

end

stim = fullfile(get_multidir_root, 'stimulus_table_total_n.xlsx');
stim_data = readtable(stim);

rtr_list = [];
for e = 1:length(exp_ids)
    exp = exp_ids(e);
    row = stim_data(stim_data.experiment_id == exp,:);
    if isempty(row)
        warning(sprintf('exp_%d is not found in stimuli table', exp))
        total_n = nan;
    else
        if isempty(varargin)
            total_n = row.number_of_objs_local;
        else
            total_n = row.number_of_objs_global;
        end
        if isnan(total_n)
            warning(sprintf('exp_%d is nan in stimuli table!', exp))
        end
    end
    rtr_list = [rtr_list, total_n];
end