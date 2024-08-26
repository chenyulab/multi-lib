%%%
% Author: Jane Yang
% Last Modified: 9/06/2023
% This function creates expanded version of an input cevent variable.
%
% Input: subexpIDs    - a list of subIDs or expIDs
%        base_cev     - name of the base cevent variable
%        expanded_var - name of the expanded version of base cevent var
% 
% Example function call: make_cevent_expanded([12],'cevent_speech_naming_local-id','cevent_speech_naming_local-id_expanded')
%%%

function make_cevent_expanded(subexpIDs, base_cev, expanded_var)
    % hard-coded to reinforce a gap between two consecutive expanded
    % instances
    gap = 0.1;

    % expand subexpIDs to get a list of subjects
    full_sub_list = cIDs(subexpIDs);

    % iterate thru subject list and create expanded naming var
    for i = 1:numel(full_sub_list)
        % make a copy of base var
        cevent_expanded = get_variable_by_trial(full_sub_list(i),base_cev);
        cevent_trials = get_variable_by_trial(full_sub_list(i),'cevent_trials');

        if ~isempty(cevent_expanded)
            % iterate thru each trial
            for t = 1:length(cevent_trials)
                for k = 1:size(cevent_expanded{t},1)
                    if k < size(cevent_expanded{t},1)
                        cevent_expanded{t}(k,2) = cevent_expanded{t}(k+1,1) - gap;
                    else
                        cevent_expanded{t}(k,2) = cevent_trials{t}(end,2);
                    end
                end
                % % create a list of expanded timestamps based on base var's onset
                % unique_expanded_timestamps = repmat(unique(cevent_expanded{t}(:,1)),1,2);
                % 
                % for k = 1:size(unique_expanded_timestamps,1)
                %     if k < size(unique_expanded_timestamps,1)
                %         unique_expanded_timestamps(k,2) = unique_expanded_timestamps(k+1,1) - gap;
                %     else
                %         unique_expanded_timestamps(k,2) = cevent_trials{t}(end,2);
                %     end
                % end
                % 
                % onset_list = cevent_expanded{t}(:,1);
                % 
                % % iterate through base var instances
                % for j = 1:numel(onset_list)
                %     cevent_expanded{t}(j,2) = unique_expanded_timestamps{t}(unique_expanded_timestamps{t}(:,1)==onset_list(j),2);
                % end
            end

            cevent_expanded = vertcat(cevent_expanded{:});

            % save variables
            record_additional_variable(full_sub_list(i),expanded_var,cevent_expanded);
        end
    end
end