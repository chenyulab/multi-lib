%%%
% Author: Jane Yang
% Last Modified: 2/23/2024 by Ruchi Shah
% This function gets the first forward pairing instances of two cevents for
% each subject. Assumes that master_make_speech_naming_expanded() has been
% called for cev1
%
% Input: expIDs             - a list of expIDs
%        cev1               - name of the first cevent (usually an expanded
%                             version of the base variable)
%        cev2               - name of the dependent variable for pairing
%        num_obj            - number of objects in the experiment
%        output_dir         - output directory for csv files
%        allpairs(optional) - pairing results from backward pairing
%
% 
% Example function call: get_first_forward_pairs([12],'cevent_speech_naming_local-id_expanded','cevent_eye_roi_child',24,'C:\Users\janeyang\Box\Extract Pairs Vis')
%%%

function get_first_forward_cevent_pairs(expID, cev1, cev2, num_obj, output_dir, backward_pairs)
    % check for optional backward pairing results passed in the argument
    if ~exist('backward_pairs', 'var')
        backward_pairs = []; % set it to empty
    end
    
    % get a list of subjects in the input experiment that has expanded
    % naming variable
    % subexpIDs = find_subjects({'cevent_trials','cevent_speech_naming_local-id_expanded'},expID);
    subexpIDs = find_subjects({'cevent_trials',cev1,cev2},expID);

    % define timing relation for pairing
    % threshold = 3; % 3 seconds between naming and looking
    timing_relation = 'more(on1, on2) & more(on2,off1)'; % this means on1 must be less than on2 & on2 must be less than off1
    % timing_relation = 'less(on1,on2,3)';
    
    mapping = repmat(1:num_obj,2,1)';

    args.first_n_cev1 = 1;
    
    savefilename = '';
    [allpairs, cev1wo, ~] = extract_pairs_multiwork(subexpIDs, cev1, cev2, timing_relation, mapping, savefilename, args);
    

    %%% TODO: change column header to be the same as the output of
    %%% extract_pairs_multiwork
    % set column names for output csv file
    colNames = {'subID','onset_cev1','offset_cev1','onset_cev2','offset_cev2','objID'};
    
    % generate the matrix containing pairing information
    paired = allpairs(:,[1:4 6:7]); % parse paired data from output of extract_pairs
    % create not paired instances matrix
    not_paired = cev1wo(:,1:4);
    not_paired_val = NaN([length(not_paired) 2]);
    not_paired = horzcat(not_paired,not_paired_val);
    % concat paired and not paired instances together
    rtr = vertcat(paired,not_paired);
    % reformat matrix columns
    cat_col = rtr(:,4);
    onset_col = rtr(:,5);
    offset_col = rtr(:,end);
    rtr(:,4) = onset_col;
    rtr(:,5) = offset_col;
    rtr(:,end) = cat_col;

    % exclude instances that were included in the backward pairing case
    filtered_rtr = [];

    if ~isempty(backward_pairs)
        % iterate thru subjects
        for i = 1:length(subexpIDs)
            sub = subexpIDs(i);

            % find subject specific instances
            sub_mtx = rtr(rtr(:,1)==sub,:);

            % find all onsets that appeared in the backward naming case
            backward_pairs_onset = backward_pairs(backward_pairs(:,1)==sub,2);

            % find matching index where the forward pairing instances overlap
            % with backward naming
            match_idx = ~ismember(round(sub_mtx(:,2),2),round(backward_pairs_onset,2));

            filtered_sub_mtx = sub_mtx(match_idx,:);
            filtered_rtr = [filtered_rtr;filtered_sub_mtx]; 
        end
    else
        filtered_rtr = rtr;
    end
    
    
    % convert matrix to table
    rtr_table = array2table(filtered_rtr,"VariableNames",colNames);
    
    % sort table by subject ID and onset of cev1
    rtr_table = sortrows(rtr_table,[1 2]);
    
    % write to csv
    % writetable(rtr_table,fullfile(output_dir,sprintf('naming_led_exp%d.csv',expID)));
    writetable(rtr_table,fullfile(output_dir,sprintf('%s_%s_exp%d.csv',cev1,cev2,expID)));


    %%% TODO: not sure if visualizations should be generated in this
    %%% function

    % % generate visualizations
    % full_sub_list = cIDs(subexpIDs);
    % tmp_var_name = 'cevent_forward-paired_tmp';
    % base_cev = cev1(1:end-9); % hard-coded right now to get the name of the base cev
    % 
    % % create temporary paired variable for visualization
    % for i = 1:numel(full_sub_list)
    %     cevent_paired_tmp = allpairs(allpairs(:,1) == full_sub_list(i),6:8);
    % 
    %     record_additional_variable(full_sub_list(i), tmp_var_name,cevent_paired_tmp);
    % 
    %     var_list = {base_cev,cev1,cev2,tmp_var_name}; % hard-coded right now, not sure how to modify if we were to use another base variable
    % 
    %     streamlabels = {'naming','expanded','ceye','paired'};
    %     vis_streams_multiwork(full_sub_list(i),var_list,streamlabels,output_dir);
    % end

    % delete_variables(full_sub_list,tmp_var_name);
end