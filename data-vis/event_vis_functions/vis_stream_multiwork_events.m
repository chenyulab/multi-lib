%%%
% Author: Jane Yang
% Last Modified: 8/31/2023
% This function displays event-based data stream visualization based on
% extract_multi_measures()
%
% Input: subexpID                 - a list of subID or expID
%        event_var                - base variable to pass to extract_multi_measures()
%        var_list                 - a list of dependent variables
%        category_val_list        - a list of cevent values to parse for events
%        output_file_dir          - directory to save output data visualization
%        event_row_num (optional) - which row to display base variable in
%                                    data visualization
%        whence                   - e.g. 'start'
%                                   (see demo_extract_multi_measure)
%        interval                 - e.g. [-3 3]
%        flag                     - "1" means visualize ALL categories, "2"
%                                   means only visualize TARGET categories
%
% Output: one data visualization for each subject
% 
%
% Dependent function called: extract_multi_measures()
% 
% Example function call: vis_stream_multiwork_events([1515 1516 1517],'cevent_speech_naming_local-id',{'cevent_eye_roi_child','cevent_eye_roi_parent','cevent_inhand_child','cevent_inhand_parent'},[1:10],{'naming','ceye','peye','chand','phand'},'naming-eye-inhand_3s-after-onset','start',[0 3],2)
%%%

function vis_stream_multiwork_events(subexpID,event_var,var_list,category_val_list,streamlabels,output_file_dir,whence,interval,flag)
    % call extract_multi_measures() using within_ranges to get event
    % timestamps that are between ranges
    args.cevent_name = event_var;
    args.cevent_values = category_val_list;

    % option default to 'full'
    if exist('flag','var')
        if flag == 1
            flag = 'all';
        elseif flag == 2
            flag = 'target';
        end
    else
        flag = 'all';
    end
    
    if exist('whence','var')
        args.whence = whence;
    end

    if exist('interval','var')
        args.interval = interval;
    end

    if ~exist('category_val_list','var')
        args.interval = interval;
    end
    
    args.within_ranges = 1;
    [datamatrix, ~] = extract_multi_measures(var_list, subexpID, fullfile(output_file_dir,'reference_extract_output.csv'), args);

    % create a tmp_var_list to track temporary variables created
    tmp_var_list = {};

    % iterate through each dependent variable to create temporary variables
    full_sub_list = cIDs(subexpID);


    for i = 1:size(full_sub_list,1)
        % check if base variable exists
        root = get_subject_dir(full_sub_list(i));
        base_var_filename = fullfile(root,'derived',[event_var '.mat']);

        if ~exist(base_var_filename,'file')
            error('Subject %d doesn''t have variable %s', full_sub_list(i),base_var_filename);
        elseif ~isempty(get_variable(full_sub_list(i),event_var))
            % parse base variable timestamps for each subject
            onset = datamatrix(datamatrix(:,1)==full_sub_list(i),3);
            offset = datamatrix(datamatrix(:,1)==full_sub_list(i),4);
            target_cat = datamatrix(datamatrix(:,1)==full_sub_list(i),5);
            base_var = get_variable(full_sub_list(i),event_var);
            start_bound = base_var(1,2);
            end_bound = base_var(end,2);
    
            for j = 1:size(var_list,2)
                % get cstream var name, hard-coded to get cstream variable name
                % based on cevent varname
                cevent_varname = char(var_list(j));
                cstream_varname = ['cstream' cevent_varname(7:end)];
    
                cevent_var_filename = fullfile(root,'derived', [cevent_varname '.mat']);
                
                % check if dependent variable exists
                if ~exist(cevent_var_filename, 'file')
                    cevent_var = get_variable(full_sub_list(i),event_var);
                    cevent_var(:,3) = 0;
                    
                    % convert cevent var to cstream for creating tmp var
                    curr_var = cevent2cstream(cevent_var,cevent_var(1,1),0.001,0);
    
                    % print 'no var found' warning message
                    sprintf('Variable %s was not found for subject %d. \n', cevent_varname,full_sub_list(i));
                else
                    cevent_var = get_variable(full_sub_list(i),cevent_varname);

                    if ~isempty(cevent_var)
                        % convert cevent var to cstream for creating tmp var
                        curr_var = cevent2cstream(cevent_var,base_var(1,1),0.001,0); % only get data starting at the onset of base variable
                    else
                        cevent_var = get_variable(full_sub_list(i),event_var);
                        cevent_var(:,3) = 0;
                        
                        % convert cevent var to cstream for creating tmp var
                        curr_var = cevent2cstream(cevent_var,cevent_var(1,1),0.001,0);
        
                        % print 'empty var found' warning message
                        sprintf('Variable %s was empty for subject %d. \n', cevent_varname,full_sub_list(i));
                    end
    
                    
        
                    % iterate through each timestamp range defined by extract_multi_measures(),
                    % mark instances within range as 0
                    for k = 1:size(onset,1)
                        if k < size(onset,1)
                            % if flag is 'target', set non-target streams
                            % to zero
                            if strcmp(flag,'target')
                                curr_var(curr_var(:,1) >= onset(k) & curr_var(:,1) <= offset(k) & curr_var(:,2)~=target_cat(k),2) = 0;
                            end

                            % set streams between base var instances as
                            % zero
                            curr_var(curr_var(:,1)>=offset(k) & curr_var(:,1)<=onset(k+1),2) = 0;
                        else
                            if strcmp(flag,'target')
                                curr_var(curr_var(:,1) >= onset(k) & curr_var(:,1) <= offset(k) & curr_var(:,2)~=target_cat(k),2) = 0;
                            end

                            curr_var(curr_var(:,1)>=offset(k),2) = 0;
                        end
                    end
        
                    % mark events start before the first onset and after the last offset of base variable as 0
                    curr_var(curr_var(:,1) > end_bound) = 0;
                    curr_var(curr_var(:,1) < start_bound) = 0;
                end
    
                % save as a temporary variable
                tmp_varname = [cstream_varname '_tmp'];
                tmp_var_list{end+1} = tmp_varname;
                record_additional_variable(full_sub_list(i),tmp_varname,curr_var);
            end
    
            if i ~= size(full_sub_list,1)
                % reset tmp variable list
                tmp_var_list = {};
            end
        end
    end

    % call vis_stream_multiwork on temporary variables
    var_display_list = horzcat(event_var,tmp_var_list);
    vis_streams_multiwork(subexpID, var_display_list, streamlabels, output_file_dir);

    % delete temporary variables
    delete_variables(subexpID,tmp_var_list);
end