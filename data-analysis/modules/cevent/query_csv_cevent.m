%%
% Author: Jane Yang
% Last modified: 12/05/2023
% This function takes in a list of subjects, a cevent variable name, and a
% list of target objIDs, outputting a detailed csv containing instances 
% where the target ROI was found in the event variable. 
%
% Input: Name                       Description
%        expIDs                     a list of expIDs
%
%        cevent_varname             base cevent variable name to query
%
%        target_obj_list            A list of target objIDs to query
%
%        output_filename            output filename for the returned csv
%
%        args.cam                   optional camera ID of the source video,
%                                   default at cam7 (kid's view)
%
%
%        args.whence                string, 'start', 'end', or 'startend'
%                                   this parameter, when combined with args.interval, 
%                                   allows you to shift the args.cevent_name window times by a certain amount. 
%                                   The shift can be respect to the start, end, or full event.
%
%        args.interval              array of 2 numbers, [t1 t2], 
%                                   where t1 and t2 refer to the offset to apply in each args.cevent_name window times.
%
% Output: a csv file containing timestamp and source camera information for
% instancs found.
% 
% Example function call: rtr_table = query_csv_cevent([12],'cevent_eye_joint-attend_child-lead-moment_both',[1:24],'M:\event_clips\test','test.csv',args)

function rtr_table = query_csv_cevent(expIDs, cevent_varname, target_obj_list,output_dir, output_filename,args)
    % check if optional argument exists
    if ~exist('args', 'var') || isempty(args)
        args = struct([]);
        whence = '';
        interval = [0 0];
    end
    
    if isfield(args,'whence') && isfield(args,'interval')
        whence = args.whence;
        interval = args.interval;
    elseif isfield(args,'whence') && ~isfield(args,'interval')
        error('Please enter an interval parameter with whence parameter.');
    end
    
    if isfield(args,'cam')
        cam = args.cam;
    else
        cam = 7; % default to cam07 --> kid's view
    end
    
    %%% TODO: maybe change this name??
    if isfield(args,'window')
        window = args.window;
    else
        window = 0; % default to window 0 --> words need to be in the same utterance
    end

    if isfield(args,'whence')
        whence = args.whence;
    else
        whence = ''; % default to empty string
    end
    
    if numel(expIDs) == 0
        error('[-] Error: Invalid experiment input. Please enter at least one experiment to query.')
    end
    
    % initialize column names for return table
    rtr_table = table();

    %%% TODO: change to a more flexible way of initializing column names
    %%% later --> for multiple words
    colNames = {'subID','fileID',...
                'onset1_system_time','onset1_frame',...
                'offset1_system_time','offset1_frame',...
                'objID1','source_video_path','source_audio_path','extract_range_onset'};
    
    % get a list of subjects that has the target variable
    subs = find_subjects(cevent_varname,expIDs);
    
    % iterate through subjects in the experiment list
    for s = 1:size(subs,1)
        % get subject-level relevant info
        subID = subs(s);
        root = get_subject_dir(subID);
        subInfo = get_subject_info(subID);
        fileID = cellstr(sprintf('__%d_%d',subInfo(3),subInfo(4)));
        kidID = subInfo(end);
        
        % load the target variable
        cevent = get_variable_by_trial_cat(subID,cevent_varname);

        if ~isempty(cevent) % in case cevent var is empty
            % find instances that contains the target object
            match_cevent = cevent(ismember(cevent(:,3),target_obj_list),:);
    
    
            % check if need to modify timestamps
            if ~isempty(whence)
                match_onset = match_cevent(:,1);
                match_offset = match_cevent(:,2);
                if strcmp(whence,'start')
                    modified_onset = match_onset + interval(1);
                    modified_offset = match_onset + interval(2);
                elseif strcmp(whence,'end')
                    modified_onset = match_offset + interval(1);
                    modified_offset = match_offset + interval(2);
                elseif strcmp(whence,'startend')
                    modified_onset = match_onset + interval(1);
                    modified_offset = match_offset + interval(2);
                end
    
                % match_cevent = [];
                match_cevent(:,1) = modified_onset;
                match_cevent(:,2) = modified_offset;
            end
    
            % find corresponding timestamps in frame number
            match_onset_frames = time2frame_num(match_cevent(:,1),subID);
            match_offset_frames = time2frame_num(match_cevent(:,2),subID);
    
            % find video source path
            source_vid_path = cellstr(fullfile(root,sprintf('cam%02d_frames_p',cam)));
    
            % find audio source path
            audio_root = fullfile(root,'speech_r');
            audio_fileList = dir(fullfile(audio_root,'*.wav'));
            % check if audio file exists
            if ~isempty(audio_fileList)
                % set the first audio file in the directory as source audio
                source_aud_path = cellstr(fullfile(audio_fileList(1).folder,audio_fileList(1).name));
            else
                sprintf('Subject %s does not have an audio file!',subID);
                source_aud_path = {''};
            end
    
    
            % get extract range onset
            extract_range_file = fullfile(root,'supporting_files','extract_range.txt');
            range_file = fopen(extract_range_file,'r');
            extract_range_onset = fscanf(range_file,'[%f]');
    
            % setting up subject-level entry table
            num_match = size(match_cevent,1); % number of matching instances
            subID_col = repmat(subID,num_match,1);
            fileID_col = repmat(fileID,num_match,1);
            source_vid_path_col = repmat(source_vid_path,num_match,1);
            source_aud_path_col = repmat(source_aud_path,num_match,1);
            extract_range_onset_col = repmat(extract_range_onset,num_match,1);
    
            % create subject-level entry
            sub_entry = table(subID_col,fileID_col,...
                              match_cevent(:,1),match_onset_frames,...
                              match_cevent(:,2),match_offset_frames,...
                              match_cevent(:,3),source_vid_path_col,source_aud_path_col,extract_range_onset_col,'VariableNames',colNames);
            % append to return table
            rtr_table = [rtr_table;sub_entry];
        end
    end
    % save table to a csv file
    %%% TODO: change output_filename to handle multi-words case
    writetable(rtr_table,fullfile(output_dir,output_filename),'WriteVariableNames', true);
end