% return the height and width of the target camera for each subject
% in subs
% Missing data is marked by 0 0
function [sz, camFolders] = get_frame_size(subs, subDirs, camID)
    sz = zeros(height(subDirs),2);
    camFolders = strings(height(subDirs),1);

    for i = 1:height(subDirs)
        subID = subs(i);
        camFolder = fullfile(subDirs{i},sprintf('cam%02d_frames_p',camID));
        fm_path = fullfile(camFolder, 'img_1.jpg');
  

        if ~isfile(fm_path)
            fprintf('[SKIPPING] subID %d | %s is empty\n', subID, camFolder)
            continue
        end

        fm = imread(fm_path);
        fm_size = size(fm);

        sz(i,:) = [fm_size(1), fm_size(2)];
        camFolders(i,1) = camFolder;
    end
end