% Author: Ruchi Shah
% Last modified: 03/20/2024
% Summary
    % This is a helper function intended for extract_basic_demographic() to
    % get the demographic survey data csv. This works on both Windows and Mac.
    % Output:
    %       demographic survey data table

function [demo_data] = get_demo_survey_csv()
    if ismac % Mac
        demo_data = readtable("/Volumes/multiwork/HOME_survey.xlsx");
    elseif ispc  % Windows
        demo_data = readtable("M:\HOME_survey.xlsx");
    else % maybe add for linux?
        disp('Platform not supported')
    end
end

