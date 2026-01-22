% get subID from recording ID by reading the subject table
% recordingID2subID either takes:
%   (date, kidID, expID)
% or
%   (recordingID, expID)
%
% recordingID format must be 'date_kidID'
%
% Example:
%   match = recordingID2subID(20221112, 10041, 351);
%   match = recordingID2subID('20221112_10041', 351);

function subID = recid2sid(a, b, c)

    % Determine input format
    if nargin == 2
        % Format is (recordingID, expID)
        recordingID = a;
        expID = b;

        % Ensure string
        recordingID = string(recordingID);

        % Split on underscore
        parts = split(recordingID, "_");
        if numel(parts) ~= 4
            error('recordingID must be formatted as "date_kidID".');
        end

        % Parse date and kidID as numbers
        date = str2double(parts(3));
        kidID = str2double(parts(4));

        if isnan(date) || isnan(kidID)
            error('recordingID must contain numeric date and kidID.');
        end

    elseif nargin == 3
        % Format is (date, kidID, expID)
        date = a;
        kidID = b;
        expID = c;
    else
        error('Function must be called with either 2 or 3 arguments.');
    end

    % Load table
    sub_table = read_subject_table();

    % Build mask
    mask = sub_table(:,3) == date & ...
           sub_table(:,4) == kidID & ...
           sub_table(:,2) == expID;
    
    if ~any(mask)
        fprintf('no match found for \n date: %d\n kidID: %d\n expID: %d\n', date, kidID, expID)
        subID = [];
        return 
    end

 
    % Extract match
    subID = sub_table(mask, 1);
end
