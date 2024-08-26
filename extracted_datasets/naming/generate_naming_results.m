function generate_naming_results(expIDs, num_objs, input_file_name, dep_cevent, output_dir,output_file_name, args)

% {
args.dep_cevent_list
args.dep_dep_type_list
args.num_bin
% }


    if ~exist('args', 'var') || isempty(args)
         args = struct([]);
    end

    if ~isfield(args, 'dep_cevent_list')
        dep_cevent_list = {'cevent_eye_roi_child','cevent_eye_roi_parent','cevent_inhand_child','cevent_inhand_parent'};
    else
        dep_cevent_list = args.dep_cevent_list;
    end

    if ~isfield(args, 'dep_type_list')
        dep_type_list = {'cevent_eye_roi_child','cevent_eye_roi_parent','cevent_inhand_child','cevent_inhand_parent'};
    else
        dep_type_list = args.dep_type_list;
    end    

    if ~isfield(args, 'num_bin')
        num_bin = 10;
    else
        num_bin = args.num_bin;
    end




    subj_headers = {'subID','num_instances','session_dur'};
    obj_headers = {'objID','num_instances'};
    subj_bin_col =  length(subj_headers) + 1 : length(subj_headers) + num_bin;
    obj_bin_col = length(obj_headers) + 1 : length(obj_headers) + num_bin;
    
    bins = 0:1/(num_bin):1; % set bins to 0,0.1,0.2, 0.3,...,1
    bin_colNames = binRangeToString(bins);

    % iterate thru experiment list
    for e = 1:length(expIDs)
        expID = expIDs(e);
        num_obj = num_objs(e);

        cevent_col = find(strcmp(dep_cevent_list,dep_cevent));
        if isempty(cevent_col)
            error('Please enter a valid dependent cevent included in the reformatted data for exp%d',expID);
        end
        match_cevent_col = cevent_col * 2 - 1;
        type = dep_type_list{cevent_col};        

        % % load naming reformatted data --> {subject}x{object} 2D cell array
        % file_name = sprintf('../data/%s_exp%d',input_file_name, expID);
        % load(file_name);

        % read the output file from extract multi measure,
        % use reshape_naming_event_measure to get the naming event and
        % naming measure
        [naming_events, naming_measure] = reshape_naming_event_measure(num_obj, input_file_name);
        
        % get the number of 
        [num_sub, num_obj] = size(naming_measure);
        results_sub = []; 
        % aggregate subject-level result
        for s = 1:num_sub
            % flatten data for the current subject
            data_sub = vertcat(naming_measure{s,:});
            data_event = vertcat(naming_events{s,:});
            
            % calculate results
            results_sub(s,1) = data_event(1,1); % subID
            results_sub(s,2)  = size(data_sub,1); % number of naming instances
            
            % calculate trial time
            trial_times= get_trial_times(results_sub(s,1)); 
            results_sub(s,3) = sum(trial_times(:,2)-trial_times(:,1));

            % TODO: rephrase this --> get the distribution of frequency of prop of time of cevent
            % variable
            h = histogram(data_sub(:,match_cevent_col),bins, 'Normalization','probability');
            results_sub(s,subj_bin_col) = h.Values;
        end
        
        % aggregate object-level result
        results_obj =[]; 
        for obj = 1:num_obj
            % flatten data for the current object
            data_obj = vertcat(naming_measure{:,obj});
            data_event = vertcat(naming_events{:,obj});

            % calculate results
            if ~isempty(data_event)
                results_obj(obj,1) = obj; % objID
                results_obj(obj,2) = size(data_obj,1); % number of naming instances
    
                % TODO: rephrase this --> get the distribution of frequency of prop of time of cevent
                % variable
                
                h = histogram(data_obj(:,match_cevent_col),bins, 'Normalization','probability');
                results_obj(obj,obj_bin_col) = h.Values;
            else
                results_obj(obj,1) = obj; % objID
                results_obj(obj,2) = 0;
                results_obj(obj,obj_bin_col) = 0; % put 0 if no data exists for the current object
            end
        end
        
        % write subject- and object-level results to CSV
        colNames_sub = [subj_headers, bin_colNames];
        colNames_obj = [obj_headers, bin_colNames];
        results_sub_table = array2table(results_sub,'VariableNames',colNames_sub);
        results_obj_table = array2table(results_obj,'VariableNames',colNames_obj);

        % set output CSV file names
        output_filename_sub = fullfile(output_dir,sprintf('%s_%s_per_sub_exp%d.csv',output_file_name, type,expID));
        output_filename_obj = fullfile(output_dir,sprintf('%s_%s_per_obj_exp%d.csv',output_file_name, type,expID));

        writetable(results_sub_table,output_filename_sub);
        writetable(results_obj_table,output_filename_obj);
   end
end


function output = binRangeToString(bin)
    % Number of intervals
    n = length(bin) - 1;
    
    % Initialize the cell array for output
    output = cell(1, n);
    
    for i = 1:n
        % Create string for each range and store in the output cell array
        output{i} = sprintf('%.1f-%.1f', bin(i), bin(i+1));
    end
end