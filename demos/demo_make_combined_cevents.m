% The function creates up to five cevent variables by comparing
% two aligned cevent variables given as inputs.
%
% The possible output variables are:
%
% 1. Same
%    Times when both cevents are active and have the same category.
%    The output category is their shared category.
%
% 2. Different 1
%    Times when both cevents are active but have different categories.
%    The output category is taken from cevent1.
%
% 3. Different 2
%    Times when both cevents are active but have different categories.
%    The output category is taken from cevent2.
%
% 4. Only 1
%    Times when cevent1 is active and cevent2 is inactive.
%    The output category is taken from cevent1.
%
% 5. Only 2
%    Times when cevent2 is active and cevent1 is inactive.
%    The output category is taken from cevent2.
%
% INPUTS
% subexpID
%    Experiment ID, subject ID, or vector of IDs, such as:
%    351 or [35101, 35102]
%
% cevent1
%    Name of the first cevent variable, such as:
%    'cevent_eye_roi_child'
%
% cevent2
%    Name of the second cevent variable, such as:
%    'cevent_speech_naming_local-id'
%
% cevent_naming_matrix
%    Five-element vector specifying the names of the output variables
%    in the order listed above. Use "" for any output that should not be
%    generated.
%
%    Example:
%    [
%       "cevent_eye_roi_with_naming_same_child", ...
%       "", ...
%       "", ...
%       "cevent_eye_roi_wo_naming_child", ...
%       "cevent_naming_wo_eye_roi_child"
%   ]
function demo_make_combined_cevents(option)
    switch option
        case 1
            % Regular usage of generating all types of combined variables from two regular variables
            subexpID = 12;
            cevent1 = 'cevent_speech_naming_local-id';
            cevent2 = 'cevent_eye_roi_sustained-3s_child';
            cevent_naming_matrix = [
                "cevent_naming-with-SA-same_parent-child", ... % same category
                "cevent_naming-with-SA-diff_parent-child", ... % category from naming
                "cevent_SA-with-naming-diff_parent-child" ... % category from SA
                "cevent_naming-wo-SA_parent_child", ... % category from naming
                "cevent_SA-wo-naming_parent_child" % category from SA
            ];
            make_combined_cevents(subexpID,cevent1,cevent2,cevent_naming_matrix);
        case 2
            % Generate only selected combined variables. This case only generates 3 of the 5 varaibles
            subexpID =12;
            cevent1 = 'cevent_speech_naming_local-id';
            cevent2 = 'cevent_eye_roi_sustained-3s_child';
            cevent_naming_matrix = [
                "cevent_naming-with-SA-same_parent-child", ...
                "", ...
                "", ...
                "cevent_naming-wo-SA_parent_child", ...
                "cevent_SA-wo-naming_parent_child"
            ];
            make_combined_cevents(subexpID, cevent1, cevent2, cevent_naming_matrix);
        case 3
            % Make combined variables from a combined variable and a regular variable
            subexpID = 12;
            cevent1 = 'cevent_naming-with-SA-same_parent-child';
            cevent2 = 'cevent_eye_joint-attend_both';
            cevent_naming_matrix = [
                % names do not need to be in this format for secondly derived variable if more understandable name
                % fits task, this is an example of what was used previously.
                "cevent_naming-with-SA-same-with-JA-same_parent-child", ...
                "cevent_naming-with-SA-same-with-JA-diff_parent-child", ...
                "cevent_JA-with-naming-with-SA-same-diff_parent-child", ...
                "cevent_naming-with-SA-same-wo-JA_parent-child", ...
                "cevent_JA-wo-naming-with-SA-same_parent-child"
            ];
            make_combined_cevents(subexpID, cevent1, cevent2, cevent_naming_matrix);

    end
end