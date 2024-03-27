%%%
% Author: Jane Yang
% Last modifier: 2/29/2024 (Leap Day!)
% 
% Description: This function takes in one required argument and three
% optional arguments (visitIDs, ageRange, and kidID), returning a list of 
% subjects that fall into the query category. Users can freely assign any 
% optional arguments for more specific subject query. visitIDs defaults at
% [1,2,3], returning all subjects participated in the study regardless of
% the number of visits. ageRange defaults at [0,40], including kids between
% 0 to 40 months old. If a user would like to know all the subIDs for a
% kid, the user can do so by specifying the kidID. Users can choose to
% assign any or all three optional arguments.
%
% This function ONLY targets experiment 350+ (home2 experiments).
%
% Input:        Name        Description
%               expIDs      a list of experiment IDs - [351, 353]
%               varargin    optional parameters:
%                               - visitIDs: a list incidates the number of
%                                           visits - [1] or [1,2] etc.
%                               - ageRange: an array specifying the age
%                                           range
%                               - kidID: a list of kidID or one kidID
%
% Output: an array of subject IDs
%%%
% sub_list = list_home2_subjects(351, 'visitIDs', [2], 'ageRange', [12 24])
function sub_list = list_home2_subjects(expIDs,varargin)
    % define default values for optional parameters
    ageRange = [0 40];
    visitIDs = [1 2 3 4];
    kidID = 0;

    % Parse input arguments: Method 1
    % numArgs = length(varargin);
    % if numArgs > 1
    %     visitIDs = varargin{1};
    %     disp(visitIDs);
    % end
    % if numArgs > 2
    %     ageRange = varargin{2};
    % end
    % if numArgs > 3
    %     kidID = varargin{3};
    % end

    % Parse input arguments: Method 2
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i}, 'visitIDs')
            visitIDs = varargin{i+1};
        elseif strcmpi(varargin{i}, 'ageRange')
            ageRange = varargin{i+1};
        elseif strcmpi(varargin{i}, 'kidID')
            kidID = varargin{i+1};
        else
            error('Invalid parameter name: %s', varargin{i});
        end
    end

    % read subject table
    sub_table = table2array(read_home2_subject_table());

    % if kidID not specified
    if kidID == 0
        sub_list = sub_table(ismember(sub_table(:,2),expIDs) & ismember(sub_table(:,5),visitIDs) & sub_table(:,6) >= ageRange(1) & sub_table(:,6) <= ageRange(2),1);
    else % special case: query subIDs for the same kid
        sub_list = sub_table(ismember(sub_table(:,2),expIDs) & ismember(sub_table(:,5),visitIDs) & sub_table(:,6) >= ageRange(1) & sub_table(:,6) <= ageRange(2) & sub_table(:,4) == kidID,[1 5]);
    end
end