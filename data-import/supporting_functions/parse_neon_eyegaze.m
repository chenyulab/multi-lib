function sync_eyegaze = parse_neon_eyegaze(date, kidID, expID, agent)

    root = get_d_drive_kid_root(date,kidID, expID);
    if strcmp(agent,'child')
        agent_root = fullfile(root,'child_pupil');
        sync_offset = 0;
    elseif strcmp(agent,'parent')
        agent_root = fullfile(root,'parent_pupil');

        % parse eyegaze offset
        sync_offset = dlmread(fullfile(root,'parent_sync_offset.txt'));
        % convert sync offset to nanoseconds
        sync_offset = sync_offset * 1000000000;
    end

    % read raw eyegaze file
    raw_eyegaze = readtable(fullfile(agent_root,'fixations.csv'));
    eyegaze_onset = raw_eyegaze{:,4};
    eyegaze_offset = raw_eyegaze{:,5};
    eyegaze_x = raw_eyegaze{:,7};
    eyegaze_y = raw_eyegaze{:,8};

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
    eyegaze_onset = (eyegaze_onset - sync_offset - worldtime_start)/1000000000;
    eyegaze_offset = (eyegaze_offset - sync_offset - worldtime_start)/1000000000;


    sync_eyegaze = horzcat(eyegaze_onset, eyegaze_offset,eyegaze_x,eyegaze_y);

    for i = 1:size(chunk_info,1)
        expID = exp_list(i);
        onset = onset_list(i) / 30; % convert frame to sec, 30 fps
        offset = offset_list(i) /30; % convert frame to sec, 30 fps

        % perform chunking
        index = sync_eyegaze(:,1) >= onset & sync_eyegaze(:,2) <= offset;
        chunked_eyegaze = sync_eyegaze(index,:);
        chunked_eyegaze(:,1:2) = (chunked_eyegaze(:,1:2) - onset)*1000;
    
        chunked_eyegaze_table = array2table(chunked_eyegaze,'VariableNames',{'onset','offset','gazex','gazey'});
    
        % % if subject folder on chunk_data folder, save eyegaze
        % % files to chunk_data folder
        % chunk_data_dir = fullfile(root, 'chunk_data',sprintf('%d*', expID));
        % if exist(chunk_data_dir, 'dir')
        %     dnames = dir(chunk_data_dir);
        %     foldernames = {dnames(:).name};
        %     subexp_folder_name = fullfile(root, 'chunk_data', foldernames{1});
        %     output_filename = fullfile(subexp_folder_name,sprintf('%s_eyegaze.csv',agent));
        %     writetable(chunked_eyegaze_table,output_filename);
        % end
        % 
        % if subject folder already exists on temp_backus, save eyegaze
        % files to temp_backus as well
        temp_backus_dir = fullfile(get_temp_backus_root(),sprintf('experiment_%d',expID),'included',sprintf('__%d_%d',date,kidID),'supporting_files');
        if exist(temp_backus_dir, 'dir')
            temp_backus_output_filename = fullfile(temp_backus_dir,sprintf('%s_eye.csv',agent));
            writetable(chunked_eyegaze_table,temp_backus_output_filename);
        end

        % if subject folder already exists on multi-work, save eyegaze
        % files to temp_backus as well
        multi_work_dir = fullfile(get_multidir_root(),sprintf('experiment_%d',expID),'included',sprintf('__%d_%d',date,kidID),'supporting_files');
        if exist(multi_work_dir, 'dir')
            multi_work_output_filename = fullfile(multi_work_dir,sprintf('%s_eye.csv',agent));
            writetable(chunked_eyegaze_table,multi_work_output_filename);
        end
    end
end