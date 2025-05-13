%%%
% Author: Jingwen Pang
% Last modified: 5/13/2025
% 
% !! This function will generate new variables in our system, don't use it
% unless you get approval from Chen.
%
% This function splits base cevent data based on conditional cevent data.
% The classification is determined as follows:
% 1. Check the onset of each instance in base cevent.
% 2. If a corresponding instance of conditional cevent occurs at the same time with the same category value, 
%    classify the base cevent instance as "cond_cevent-led."
% 3. If no such instance occurs, check whether condtional cevent appears *during* the duration of base cevent 
%    with the same category value. If it does, classify the base cevent instance as "cond_cevent-follow."
% 4. If no instance of conditional cevent occurs during base cevent, classify it as "no-cond_cevent."
%
%   case 1: cond_cevent led
%             [-----base_cevent----]
%       [----cond_cevent----]
%   case 2: cond_cevent follow
%       [----base_cevent----]
%             [-----cond_cevent----]
%   case 3: no cond_cevent
%       [----base_cevent----]
%                                    [--cond_cevent--]
% 
%   input parameters: 
%       - subexpIDs
%       - base_cevent
%       - cond_cevent
%       - cond_cevent_name
%   output:
%       [base_cevent]_[cond_cevent-led]_[agent]
%       [base_cevent]_[cond_cevent-led-lag]_[agent]
%       [base_cevent]_[cond_cevent-follow]_[agent]
%       [base_cevent]_[cond_cevent-follow]_[agent]
%       [base_cevent]_[no-cond_cevent]_[agent]
%   
%
%   e.g
%       base_cevent: 'cevent_speech_naming_local-id'
%       cond_cevent_name: "child-roi" 
%       output:
%       - cevent_speech_naming_local-id_child-roi-led
%       - cevent_speech_naming_local-id_child-roi-led-lag
%       - cevent_speech_naming_local-id_child-roi-follow
%       - cevent_speech_naming_local-id_child-roi-follow-lag
%       - cevent_speech_naming_local-id_no-child-roi
% 
%%%

function demo_split_cevent_at_onset_by_cevent(option)

switch option
    case 1
        subexpIDs = 35101;
        base_cevent = 'cevent_speech_naming_local-id';
        cond_cevent = 'cevent_eye_roi_child';
        cond_cevent_name = 'child-roi';
        split_cevent_at_onset_by_cevent(subexpIDs,base_cevent,cond_cevent,cond_cevent_name)
end