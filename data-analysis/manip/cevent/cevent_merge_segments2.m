function [cevent_out] = cevent_merge_segments2(cevent, maxGap, cat_list,is_other_between,include_non_merged )
% cevent_merge_segments merges intervals that have a small gap between them
% 
% it takes a list of cevent/event instances in a cevent variable and return a new
% list by merging those instances 1) temproally next to each other 2) with
% a small gap in between and 3) share the same category if it is a cevent.
% 
% Input:
%   cevent: a cevent/event variable
%   maxGap: in seconds, the length of the longest gap to merge
%   cat_list : variables to merge
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
%    include_non_merged : include the non-merged categories (categories not in cat_list) in output
%                         1 if yes (default)
%                         0 if no
%
% 
% Output:
%   A new cevent/event variable by merging instances with small gaps in between.

    if ~exist('is_other_between','var')
        is_other_between = 0;  

    end
    if ~exist('include_non_merged','var')
        include_non_merged = 1;  

    end

    if is_other_between ==1
        for c = 1 : length(cat_list)
            target = cat_list(c);
        
            % find target events
            idx = cevent(:,3) == target;
            cevent_target = cevent(idx,:);
        
            n = 1;
            res{c}(n,:) = cevent_target(1,:);
        
            for i = 2 : size(cevent_target,1)
        
                if (cevent_target(i,1) - cevent_target(i-1,2) <= maxGap) && (cevent_target(i-1,3) == cevent_target(i,3))
                    res{c}(n,2) = cevent_target(i,2);
                else
                    n = n + 1;
                    res{c}(n,:) = cevent_target(i,:);
                end
            end
        end
        cevent_out=sortrows(vertcat(res{:}));
         
    else
        idx = find(ismember(cevent(:,3),cat_list));
        cevent_target = cevent(idx,:);
        n = 1;
        res(n,:) = cevent_target(1,:);
        
        for i = 2 : size(cevent_target,1)
    
            if (cevent_target(i,1) - cevent_target(i-1,2) <= maxGap) && (cevent_target(i-1,3) == cevent_target(i,3))
                res(n,2) = cevent_target(i,2);
            else
                n = n + 1;
                res(n,:) = cevent_target(i,:);
            end
        end
        cevent_out=sortrows(res);
    end
    
    if include_non_merged ==1 %include the nonmerged segments in the output
        idx = ~ismember(cevent(:,3),cat_list);
        non_merged = cevent(idx,:);

        cevent_out = sortrows(vertcat(cevent_out, non_merged));

    end



end