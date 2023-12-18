function sync_fixation = parse_neon(date, kidID, expID, agent)
    % fixation_file,world_file,sync_file,chunk_file,output_fixation_file
    % TODO: parameter checking

    % obtain path to raw gaze_positions.csv pupil labs output on D drive
    root = get_d_drive_kid_root(date,kidID, expID);
    if strcmp(agent,'child')
        agent_root = fullfile(root,'child_pupil');
        sync_offset = 0;
    elseif strcmp(agent,'parent')
        agent_root = fullfile(root,'parent_pupil');

        % parse fixation offset
        sync_offset = dlmread(fullfile(root,'parent_sync_offset.txt'));
        % convert sync offset to nanoseconds
        sync_offset = sync_offset * 1000000000;
    end

    % read raw fixation file
    raw_fixation = readtable(fullfile(agent_root,'fixations.csv'));
    fixation_onset = raw_fixation{:,4};
    fixation_offset = raw_fixation{:,5};

    % get the start of recording from absolute world time
    worldtime = readtable(fullfile(agent_root,'world_timestamps.csv'));
    worldtime_start = worldtime{1,3}; % in nanoseconds

    % parse chunking info file
    chunk_info = dlmread(fullfile(root,'chunk_info.txt'));
    act_list = chunk_info(:,1);
    exp_list = chunk_info(:,2);
    onset_list = chunk_info(:,3);
    offset_list = chunk_info(:,4);

    
    % apply sync offset to modified worldtime
    fixation_onset = (fixation_onset - sync_offset - worldtime_start)/1000000000;
    fixation_offset = (fixation_offset - sync_offset - worldtime_start)/1000000000;


    sync_fixation = horzcat(fixation_onset, fixation_offset);

    for i = 1:size(chunk_info,1)
        expID = exp_list(i);
        onset = onset_list(i) / 30; % convert frame to sec, 30 fps
        offset = offset_list(i) /30; % convert frame to sec, 30 fps

        dnames = dir(fullfile(root, 'chunk_data',sprintf('%d*', expID)));
        foldernames = {dnames(:).name};
        subexp_folder_name = fullfile(root, 'chunk_data', foldernames{1});
        output_filename = fullfile(subexp_folder_name,sprintf('%s_fixation.csv',agent));

        % perform chunking
        index = sync_fixation(:,1) >= onset & sync_fixation(:,2) <= offset;
        chunked_fixation = sync_fixation(index,:);
        chunked_fixation = (chunked_fixation - onset)*1000;
    
        chunked_fixation_table = array2table(chunked_fixation,'VariableNames',{'onset','offset'});
    
        % writetable(chunked_fixation_table,output_filename); % TODO: may need to change this to save to corresponding folder on tempbackus? depending on the stage of processing

        % if subject folder already exists on temp_backus, save fixation
        % files to temp_backus as well
        temp_backus_dir = fullfile(get_temp_backus_root(),sprintf('experiment_%d',expID),'included',sprintf('__%d_%d',date,kidID),'supporting_files');
        if exist(temp_backus_dir, 'dir')
            temp_backus_output_filename = fullfile(temp_backus_dir,sprintf('%s_fixation.csv',agent));
            % disp(temp_backus_output_filename);
            % writetable(chunked_fixation_table,temp_backus_output_filename);
        end
    end
end