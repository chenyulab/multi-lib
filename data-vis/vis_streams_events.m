%%%
% Author: Jane Yang
% Last Modified: 06/06/2024
% This function displays event-based data stream visualization based on
% extract_multi_measures()
%
% Input: subexpID                 - a list of subID or expID
%        event_var                - base variable to pass to extract_multi_measures()
%        var_list                 - a list of dependent variables
%        cevent_values            - a list of cevent values to parse for events
%        output_file_dir          - directory to save output data visualization
%        args.whence              - 'start','end', or 'startend'
%        args.interval            - [0 3] interval to modify the timestamps
%        args.showSingleColor     - only display the instances which have
%                                   the same obj category as the base event
%        args.displayObjList      - a list of categories to display
%
% Output: one data visualization for each subject
% 
%
% Dependent function called: extract_multi_measures()
% 
% Example function call: vis_streams_events([351],'cevent_speech_naming_local-id',{'cevent_eye_roi_child','cevent_eye_roi_parent','cevent_inhand_child','cevent_inhand_parent'},'naming-eye-inhand_3s-after-onset',args)
%                        
%%%

function vis_streams_events(subexpID,cevent_name,var_list,cevent_values,streamlabels,output_file_dir,args)
    % check if args exists
    if ~exist('args', 'var') || isempty(args)
        args = struct([]);
    end

    if isfield(args, 'whence')
        whence = args.whence;
    end

    if isfield(args, 'interval')
        interval = args.interval;
    end

    if isfield(args, 'showSingleColor')
        showSingleColor = args.showSingleColor;
    else
        showSingleColor = 0;
    end

    if isfield(args, 'displayObjList')
        displayObjList = args.displayObjList;
    else
        displayObjList = [];
    end

    disp(displayObjList);

    % call extract_multi_measures() using within_ranges to get event
    % timestamps that are between ranges
    if ~isempty(args)
        args.cevent_name = cevent_name;
        args.cevent_values = cevent_values;
    else
        args = struct('cevent_name',cevent_name,'cevent_values',cevent_values);
    end
    
    args.within_ranges = 1;

    % find a list of subjects with relevant variables
    sub_list = cIDs(subexpID);
    sub_list = find_subjects(horzcat(var_list,cevent_name,'cstream_trials'),unique(sub2exp(sub_list)));

    [datamatrix, ~] = extract_multi_measures(var_list, sub_list, fullfile(output_file_dir,'reference_extract_output.csv'), args);

    % create a tmp_var_list to track temporary variables created
    tmp_var_list = {};
    
    % iterate thru subjects and generate temporary variables
    for i = 1:size(sub_list,1)
    % for i = 2
        tmp_var_list = {}; % reset temporary variables cell array
        
        subID = sub_list(i); % get current subject ID
        
        % load base variable
        base_var = get_variable_by_trial_cat(subID,cevent_name);

        % filter base variable by target object categories
        base_var = base_var(ismember(base_var(:,3),cevent_values),:);

        % load trial variable for cevent to cstream conversion later
        trials = get_variable_by_trial_cat(subID,'cstream_trials');
        % get trial timebase
        tb = trials(:,1);

        % parse subject datamatrix
        sub_data = datamatrix(datamatrix(:,1)==subID,:);

        if isempty(base_var) % check if base variable is empty
            sprintf('Variable %s is empty for subject %d! Outputting an empty visualization!\n',cevent_name,subID);

            % record temporary base cevent variable
            base_varname_tmp = [cevent_name '_tmp'];
            record_additional_variable(subID,base_varname_tmp,base_var);

            % TODO: debug this
            vis_streams_multiwork(subID, {base_varname_tmp}, streamlabels(1), output_file_dir);
        else
            % record temporary base cevent variable
            base_varname_tmp = [cevent_name '_tmp'];
            record_additional_variable(subID,base_varname_tmp,base_var);

            % parse base variable timestamps for each subject from
            % extract_multi_measure output
            onset = sub_data(:,3);
            offset = sub_data(:,4);
            target_category = sub_data(:,5);

            % get a onset range for base variable
            start_bound = sub_data(1,3);
            end_bound = sub_data(end,4);

            % iterate thru a list of dependent variables to visualize
            for j = 1:size(var_list,2)
                cevent_varname = char(var_list(j));
                cev = get_variable_by_trial_cat(subID,cevent_varname);

                % filter cevent variable based on target categories
                % cev = cev(ismember(cev(:,3),cevent_values),:);

                if ~isempty(cev) % check if cevent var is empty
                    % convert cevent to cstream
                    curr_var = cevent2cstreamtb(cev,tb);

                    % mark events start before the first onset and after the last offset of base variable as 0
                    curr_var(curr_var(:,1) > end_bound,2) = 0;
                    curr_var(curr_var(:,1) < start_bound,2) = 0;

                    % iterate through each timestamp range defined by extract_multi_measures(),
                    % mark instances within range as 0
                    for k = 1:size(onset,1)
                        if k < size(onset,1)
                            curr_var(curr_var(:,1)>offset(k) & curr_var(:,1)<onset(k+1),2) = 0;

                            % %%% TODO: Add an if-statement here if a flag is
                            % %%% added
                            if showSingleColor
                                curr_var(curr_var(:,1)>=offset(k) & curr_var(:,1)<=onset(k+1) & curr_var(:,2)~=target_category(k),2) = 0;
                                curr_var(curr_var(:,1)<=offset(k) & curr_var(:,1)>=onset(k) & curr_var(:,2)~=target_category(k),2) = 0;
                            end
                            % 
                            % % check if only want to display a subset of
                            % % objects
                            if ~isempty(displayObjList)
                                curr_var(curr_var(:,1)>=offset(k) & curr_var(:,1)<=onset(k+1) & ~ismember(curr_var(:,2),displayObjList),2) = 0;
                                curr_var(curr_var(:,1)<=offset(k) & curr_var(:,1)>=onset(k) & ~ismember(curr_var(:,2),displayObjList),2) = 0;
                            end
                        else % last instance
                            curr_var(curr_var(:,1)>offset(k),2) = 0;

                            % %%% TODO: Add an if-statement here if a flag is
                            % %%% added
                            if showSingleColor
                                curr_var(curr_var(:,1)>=offset(k) & curr_var(:,2)~=target_category(k),2) = 0;
                                curr_var(curr_var(:,1)<=offset(k) & curr_var(:,1)>=onset(k) & curr_var(:,2)~=target_category(k),2) = 0;
                            end
                            % 
                            % % check if only want to display a subset of
                            % % objects
                            if ~isempty(displayObjList)
                                curr_var(curr_var(:,1)>=offset(k) & ~ismember(curr_var(:,2),displayObjList),2) = 0;
                                curr_var(curr_var(:,1)<=offset(k) & curr_var(:,1)>=onset(k) & ~ismember(curr_var(:,2),displayObjList),2) = 0;
                            end
                        end
                    end

                    % save as a temporary variable
                    varname_split = strsplit(cevent_varname,'_');
                    cstream_varname = strjoin(varname_split(2:end),'_');
                    tmp_varname = ['cstream_' cstream_varname '_tmp'];
                    tmp_var_list{end+1} = tmp_varname;
                    record_additional_variable(subID,tmp_varname,curr_var);
                else
                    % print 'no var found' warning message
                    sprintf('Variable %s was not found for subject %d. \n', cevent_varname,subID);

                    curr_var = horzcat(tb,zeros(size(tb(:,1)))); % set current variable to zeros to visualize empty data stream
                end            
            end
            % call vis_stream_multiwork on temporary variables
            var_display_list = horzcat(base_varname_tmp,tmp_var_list);
            vis_streams_multiwork(subID, var_display_list, streamlabels, output_file_dir);
        end
    end
    % delete temporary variables
    delete_variables(sub_list,tmp_var_list); %%% TODO: not sure if this is the best place to put this, because tmp_var_list may differ for each subject pending which vars are not empty
end