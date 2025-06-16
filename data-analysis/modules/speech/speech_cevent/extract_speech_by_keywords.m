% This function extract speech utterance based on the keyword
function extracted_data_set = extract_speech_by_keywords(subexpIDs,keywords,output_filename)
    colNames = {'expID','subID','trial time','onset','offset','keywords','utterances'};
    cat_col = 6;

    if ~isempty(keywords)
        args.target_words = keywords;
        extracted_data_set = extract_speech_in_situ(subexpIDs,'',0,'',args);
    else
        extracted_data_set = extract_speech_in_situ(subexpIDs,'',0,'');
    end

    % remove the cat column
    if ~isempty(extracted_data_set)
        extracted_data_set(:,cat_col) = [];
    end

    if ~strcmp(output_filename,'')
        if ~isempty(extracted_data_set)
            rtr_table = cell2table(extracted_data_set,"VariableNames",colNames);
            writetable(rtr_table,output_filename);
        else
            disp('no output data is found')
        end
    end

end