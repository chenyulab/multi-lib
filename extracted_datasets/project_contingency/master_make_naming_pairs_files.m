%%%
% Author: Jane Yang
% Last Modified: 2/23/2024 by Ruchi Shah
% This master function calls get_first_forward_pairs and
% get_backward_naming_pairs to get the first forward and backward pairing
% instances of expanded naming variable and paired_var.
%
% Input: expIDs       - a list of experiments
%        num_obj_list - a list of number of objects in each experiment
%        paired_var   - second cevent variable for pairing with naming
%        output_dir   - where to save the output csv files
% 
% Example function call: master_make_naming_pairs_files([12 15 27 49],[24 10 24 3],'cevent_eye_roi_child' ,'.')
%%%

function master_make_naming_pairs_files(expIDs,num_obj_list, base_var, paired_var, output_dir)
    % check if there's one number of object for each input experiment
    if numel(num_obj_list) ~= numel(expIDs)
        error('Please specify the number of objects in each experiment!');
    end

    cev2 = paired_var;
    for i = 1:numel(expIDs)
        % get current experiment and its corresponding number of objects
        expID = expIDs(i);
        num_obj = num_obj_list(i);

        % make naming following files
        % cev1 = 'cevent_speech_naming_local-id'; % extract pairs of actual naming instances and target cevent var
        cev1 = base_var;
        backward_pairs = get_backward_cevents_pairs(expID,cev1,cev2,num_obj,output_dir);

        % make naming led files
        % cev1 = 'cevent_speech_naming_local-id_expanded';
        cev1 = [base_var '_expanded'];
        get_first_forward_cevent_pairs(expID,cev1,cev2,num_obj,output_dir,backward_pairs);
    end
end