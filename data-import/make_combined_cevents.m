function make_combined_cevents(subexpID, cevent1, cevent2, cevent_naming_matrix)
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
%       "cevent_eye_roi_naming_same_child", ...
%       "", ...
%       "", ...
%       "cevent_eye_roi_no_naming_child", ...
%       "cevent_naming_no_eye_roi_child"
%   ]

    subs = cIDs(subexpID);
    for s = 1:numel(subs)
        exp_id = sub2exp(subs(s));
        if all(cellfun(@(a) has_variable(subs(s), a), {cevent1, cevent2}))
            gt = get_variable(subs(s), 'cstream_trials');
            event1 = get_variable(subs(s),cevent1);
            event2 = get_variable(subs(s),cevent2);
            var1 = cevent2cstream(event1,30.0,1/30,0);
            var2 = cevent2cstream(event2,30.0,1/30,0);
            [gt,var1,var2] = align_cstreams(gt,var1,var2);

            % Store every category separately so categories with the same
            % onset and offset are not removed by cevent2cstream.
            categories = unique([event1(:,3); event2(:,3)]);
            categories(categories == 0) = [];
            var1_categories = make_category_cstreams(event1,var1(:,1),categories);
            var2_categories = make_category_cstreams(event2,var2(:,1),categories);
            var1_active = any(var1_categories,2);
            var2_active = any(var2_categories,2);

            %% var1 and var2 same variables
            if ~(cevent_naming_matrix{1} == "")
                same_categories = var1_categories & var2_categories;
                cev_both_vars = category_cstreams2cevent( ...
                    same_categories,var1(:,1),categories);
                record_additional_variable(subs(s), cevent_naming_matrix{1}, cev_both_vars);
            end

            %% var1 diff and var2 diff variables
            if ~(cevent_naming_matrix{2} == "") || ~(cevent_naming_matrix{3} == "")
                % A category is different when the other variable is active
                % but does not contain that category.
                var1_diff = var1_categories & var2_active & ~var2_categories;
                var2_diff = var2_categories & var1_active & ~var1_categories;
                cev_var1_bidiff = category_cstreams2cevent( ...
                    var1_diff,var1(:,1),categories);
                cev_var2_bidiff = category_cstreams2cevent( ...
                    var2_diff,var2(:,1),categories);
                if ~(cevent_naming_matrix{2} == "")
                    record_additional_variable(subs(s), cevent_naming_matrix{2}, cev_var1_bidiff);
                end
                if ~(cevent_naming_matrix{3} == "")
                    record_additional_variable(subs(s), cevent_naming_matrix{3}, cev_var2_bidiff);
                end
            end

            %% var1 only and var2 only variables
            if ~(cevent_naming_matrix{4} == "") || ~(cevent_naming_matrix{5} == "")
                var1_only = var1_categories & ~var2_active;
                var2_only = var2_categories & ~var1_active;
                cev_var1_only = category_cstreams2cevent( ...
                    var1_only,var1(:,1),categories);
                cev_var2_only = category_cstreams2cevent( ...
                    var2_only,var2(:,1),categories);
                if ~(cevent_naming_matrix{4} == "")
                    record_additional_variable(subs(s), cevent_naming_matrix{4}, cev_var1_only);
                end
                if ~(cevent_naming_matrix{5} == "")
                    record_additional_variable(subs(s), cevent_naming_matrix{5}, cev_var2_only);
                end
            end
        end
    end
end


function category_cstreams = make_category_cstreams(events,times,categories)
% Make one binary cstream column for every category.

    category_cstreams = false(numel(times),numel(categories));

    for i = 1:size(events,1)
        category_column = find(categories == events(i,3),1);
        active = times >= events(i,1) & times < events(i,2);
        category_cstreams(active,category_column) = true;
    end
end


function cevents = category_cstreams2cevent(category_cstreams,times,categories)
% Convert the separate category columns back into one cevent variable.

    cevents = zeros(0,3);

    for i = 1:numel(categories)
        category_stream = [times zeros(numel(times),1)];
        category_stream(category_cstreams(:,i),2) = categories(i);
        category_cevents = cstream2cevent(category_stream);
        cevents = [cevents; category_cevents]; %#ok<AGROW>
    end

    if ~isempty(cevents)
        cevents = sortrows(cevents,[1 2 3]);
    end
end
