% Author: Ruchi Shah
function get_utterance_gap_dist(sub_expID, output_filename, args)
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
     if isfield(args, 'keywords')
         keywords = args.keywords;
     else 
         keywords = {'*'};
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

    % access speech trans file of each subject
    mat = zeros(length(subIDs), height(defined_bins), 'double');
    for i = 1:numel(subIDs)
        sub_dir = get_subject_dir(subIDs(i));
        % check if this experiment has speech transcription data
        str = strsplit(sub_dir, "_");
        file_n = str(end);
        f = strcat(sub_dir,"/speech_transcription_p/", "speech_", file_n, ".txt");
        if ~isfile(f)
            disp("ERROR: file does not exist or this experiment does not have speech data.")
            continue;
        end 
        fid = fopen(f, 'r');
        data = textscan(fid, '%s', 'Delimiter', '\n');
        data = strtrim(data{1});
        % get the transcript with only the utterances containing the
        % keywords
        data = keyword_utterances(data, keywords);
        subTimes = {};
        % get times of each utterance
        for j = 1:length(data)
            line = strtrim(data{j});
            splitcells = regexp(line,'\s','split','once');
            if ~isempty(splitcells{1})
                splitcells2 = regexp(splitcells{2},'\s','split','once');
                t1 =  splitcells{1};
                t2 = splitcells2{1};
                times = {t1, t2};
                subTimes{end+1} = times;
            end 
        end 

        for j = 1:(length(subTimes)-1)
            time_e = subTimes{j};
            time_s = subTimes{j+1};
            time_off = str2double(time_e{2});  % end time of current utterance
            time_on_next = str2double(time_s{1});  % start time of next utterance
            utter_gap = time_on_next - time_off;
            col = 1;
            for k = 1:height(defined_bins)
                % get bin utter_gap belongs to if any at all
                if utter_gap > defined_bins(k,1) && utter_gap <= defined_bins(k,2)
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
   
    fclose('all');
end
