function sync_saccades = parse_neon_saccades(date, kidID, expID, agent)

    root = get_d_drive_kid_root(date,kidID, expID);
    if strcmp(agent,'child')
        agent_root = fullfile(root,'child_pupil');
        sync_offset = 0;
    elseif strcmp(agent,'parent')
        agent_root = fullfile(root,'parent_pupil');

        % parse saccades offset
        sync_offset = dlmread(fullfile(root,'parent_sync_offset.txt'));
        % convert sync offset to nanoseconds
        sync_offset = sync_offset * 1000000000;
    end

    % read raw saccades file
    raw_saccades = readtable(fullfile(agent_root,'saccades.csv'));
    saccades_onset = raw_saccades{:,4};
    saccades_offset = raw_saccades{:,5};
    saccades_visual_angle = raw_saccades{:,8};

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
    saccades_onset = (saccades_onset - sync_offset - worldtime_start)/1000000000;
    saccades_offset = (saccades_offset - sync_offset - worldtime_start)/1000000000;


    sync_saccades = horzcat(saccades_onset, saccades_offset,saccades_visual_angle);

    for i = 1:size(chunk_info,1)
        expID = exp_list(i);
        onset = onset_list(i) / 30; % convert frame to sec, 30 fps
        offset = offset_list(i) /30; % convert frame to sec, 30 fps

        % perform chunking
        index = sync_saccades(:,1) >= onset & sync_saccades(:,2) <= offset;
        chunked_saccades = sync_saccades(index,:);
        chunked_saccades(:,1:2) = (chunked_saccades(:,1:2) - onset)*1000;
    
        chunked_saccades_table = array2table(chunked_saccades,'VariableNames',{'onset','offset','rotate_angles'});
    
        % % if subject folder on chunk_data folder, save saccades
        % % files to chunk_data folder
        % chunk_data_dir = fullfile(root, 'chunk_data',sprintf('%d*', expID));
        % if exist(chunk_data_dir, 'dir')
        %     dnames = dir(chunk_data_dir);
        %     foldernames = {dnames(:).name};
        %     subexp_folder_name = fullfile(root, 'chunk_data', foldernames{1});
        %     output_filename = fullfile(subexp_folder_name,sprintf('%s_saccades.csv',agent));
        %     writetable(chunked_saccades_table,output_filename);
        % end
        % 
        % if subject folder already exists on temp_backus, save saccades
        % files to temp_backus as well
        temp_backus_dir = fullfile(get_temp_backus_root(),sprintf('experiment_%d',expID),'included',sprintf('__%d_%d',date,kidID),'supporting_files');
        if exist(temp_backus_dir, 'dir')
            temp_backus_output_filename = fullfile(temp_backus_dir,sprintf('%s_saccades.csv',agent));
            writetable(chunked_saccades_table,temp_backus_output_filename);
        end

        % if subject folder already exists on multi-work, save saccades
        % files to temp_backus as well
        multi_work_dir = fullfile(get_multidir_root(),sprintf('experiment_%d',expID),'included',sprintf('__%d_%d',date,kidID),'supporting_files');
        if exist(multi_work_dir, 'dir')
            multi_work_output_filename = fullfile(multi_work_dir,sprintf('%s_saccades.csv',agent));
            writetable(chunked_saccades_table,multi_work_output_filename);
        end
    end
end