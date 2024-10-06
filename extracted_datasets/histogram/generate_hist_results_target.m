function generate_hist_results_target(expIDs, input_filename, output_filename, args)
% {
% args.dep_cevents
% args.num_bin
% }

    input_dir = "M:/extracted_datasets/histogram/data";
    output_dir = "M:/extracted_datasets/histogram/results";
    start_col = 8;
    subj_headers = {'subID','num_instances','session_dur'};
    obj_headers = {'objID','num_instances'};


    if ~exist('args', 'var') || isempty(args)
         args = struct([]);
    end

    if ~isfield(args, 'num_bin')
        num_bin = 10;
    else
        num_bin = args.num_bin;
    end


    subj_bin_col =  length(subj_headers) + 1 : length(subj_headers) + num_bin;
    obj_bin_col = length(obj_headers) + 1 : length(obj_headers) + num_bin;
    
    bins = 0:1/(num_bin):1; % set bins to 0,0.1,0.2, 0.3,...,1
    bin_colNames = binRangeToString(bins);


    % iterate thru experiment list
    for e = 1:length(expIDs)
        expID = expIDs(e);
        num_obj = get_num_obj(expID);

        % get cevent variable list
        input_file = fullfile(input_dir,sprintf('%s_exp_%d.csv',input_filename,expID));
        dep_cevent_list = {};
        input_table = readtable(input_file, "DataLine",5, "VariableNamesLine",1);
        cevent_headers = input_table.Properties.VariableNames;
        for i = start_col:2:length(cevent_headers)
            dep_cevent_list = [dep_cevent_list,cevent_headers{i}];
        end
    
        % detect if there is specific dep variable, if not, go over all the
        % variables
        if ~isfield(args, 'dep_cevents')
            target_cevents = dep_cevent_list;
        else
            target_cevents = args.dep_cevents;
        end

        % iterate thru variable list
        for i = 1:length(target_cevents)
            dep_cevent = target_cevents{i};
    
            cevent_col = find(strcmp(dep_cevent_list,dep_cevent));
            if isempty(cevent_col)
                error('Please enter a valid dependent cevent included in the reformatted data for exp%d',expID);
            end
            match_cevent_col = cevent_col * 2 - 1;
            var_name = dep_cevent;        
    
            % read the output file from extract multi measure,
            % use reshape_event_measure to get the naming event and
            % naming measure
            [naming_events, naming_measure] = reshape_event_measure(num_obj, table2array(input_table));
            
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
                results_sub(s,2) = size(data_sub,1); % number of naming instances
                
                % calculate trial time
                trial_times= get_trial_times(results_sub(s,1)); 
                results_sub(s,3) = sum(trial_times(:,2)-trial_times(:,1));
    
                % TODO: rephrase this --> get the distribution of frequency of prop of time of cevent
                % variable
                h = histogram(data_sub(:,match_cevent_col),bins, 'Normalization','probability');
                results_sub(s,subj_bin_col) = h.Values;
            end

            total = sum(results_sub);
            total(:,4:end) = total(:,4:end)/num_sub;
            results_sub = [results_sub; total];

            results_sub(num_sub+1,1) = expID;

            total(:,4:end)
            figure;
            bar(total(:,4:end));
            set(gca, 'XTickLabel', bin_colNames);

            var_name_sp = strrep(var_name,'_',' ');
            output_filename_sp = strrep(output_filename, '_', ' ');
            title(sprintf('%s %s %d',output_filename_sp,var_name_sp,expID));
            xlabel('Ranges');
            ylabel('normalized frequency');
            
            % Save the histogram as a PNG image
            saveas(gcf, fullfile(output_dir,sprintf('%s_%s_%d.png',output_filename,var_name,expID)));
            close(gcf);

            
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
            output_filename_sub = fullfile(output_dir,sprintf('%s_%s_per_sub_exp%d.csv',output_filename,var_name,expID));
            output_filename_obj = fullfile(output_dir,sprintf('%s_%s_per_obj_exp%d.csv',output_filename,var_name,expID));
    
            writetable(results_sub_table,output_filename_sub);
            writetable(results_obj_table,output_filename_obj);
        end
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

function [naming_events, naming_measure] = reshape_event_measure(num_obj,raw_data)

    sub_list = unique(raw_data(:,1));
    for sub = 1: length(sub_list)
        index = find(raw_data(:,1)==sub_list(sub));
        data_sub = raw_data(index,:);
        for obj = 1: num_obj
            naming_events{sub,obj} =[];
            index = find(data_sub(:,5) == obj);
            naming_events{sub,obj} = data_sub(index,1:7);
            naming_measure{sub,obj} = data_sub(index,8:end);

        end
    end

end