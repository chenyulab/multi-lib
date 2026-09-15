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
            var1 = cevent2cstream(get_variable(subs(s),cevent1),30.0,1/30,0);
            var2 = cevent2cstream(get_variable(subs(s),cevent2),30.0,1/30,0);
            [gt,var1,var2] = align_cstreams(gt,var1,var2);

            %% var1 and var2 same variables
            if ~(cevent_naming_matrix{1} == "")
                both = [var1(:,2) var2(:,2)];
                log = both(:,1) ~= both(:,2);
                both(log,:) = 0;
                both_vars = [var1(:,1) both(:,1)];
                cev_both_vars = cstream2cevent(both_vars);
                record_additional_variable(subs(s), cevent_naming_matrix{1}, cev_both_vars);
            end

            %% var1 diff and var2 diff variables
            if ~(cevent_naming_matrix{2} == "") || ~(cevent_naming_matrix{3} == "")
                vars_diff = (var2(:,2) ~= 0 & var1(:,2) ~= 0) & (var2(:,2) ~= var1(:,2));
                var1_diff = var1;
                var2_diff = var2;
                var1_diff(~vars_diff,2) = 0;
                var2_diff(~vars_diff,2) = 0;
                cev_var1_bidiff = cstream2cevent(var1_diff);
                cev_var2_bidiff = cstream2cevent(var2_diff);
                if ~(cevent_naming_matrix{2} == "")
                    record_additional_variable(subs(s), cevent_naming_matrix{2}, cev_var1_bidiff);
                end
                if ~(cevent_naming_matrix{3} == "")
                    record_additional_variable(subs(s), cevent_naming_matrix{3}, cev_var2_bidiff);
                end
            end

            %% var1 only and var2 only variables
            if ~(cevent_naming_matrix{4} == "") || ~(cevent_naming_matrix{5} == "")
                one_only = var2(:,2) == 0;
                two_only = var1(:,2) == 0;
                var1_only = var1;
                var2_only = var2;
                var1_only(~one_only,2) = 0;
                var2_only(~two_only,2) = 0;
                cev_var1_only = cstream2cevent(var1_only);
                cev_var2_only = cstream2cevent(var2_only);
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

