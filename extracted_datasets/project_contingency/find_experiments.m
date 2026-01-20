%%%
% Author: Jane Yang
% Last Modified: 9/06/2023
% This function returns a matrix of experiments and the number of subjects in
% each experiment that has the given variable.
%
% Input: var_list - a list of target variables for query
% 
% Dependent function call: find_subjects(var_list, expIDs)
% Example function call: exp_sub_matrix = find_experiments({'cevent_trials','cevent_speech_naming_local-id'})
%
% Output: expID   #subInExp
%           12       36
%           14       31
%           15       52
%           ...      ...
%%%

function rtr = find_experiments(var_list)
    % get experiments that have 'derived' folder on Multiwork Drive
    root = get_multidir_root();
    info = dir(fullfile(root,'experiment_*'));
    dirFlags = [info.isdir];
    subFolders = info(dirFlags);
    subFolderNames = {subFolders(3:end).name};
    exps_cell = cellfun(@(x) extractAfter(x,'_'),subFolderNames,'UniformOutput',false);
    exps = str2double(exps_cell);
    exps = setdiff(exps,[50 51]); % hard-coded to exclude exps w/o 'derived' folder


    % call find_subjects()
    all_subs = find_subjects(var_list,exps);

    % get unique expIDs
    all_exps = sub2exp(all_subs);
    unique_exps = unique(all_exps);

    % calculate number of subjects hat have the var in each experiment
    num_subs = zeros(size(unique_exps));
    for i = 1:length(unique_exps)
        num_subs(i) = sum(all_exps==unique_exps(i));
    end

    rtr = horzcat(unique_exps,num_subs);
end