function backup_exp_data()

% Input experiment IDs and folder names
exp_ids = [12, 15, 351, 353, 361, 362, 363, 70:75, 91, 27, 77:79, 65:69, 58, 59, 96];
folders = {'derived', 'reliability', 'speech_transcription_p', 'supporting_files'};

% Generate a timestamped backup folder name
timestamp = datestr(datetime('now'), 'yyyymmdd_HHMMSS');
backup_base_dir = fullfile('C:',sprintf('backup_%s', timestamp));

% Directory to store the ZIP file
zip_destination_dir = 'B:\exp_data_backup'; 

% Create the backup base directory
if ~exist(backup_base_dir, 'dir')
    mkdir(backup_base_dir);
end

% Get subject IDs
sub_ids = cIDs(exp_ids);

% Iterate over subject IDs
for s = 1:length(sub_ids)
    sub_id = sub_ids(s);
    try
        % Get subject info and directory
        sub_info = get_subject_info(sub_id);
        sub_dir = get_subject_dir(sub_id);
        
        % Check if the subject directory exists
        if ~exist(sub_dir, 'dir')
            error('Subject folder does not exist: %s', sub_dir);
        end
        
        % Create target experiment directory
        experiment_dir = fullfile(backup_base_dir, sprintf('experiment_%d', sub2exp(sub_id)));
        if ~exist(experiment_dir, 'dir')
            mkdir(experiment_dir);
        end
        
        % Create subject info directory
        subject_info_dir = fullfile(experiment_dir, sprintf('__%d_%d', sub_info(3), sub_info(4)));
        if ~exist(subject_info_dir, 'dir')
            mkdir(subject_info_dir);
        end
        
        % Copy trial info files
        trial_info_mat_file = sprintf('__%d_%d_info.mat', sub_info(3), sub_info(4));
        trial_info_txt_file = sprintf('__%d_%d_info.txt', sub_info(3), sub_info(4));
        
        mat_file_path = fullfile(sub_dir, trial_info_mat_file);
        txt_file_path = fullfile(sub_dir, trial_info_txt_file);
        
        if exist(mat_file_path, 'file')
            copyfile(mat_file_path, subject_info_dir);
        else
            warning('MAT file not found for subject %d: %s', sub_id, mat_file_path);
        end
        
        if exist(txt_file_path, 'file')
            copyfile(txt_file_path, subject_info_dir);
        else
            warning('TXT file not found for subject %d: %s', sub_id, txt_file_path);
        end
        
        % Copy folders
        for f = 1:length(folders)
            folder_name = folders{f};
            source_folder = fullfile(sub_dir, folder_name);
            target_folder = fullfile(subject_info_dir, folder_name);
            
            if strcmp(folder_name, 'extra_p') && exist(source_folder, 'dir')
                % Special handling for 'extra_p' folder
                files = dir(fullfile(source_folder, '*boxes.mat')); % Match 'boxes.mat'
                files_face = dir(fullfile(source_folder, '*boxes_face.mat')); % Match 'boxes_face.mat'
                all_files = [files; files_face];
                
                % Create the target folder
                if ~exist(target_folder, 'dir')
                    mkdir(target_folder);
                end
                
                % Copy only the matched files
                for file = all_files'
                    copyfile(fullfile(source_folder, file.name), target_folder);
                end
            elseif strcmp(folder_name, 'supporting_files') && exist(source_folder, 'dir')
                % Special handling for 'supporting_files' - only direct files
                files = dir(fullfile(source_folder, '*')); % List all items
                files = files(~[files.isdir]); % Filter out directories
                
                % Create the target folder
                if ~exist(target_folder, 'dir')
                    mkdir(target_folder);
                end
                
                % Copy only the files in the folder, not subfolders
                for file = files'
                    copyfile(fullfile(source_folder, file.name), target_folder);
                end
            elseif exist(source_folder, 'dir')
                % Normal folder copy for other folders
                copyfile(source_folder, target_folder);
            else
                warning('Folder not found for subject %d: %s', sub_id, source_folder);
            end
        end
        
    catch ME
        % Log the error and continue with the next subject
        fprintf('Error processing subject %d: %s\n', sub_id, ME.message);
        continue;
    end
end

% Create a ZIP file of the backup folder
zip_file_name = sprintf('%s.zip', backup_base_dir);
try
    zip(zip_file_name, backup_base_dir);
    disp(['Backup folder successfully zipped as: ' zip_file_name]);
    
    % Move the ZIP file to the specified destination
    movefile(zip_file_name, zip_destination_dir);
    disp(['ZIP file moved to: ' fullfile(zip_destination_dir, zip_file_name)]);
    
    % Delete the original backup folder
    rmdir(backup_base_dir, 's');
    disp(['Original backup folder deleted: ' backup_base_dir]);
catch ME
    fprintf('Error during ZIP or cleanup process: %s\n', ME.message);
end

disp('Backup process completed.');

end