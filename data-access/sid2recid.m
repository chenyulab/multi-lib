% get recording ID from subID
% either in the form __date_kidID or date, kidID
% 
% subID2recordingID takes:
%   (date, kidID, format)
%  where format is 1 or 2 as int 
%  1 = tuple (data, kidID)
%  2 = string ('__data_kidID')
%
%
% Example:
%   recordingID = subID2recordingID(35101, 351);

function recordingID = subID2recordingID(subID, expID, format)
    %subject_id, experiment_num, date, kid_id
   sub_table = read_subject_table();

    % Build mask
    mask = sub_table(:,1) == subID & ...
           sub_table(:,2) == expID;

    if ~any(mask)
        fprintf('no match found for \n subID: %d, \n expID: %d\n', subID, expID)
        recordingID = [];
        return 
    end

    % Extract match
    recordingID = sub_table(mask, [3,4]);

    if format == 2
        recordingID = sprintf('__%d_%d',recordingID(1),recordingID(2));
    end
end
