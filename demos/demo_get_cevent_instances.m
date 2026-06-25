function demo_get_cevent_instances(option)
%% Summary
% 
% This function take all instances from a cevent variable and generates an excel file with this format:
% subID      expID      onset      offset      category       trial      instanceID
%  --          --         --         --          --             --          --
% This file will have the same structure as the output from extract_multi_measures

%% Required Arguments
%   cevent_variable : name of cevent variable, e.g.
%                     "cevent_speech_naming_local-id"
%
%   subexpIDs       : experiment ID, subject ID, or list of IDs.
%                     Examples:
%                         351
%                         35101
%                         [35101 35102 35103]
%
%   output_file     : .csv file
%

%% OUTPUT:
%  csv file          : original-format cell array with 4 header rows
%                               This includes the cevent name
%
% Output columns:
%   subID, expID, onset, offset, category, trialsID, instanceID

switch option 
    
    case 1 
        % Get events from cevent_eye_roi_child for a single subject
        output_file = "Z:\James\ImageVectorMeasures\get_cevent_instances_DEMOS\case01.csv";
        cevent_variable = "cevent_eye_roi_child";
        subexpIDs = 1501;

        get_cevent_instances(cevent_variable, subexpIDs, output_file);


    case 2
        % Get events from cevent_speech_naming_local-id for a few subjects 
        output_file = "Z:\James\ImageVectorMeasures\get_cevent_instances_DEMOS\case02.csv";
        cevent_variable = "cevent_speech_naming_local-id";
        subexpIDs = [35101 35107 35131];

        get_cevent_instances(cevent_variable, subexpIDs, output_file);

    case 3
        % Get events from cevent_inhand_child for all of 310
        output_file = "Z:\James\ImageVectorMeasures\get_cevent_instances_DEMOS\case03.csv";
        cevent_variable = "cevent_inhand_child";
        subexpIDs = 310;

        get_cevent_instances(cevent_variable, subexpIDs, output_file);
end
