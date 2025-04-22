function extracted_data_set = extract_speech_by_keywords(subexpIDs,keywords,output_filename)

    colNames = {'expID','subID','trial time','onset','offset','keywords','utterances'};

    sub_list = cIDs(subexpIDs);
    expIDs = sub2exp(sub_list);
    unique_expIDs = unique(sub2exp(sub_list));
    cat_col = 6;

    extracted_data_set = {};
    for i = 1:length(sub_list)

        sub_id = sub_list(i);
        if ~isempty(keywords)
            args.target_words = keywords;
            extracted_data_set_sub = extract_speech_in_situ(sub_id,'',0,'',args);
        else
            extracted_data_set_sub = extract_speech_in_situ(sub_id,'',0,'');
        end

        for j = 1:length(extracted_data_set_sub)
            if ~isempty(extracted_data_set_sub{j})
                if length(extracted_data_set) < j || isempty(extracted_data_set{j})
                    extracted_data_set{j} = extracted_data_set_sub{j};
                else
                    extracted_data_set{j} = [extracted_data_set{j}; extracted_data_set_sub{j}];
                end
            end
        end

    end

        % remove the cat column
        for j = 1: length(extracted_data_set)
            extracted_data = extracted_data_set{j};
            if ~isempty(extracted_data_set{j})
                extracted_data(:,cat_col) = [];
                extracted_data_set{j} = extracted_data;
            end
        end


    if ~strcmp(output_filename,'')
        if ~isempty(extracted_data_set)
            if ~isempty(keywords) 
                for i = 1:length(keywords)
                    if ~isempty(extracted_data_set{i})
                        keyword = strrep(keywords{i}, ' ', '_');
                        rtr_table = cell2table(extracted_data_set{i},"VariableNames",colNames);
                        writetable(rtr_table,sprintf('%s_%s.csv',output_filename(1:end-4),keyword));
                    else
                        fprintf('no output data is found for %s',keywords{i});
                    end
                end
            else
                rtr_table = cell2table(extracted_data_set{1},"VariableNames",colNames);
                writetable(rtr_table,output_filename);
            end
        else
            disp('no output data is found')
        end
    end

end