%%%
% Author: Jane Yang
% Last modifier: 2/29/2024 (Leap Day!)
% 
% Description: This demo function showcases how to use list_home2_subjects()
% function to get a list of subjects that fall into the query category.
% Please refer to documentations in the list_home2_subjects() header.
%
% This function ONLY targets experiment 350+ (home2 experiments).
%
% Input:        Name        Description
%               option      the index of demo case one would like to try
%
% Output: an array of subject IDs
%%%
% sub_list = demo_list_home2_subjects(1)
function sub_list = demo_list_home2_subjects(option)
    switch option
        case 1
            % list all subjects within a certain age range
            expIDs = 351;
            ageRange = [12 24]; % 12 to 24 months old - default at 0-40 months old

            sub_list = list_home2_subjects(expIDs,'ageRange',ageRange);
        case 2
            % list all kids within the age range from both exp351&353
            expIDs = [351 353];
            ageRange = [12 24]; % 12 to 24 months old - default at 0-40 months old

            sub_list = list_home2_subjects(expIDs,'ageRange',ageRange);
        case 3
            % list all second visits subjects
            expIDs = [351 353];
            visitIDs = 2; % default to [1 2 3]

            sub_list = list_home2_subjects(expIDs,'visitIDs',visitIDs);
        case 4
            % list all subIDs for a kid
            expIDs = [351 353];
            kidIDs = 10041; % default to 0 as a flag

            sub_list = list_home2_subjects(expIDs,'kidIDs',kidIDs);
            % outputs Nx2 array where the first column is subID and second
            % column is visitID
    end
end