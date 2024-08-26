%%%
% Author: Jane Yang
% Last Modified: 2/23/2024 by Ruchi Shah
% This function finds the first backward pairing instance of 
% any two cevent instances and writes all instances to an output csv file 
% by calling extract_pairs_multiwork. The csv file contains the timestamp 
% and target ID for each paired instance.
%
% Input: expID      - experiment ID
%        cev1       - base cevent variable for pairing
%        cev2       - second cevent variable for pairing
%        num_obj    - number of objects in the experiments
%        output_dir - output directory to save the output
% 
% Example function call: get_backward_cevents_pairs([12 15 27 49 58 71 72 73 74 75 91 351 353])
%%%

function backward_pairs = get_backward_cevents_pairs(expID,cev1,cev2,num_obj,output_dir)
    % find subjects with those variables
    subexpIDs = find_subjects({'cevent_trials',cev1,cev2},expID);
    % define timing relation for pairing
    timing_relation = 'more(on1, off2) & more(on2, on1)';
    
    mapping = repmat(1:num_obj,2,1)';
    
    args.first_n_cev1 = 1;
    
    % savefilename = fullfile(output_dir,sprintf('naming_following_exp%d.csv',expID));
    savefilename = fullfile(output_dir,sprintf('%s_%s_exp%d.csv',cev2,cev1,expID));
    [backward_pairs, ~,~] = extract_pairs_multiwork(subexpIDs, cev1, cev2, timing_relation, mapping, savefilename, args);
end