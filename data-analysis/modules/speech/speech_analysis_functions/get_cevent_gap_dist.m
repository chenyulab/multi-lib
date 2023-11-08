% Author: Ruchi Shah
function get_cevent_gap_dist(sub_expID, var_name, output_filename, args)
     if ~exist('args', 'var') || isempty(args)
         args = struct();
     end
     if ~isfield(args, 'bins_matrix')
         defined_bins = [0 0.5;
             0.5 1;
             1 1.5;
             1.5 2;
             2 realmax('double')];
         disp('Set bins to default.');
     else
         defined_bins = args.bins_matrix;
     end

     % find utterances that contain any of the keywords
     % calc gaps between these keywords
     if isfield(args, 'rois')
         rois = args.rois;
     else 
         rois = {-1};
     end

% Variables
    subIDs = cIDs(sub_expID);
    if isempty(subIDs)
         disp("ERROR: experiment does not exist or there are no subjects in this experiment.")
        return;
    end
    sub_col = subIDs;
    bin_names = {};
    for i = 1:height(defined_bins)
        bin_names{end+1} = strcat('(', num2str(defined_bins(i,1)), '-', num2str(defined_bins(i,2)), ')');
    end
    disp(bin_names)

    % access variable of interest for each subject
    mat = zeros(length(subIDs), height(defined_bins), 'double');
    for i = 1:numel(subIDs)
        try
            sub_var_data = get_variable(subIDs(i), var_name);
        catch
            disp("ERROR: subject does not have variable.")
        end
        % get the transcript with only the utterances containing the
        % keywords
        data = key_roi_data(sub_var_data, rois);
        subTimes = {};
        % get times of each roi
        for j = 1:height(data)
            t = data(j, :);
            t1 = t(1);
            t2 = t(2);
            times = [t1,t2];
            subTimes{end+1} = times;
        end 

        for j = 1:(length(subTimes) - 1)
            time_e = subTimes{j};
            time_s = subTimes{j+1};
            time_off = time_e(2);  % end time of current utterance
            time_on_next = time_s(1);  % start time of next utterance
           gap = time_on_next - time_off;
            col = 1;
            for k = 1:height(defined_bins)
                % get bin gap belongs to if any at all
                if gap > defined_bins(k,1) && gap <= defined_bins(k,2)
                    mat(i, col) = mat(i, col) + 1;
                    break;
                end 
                col = col + 1;
            end
        end
    end

    % output table creation
    mat = horzcat(sub_col, mat);
    T = array2table(mat);
    vars = horzcat({'subID'}, bin_names);
    T.Properties.VariableNames = vars;
    writetable(T, output_filename)
end
