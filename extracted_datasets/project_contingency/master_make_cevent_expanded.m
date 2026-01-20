%%%
% Author: Jane Yang
% Last Modified: 10/06/2023
% This master function creates the expanded naming variable for all subjects
% under input experiments.
%8
% Input: expIDs    - a list of experiments
% 
% Example function call: master_make_speech_naming_expanded([12 15 27 49 58 71 72 73 74 75 96 351 353])
%%%

function master_make_cevent_expanded(expIDs,base_varname,output_varname)
    % find subjects that has the naming and trial variable
    subs = find_subjects({'cevent_trials',base_varname},expIDs);
    make_cevent_expanded(subs,base_varname,output_varname); 
end