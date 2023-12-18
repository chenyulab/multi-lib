function root = get_d_drive_kid_root(date, kidID, expID)
    % This function get the raw data path on with kidID and expID
    root = fullfile('D:\merged_data\', sprintf('%d',expID));
    dnames = dir(fullfile(root, sprintf('*__%d_%d', date,kidID)));
    foldernames = {dnames(:).name};
    root = fullfile(root, foldernames{1});
end