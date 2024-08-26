%%%
% Original author: Ruchi Shah
% Modifier: Jane Yang
% Last Modified: 10/05/2023
% This function generates intermediate data representations for the input
% experiment and extract multi measure output file.
%%%


function reformat_multipathways(expID, var_list, input_filename)
    % hard-coded for indexing extract_multi_measure files
    ceye_target = 8;
    peye_target = 11;
    cinhand_target = 14;
    pinhand_target = 17;

    T = csvread(input_filename,4);

    % determine type of hand data
    if ~any(strcmp(var_list, 'cevent_gesture_parent'))
        child_hand = 'cevent_inhand_child_prop_target';
        parent_hand = 'cevent_inhand_parent_prop_target';
    else 
        child_hand = 'cevent_gesture_child_prop_target';
        parent_hand = 'cevent_gesture_parent_prop_target';
    end 

    sub_list = cIDs(expID);

    for i = 1:length(sub_list)
        event{i} = [];
        behavior{i} = [];
        rows = T(T(:,1) == sub_list(i),:);
        event{i} = rows(:,1:7);
        % behavior coding order: ceye target, peye target, cinhand target,
        % pinhand target, ceye face, peye face, ceye other, peye other,
        % cinhand other, pinhand other
        behavior{i} = rows(:,[ceye_target,peye_target,cinhand_target,pinhand_target,ceye_target+2,peye_target+2,ceye_target+1,peye_target+1,cinhand_target+1,pinhand_target+1]);
    end

    save([input_filename(1:end-4) '.mat'], "event","behavior");
end