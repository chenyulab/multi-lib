%%%
% Author: Jane Yang
% Last Modified: 9/06/2023
% This function gets the first forward pairing instances of two cevents and
% creates one visualization for each subject.
%
% Input: subexpIDs       - a list of subIDs or expIDs
%        cev1            - name of the first cevent (usually an expanded
%                          version of the base variable)
%        cev2            - name of the dependent variable for pairing
%        num_obj         - number of objects in the experiment
%        streamlabels    - a list of labels for visualizations
%        output_dir      - output directory for visualizations and csv file
% 
% Example function call: get_first_forward_pairs([12],'cevent_speech_naming_local-id_expanded','cevent_eye_roi_child',24,'C:\Users\janeyang\Box\Extract Pairs Vis')
%%%

function get_first_forward_pairs(subexpIDs, cev1, cev2, num_obj, streamlabels,output_dir)
    % define timing relation for pairing
    timing_relation = 'more(on1, on2) & more(on2,off1)'; % this means on1 must be less than on2 & on2 must be less than off1
    
    mapping = repmat(1:num_obj,2,1)';
    args.first_n_cev1 = 1;
    
    savefilename = '';
    [allpairs, cev1wo, ~] = extract_pairs_multiwork(subexpIDs, cev1, cev2, timing_relation, mapping, savefilename, args);
    
    % set column names for output csv file
    colNames = {'subID','onset_cev1','offset_cev1','onset_cev2','offset_cev2','objID'};
    
    % % hard-coded index to get onset and offset of cevent 1&2
    % sub_idx = 1;
    % onset_cev1_idx = 2;
    % offset_cev1_idx = 3;
    % onset_cev2_idx = 6;
    % offset_cev2_idx= 7;
    
    % generate the matrix containing pairing information
    paired = allpairs(:,[1:4 6:7]); % parse paired data from output of extract_pairs
    % create not paired instances matrix
    not_paired = cev1wo(:,1:4);
    not_paired_val = NaN([length(not_paired) 2]);
    not_paired = horzcat(not_paired,not_paired_val);
    % concat paired and not paired instances together
    rtr = vertcat(paired,not_paired);
    % reformat matrix columns
    val_col = rtr(:,4);
    rtr(:,4) = rtr(:,end);
    rtr(:,end) = val_col;
    
    % convert matrix to table
    rtr_table = array2table(rtr,"VariableNames",colNames);
    
    % sort table by subject ID and onset of cev1
    rtr_table = sortrows(rtr_table,[1 2]);
    
    % write to csv
    writetable(rtr_table,fullfile(output_dir,'pairing_output.csv'));


    %%% TODO: not sure if visualizations should be generated in this
    %%% function
    
    % generate visualizations
    full_sub_list = cIDs(subexpIDs);
    tmp_var_name = 'cevent_forward-paired_tmp';
    base_cev = cev1(1:end-9); % hard-coded right now to get the name of the base cev

    % create temporary paired variable for visualization
    for i = 1:numel(full_sub_list)
        cevent_paired_tmp = allpairs(allpairs(:,1) == full_sub_list(i),6:8);
    
        record_additional_variable(full_sub_list(i), tmp_var_name,cevent_paired_tmp);
    
        var_list = {base_cev,cev1,cev2,tmp_var_name}; % hard-coded right now, not sure how to modify if we were to use another base variable
    
        vis_streams_multiwork_v2(full_sub_list(i),var_list,streamlabels,output_dir);
    end
    delete_variables(full_sub_list,tmp_var_name);
end