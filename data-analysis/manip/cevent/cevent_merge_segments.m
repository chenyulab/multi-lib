function [cevent_out] = cevent_merge_segments(cevent, maxGap, cat_list,args)
% cevent_merge_segments merges intervals that have a small gap between them
% 
% it takes a list of cevent/event instances in a cevent variable and return a new
% list by merging those instances 1) temporally next to each other 2) with
% a small gap in between and 3) share the same category if it is a cevent.
% 
% Input:
%   cevent: a cevent/event variable
%   maxGap: in seconds, the length of the longest gap to merge
%   cat_list : variables to merge
%           - ex. [1 2 3 4]
%               - this means that for all categories in the data, the
%               function will only merge cevents with these categories
%   in_between: specifies whether you want to merge across other
%   category instances if the gap is small enough
%       merge_in_between = 1 if yes, 0 if no
%       ex.
%       input:  245.0500  246.7000   28.0000
%               256.9600  257.7300    2.0000
%               269.0600  270.6800   28.0000
% 
%       output: 245.0500 270.6800   28.0000
%               256.9600  257.7300    2.0000
%       - defaults to 0

%
% 
% Output:
%   A new cevent/event variable by merging instances with small gaps in between.
    if ~exist('args', 'var') || isempty(args)
        args = struct([]);
    end

    if isfield(args, 'is_other_between')
        is_other_between = args.is_other_between;
    else
        is_other_between = 0;  
    end
    if isfield(args, 'max_other_duration')
        max_other_duration  = args.max_other_duration ;
    else
        max_other_duration  = false;  
    end  


    if is_other_between ==1
        for c = 1 : length(cat_list)
            target = cat_list(c);
     
            % find target events
            idx_log = cevent(:,3) == target;
            idx = find(idx_log ==1); 

            cevent_target = cevent(idx_log,:);


            if cevent_target

                n = 1;
                out{c}(n,:) = cevent_target(1,:);


                for i = 2 : size(cevent_target,1)
                    if (cevent_target(i,1) - out{c}(n,2) <= maxGap)
                        if max_other_duration 
                            %get the real indices of the two events 
                            curr_idx = idx(i-1);
                            next_idx = idx(i);
                            rng = curr_idx:next_idx;
    
                            %get the real indices of all events that happen in
                            %between the closest two cevents with the same
                            %category
                            in_btw_idx = rng(2:end-1);
     
                            btw_event_dur = 0;
                            %get the duration of all the intervening cevents 
                          
                            if in_btw_idx
                                for j = 1:numel(in_btw_idx)
                                    curr_btw_idx = in_btw_idx(j);
                                    btw_event_dur = btw_event_dur + (cevent(curr_btw_idx,2) - cevent(curr_btw_idx,1));
                                end
                            end
                            %check if the cevents are temporally next to each
                            %other or if not, check that the duration of
                            %intervening cevents is below the between threshold
                            if(isempty(in_btw_idx) || btw_event_dur <= max_other_duration  || cevent_target(i,1)<out{c}(n,2))
                                if cevent_target(i,2) >= out{c}(n,2)
                                    out{c}(n,2) = cevent_target(i,2);
                                end
                            else
                                n = n + 1;
                                out{c}(n,:) = cevent_target(i,:);
                            end
                        
                        else %if between threshold not specified, merge as long as gap < maxGap
                            if cevent_target(i,2) >= out{c}(n,2)
                                    out{c}(n,2) = cevent_target(i,2);
                            end
                        end

                    else
                        n = n + 1;
                        out{c}(n,:) = cevent_target(i,:);
                    end
                end
            end
        end
        cevent_out=sortrows(vertcat(out{:}));

         
    else
        n = 1;
        idx = find(ismember(cevent(:,3),cat_list),1, 'first');
        res(n,:) = cevent(idx,:);
        
        for i = idx+1 : size(cevent,1)
            if ismember(cevent(i,3), cat_list)
                if (cevent(i-1,3) == cevent(i,3)) && (cevent(i,1) - res(n,2)  <= maxGap)
                        if cevent(i,2) >=  res(n,2) 
                            res(n,2) = cevent(i,2);
                        end
                else
                    n = n + 1;
                    res(n,:) = cevent(i,:);
                end
            end
        end
        
        %for events with overlapping onsets and offsets, merge overlapping
        %events with the same category (even if it is across another
        %category
        for c = 1 : length(cat_list)
            target = cat_list(c);
            
            idx = res(:,3) == target;
            sub_cat_res = res(idx,:);     
            n = 1;
            if sub_cat_res
                cevent_temp{c}(n,:) = sub_cat_res(1,:);
                for i = 2:height(sub_cat_res)
                    if (sub_cat_res(i,1) <= cevent_temp{c}(n,2))
                        if sub_cat_res(i,2) >=  cevent_temp{c}(n,2) 
                            cevent_temp{c}(n,2) = sub_cat_res(i,2);
                        end
                    else
                        n = n+1;
                        cevent_temp{c}(n,:) = sub_cat_res(i,:);
                    end
                end
            end
        end
        cevent_out=sortrows(vertcat(cevent_temp{:}));
    end

    idx = ~ismember(cevent(:,3),cat_list);
    non_merged = cevent(idx,:);

    cevent_out = sortrows(vertcat(cevent_out, non_merged));



end


