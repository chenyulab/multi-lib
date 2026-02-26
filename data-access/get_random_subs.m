% sample n subjects contaning the target variables from expID
%
% subs = get_random_subs(351,4,{})
% subs = get_random_subs(351,4,{'cevent_eye_roi_child','cevent_eye_roi_parent'})
%
function randsubs = get_random_subs(expID, n, var_list)
    subs = cIDs(expID);
    mask = arrayfun(@(x) has_all_variables(x,var_list),subs);
    
    subsWithVars = subs(mask);
    
    randIdx = randi(numel(subsWithVars),n,1);
    randsubs = subsWithVars(randIdx);
end