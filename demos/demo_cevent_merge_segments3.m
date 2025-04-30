%Overview
%demo function for cevent_merge_segments3(cevent, maxGap, cat_list,args)
% cevent_merge_segments3 merges intervals that have a small gap between
% 
% 
% it takes a list of cevent/event instances in a cevent variable and returns a new
% list by merging those instances 1) temporally next to each other (if is_other_between specified, events do not have to be immediately after one another)
% 2) with a small gap in between and 3) share the same category if it is a cevent.
% 
% Input:
%   cevent: a cevent/event variable
%   maxGap: in seconds, the length of the longest gap to merge across
%   cat_list :  list of categories desired to merge (can be a sub list of
%               categories in data or a list containing all categories)
%       - ex. [1,16]
%               - this means that for all categories in the data, the
%               function will only merge cevents with 1 or 16 as the
%               category
%       input:  72.63	75.00	1
%               75.90	77.23	1
%               78.10	83.76	16
%               84.06	86.46	5
%               86.63	87.30	14
%               88.73	89.46	16
%               89.53	89.73	16
% 
%      output:  72.63	77.23	1
%               78.10	83.76	16
%               84.06	86.46	5
%               86.63	87.30	14
%               88.73	89.73	16
%
% Optional Arguments 
%   args.is_other_between: specifies whether you want to merge across other intervening category 
%                          instances if the gap between events from the same category is <= maxGap
%       args.is_other_between = 1 if yes, 0 if no
%       ex. if args.is_other_between = 1 and maxGap = 2
%       input:  245.0500  246.7000   28.0000
%               246.9600  247.7300    2.0000
%               248.0600  249.6800   28.0000
% 
%       output: 245.0500 249.6800  28.0000
%               246.9600  247.7300 2.0000
%       - defaults to 0
%       NOTE: for cevent data that has overlapping onset/offset values
%       (like cevent_inhand) overlapping cevents will be merged regardless
%       of whether is_other_between is 0
%    args.max_other_duration: can be specified in cases where args.is_other_between == 1, it specifies a threshold (in secs) that intervening cevents
%                            must be shorter than in order to be merged over 
%        - if args.max_other_duration  is not specified, maxGap is the only
%        criteria used for merging over intervening instances
% 
% 
% Output:
%   A new cevent/event variable by merging instances with small gaps in between.
function[cevent_out] = demo_cevent_merge_segments3(option)


switch option

    case 1
        % want to merge across categories only temporally next to each other

        cevent = get_variable_by_trial_cat(7002, 'cevent_eye_roi_child');

        maxGap = 3; %3 seconds is the maximum two events can be merged over
        cat_list = [1 2]; %only merge categories 1 and 2
        args.is_other_between = 0;
        cevent_out = cevent_merge_segments3(cevent, maxGap, cat_list, args);
        
    case 2 
        % want to merge across categories only temporally next to each other

        cevent = get_variable_by_trial_cat(7002, 'cevent_eye_roi_child');

        maxGap = 3; %3 seconds is the maximum two events can be merged over
        cat_list = [1 3]; %only merge categories 1 and 3
        args.is_other_between = 0;
      
        cevent_out = cevent_merge_segments3(cevent, maxGap, cat_list, args);

    case 3 
        % want to merge instances from category 1 and 2 only
        % want to merge across other intervening categories if the gap is small enough,

        cevent = get_variable_by_trial_cat(7002, 'cevent_eye_roi_child');

        maxGap = 3; %3 seconds is the maximum two events can be merged over
        cat_list = [1 2];
        args.is_other_between = 1;
        %args.max_other_duration  is not specified,
        cevent_out = cevent_merge_segments3(cevent, maxGap, cat_list,args);    
    
    case 4
        % want to merge across other categories if the gap is small enough,

        cevent = get_variable_by_trial_cat(7002, 'cevent_eye_roi_child');

        maxGap = 3; %3 seconds is the maximum two events can be merged over
        cat_list = [1 2];
        args.is_other_between = 1;
        cevent_out = cevent_merge_segments3(cevent, maxGap, cat_list,args);

    case 5 
        % want to merge cevents not temporally next to each other that have a gap less than maxGap, but only
        % if intervening categories have a duration less than
        % max_other_duration 

        cevent = get_variable_by_trial_cat(7002, 'cevent_eye_roi_child');

        maxGap = 6; % 6 seconds is the maximum gap two cevents can be merged over
        cat_list = [1 3]; % only merge categories 1 and 3
        args.is_other_between = 1;
        args.max_other_duration  = 2; % 2 seconds is the max duration an intervening cevent can have and still be merged over
        cevent_out = cevent_merge_segments3(cevent, maxGap, cat_list,args); 
           
    case 6
        % merge data that has overlapping onsets and offsets (like inhand data)
        
        %regardless of whether is_other_between is specified, events that
        %overlap that may not be next to each other in the data will be
        %merged 

        %is_other_between is specified, so will also merge over intervening
        %events if they are less than maxGap

        cevent = get_variable_by_trial_cat(1207, 'cevent_inhand_child');
        maxGap = 3; %3 seconds is the maximum two events can be merged over
        cat_list = [1:24];
        args.is_other_between = 1;
        cevent_out = cevent_merge_segments3(cevent, maxGap, cat_list,args);


    case 7 
        %merge data that has overlapping cevents (like inhand data)

        %is_other_between is specified and max_other_duration  is specified
        %so events will only merge if the gap is < maxGap AND there are either no 
        % intervening events or intervening events last for <  1 second
        % (max_other_duration)

        %events that overlap will always be merged even if intervening
        %event duration > max_other_duration 
        cevent = get_variable_by_trial_cat(35102, 'cevent_inhand_child');

        maxGap = 3; % 3 seconds is the maximum two events can be merged over
        cat_list = [1:27];
        args.is_other_between = 1;
        args.max_other_duration  = 1;

        cevent_out = cevent_merge_segments3(cevent, maxGap, cat_list,args);
     
end
end
