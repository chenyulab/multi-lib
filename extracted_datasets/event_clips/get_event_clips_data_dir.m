function data_dir = get_event_clips_data_dir()
    % This is the default path for event clips data directory
    multiwork_dir = get_multidir_root();
    data_dir = fullfile(multiwork_dir,'extracted_datasets\event_clips\event_data');
end