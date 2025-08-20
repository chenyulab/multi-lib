function rtr_data = get_exp_word_list(expID, word_list)

    filepath = fullfile(get_experiment_dir(expID), 'vocab_list.csv');
    data = readtable(filepath);

    if exist("word_list", "var") && ~isempty(word_list)
        if isnumeric(word_list)
            % Numeric input: return matching rows, unmatched as ID=0
            [~, order_idx] = ismember(word_list, data.id);
            rtr_data = cell(length(word_list), width(data));
            for i = 1:length(word_list)
                if order_idx(i) > 0
                    rtr_data(i,:) = table2cell(data(order_idx(i), :));
                else
                    % Assign 0 ID and fill rest with empty
                    rtr_data(i,:) = [{0}, repmat({''}, 1, width(data)-1)];
                end
            end

        elseif iscellstr(word_list) || isstring(word_list)
            word_list = cellstr(word_list);  % Ensure cellstr
            [~, order_idx] = ismember(word_list, data.word);
            rtr_data = cell(length(word_list), width(data));
            for i = 1:length(word_list)
                if order_idx(i) > 0
                    rtr_data(i,:) = table2cell(data(order_idx(i), :));
                else
                    % Assign 0 ID and keep the original word string
                    rtr_data(i,:) = [{0}, word_list(i), repmat({''}, 1, width(data)-2)];
                end
            end
        else
            error("Please input a valid word list, either word id list [1,2,3] or word list {'a','b','c'}");
        end
    else
        rtr_data = table2cell(data);
    end

end
