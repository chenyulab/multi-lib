function rez = get_variable_by_trial_stitch(subid, var)
%   Concatenates trials together for variable by removing inactive trial time
%   For example, if trial one 30 257.1, trial two 369.1333 636.9333. Trial one times will stay the same, but trial
%   two will start at 257.1 and all its values will be adjusted accordingly.

    if has_variable(subid,var)
        rez = get_variable_by_trial(subid,var);
        tt = get_variable(subid,'cevent_trials');

        for r = 1:numel(rez)
            % stitching logic
            if r == 1
                trial1_end = tt(r,2);
            else
                trial2_start = tt(r,1);
                skip = trial2_start - trial1_end;

                rez{r}(:,1:2) = rez{r}(:,1:2) - skip;
                trial1_end = tt(r,2)-skip;
            end
            rez{r}(:,end+1) = tt(r,3);
        end
        rez = vertcat(rez{:});
    else
        rez = [];
    end
end