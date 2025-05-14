% input_csv = "Z:\bryanna\subject_level\speech_in_roi_co_ccur_351.csv"
% output_dir = "Z:\bryanna\subject_level\keyword_hist_results"
% keyword_list = ["is", "babyname", "you"]


function make_keyword_hist(input_csv, output_dir, keyword_list, group_col, args)
    if ~exist('args', 'var')|| isempty(args)
        args = struct([]);
    end
    
    if isfield(args, 'start_word_col')
        start_word_col = args.start_word_col;
    else
        start_word_col = 4;
    end

    if isfield(args, 'word_display_limit')
        word_display_limit = args.word_display_limit;
    else
        word_display_limit = 20;
    end

    if isfield(args, 'global_common_words')
        global_common_words = args.global_common_words;
    else
        global_common_words = 0;
    end

    %read data
    data = readtable(input_csv);

    all_words = data.Properties.VariableNames(start_word_col:end);

    group_column = data(:, group_col);
    group_list = table2array(unique(group_column));
    
    cell_group = num2cell(group_list);

    if width(group_list) >1
        row_labels = vertcat({'overall' 'overall'}, cell_group);

    else
        row_labels = vertcat({'overall'}, cell_group);
    end

    data = table2array(data);
    
    % %get overall visualization

    all_counts = sum(data(:,start_word_col:end), 1);
    
    keyword_idx = [];
    for i = 1:length(keyword_list)
        idx = find(strcmp(keyword_list{i}, all_words)); 
        if isempty(idx)
            keyword_idx(end+1) = -1; 
        else
            keyword_idx(end+1) = idx;  % Append indices to preserve order
        end
    end

    %keyword histogram overall visualization
    for i = 1:length(keyword_list)
        if (keyword_idx(i)>0)
            keyword_counts(i,:)=all_counts(keyword_idx(i),:);
        else
            keyword_counts(i,:) =0; 
        end
    end

    keyword_counts = all_counts(keyword_idx);

    %sort keywords
    [sort_counts_key, sortIdxKey] = sort(keyword_counts, 'descend');
    sort_words_key = keyword_list(sortIdxKey);
    
    %display words up to word display limit - if there are less keywords
    %than word limit, display all 
    if length(keyword_list) <= word_display_limit
        disp_key_words = sort_words_key;
        disp_key_counts = sort_counts_key;
    else
        disp_key_words = sort_words_key(1:word_display_limit);
        disp_key_counts = sort_counts_key(1:word_display_limit);
    end

    histogram('Categories', disp_key_words, 'BinCounts', disp_key_counts);

    %save keyword file and close figure 
    savefilename = fullfile(output_dir, "overall_visualization_keywords.png");
    saveas(gcf, savefilename);
    close(gcf);
    
    %get counts for overall visualization
    [sort_counts, sortIdxGlobalCommon] = sort(all_counts, 'descend');
    sort_words = all_words(sortIdxGlobalCommon);
    
    disp_words_global_common = sort_words(1:word_display_limit);
    disp_counts = sort_counts(1:word_display_limit);

    
    histogram('Categories', disp_words_global_common, 'BinCounts', disp_counts);
   
    %highlight key words on the most common word plot
    ax = gca;

    % Get x-axis tick labels
    xticklabels = ax.XTickLabel; 
    
    % Modify labels
    for i = 1:length(xticklabels)
        if any(strcmp(keyword_list,xticklabels{i}))
            xticklabels{i} = ['\color{red} ', xticklabels{i}];
        end
    end
    
    % Apply new labels and rotate them
    ax.XTickLabel = xticklabels;


    savefilename = fullfile(output_dir, "overall_visualization_common.png");
    saveas(gcf, savefilename);
    close(gcf);
    
    %setup keyword matrix
    key_mtr(1,:) = disp_key_counts;
    
    %set up most common words matrix
    if global_common_words == 1

        %groupid column will be the same for either, add overall to top
        
        hist_mtr(1,:) = disp_counts;
    else
        unique_most_common_filename = fullfile(output_dir, "most_common_words_data_by_group.xlsx");
        % Create a descriptive sheet name
        sheetName = "overall";
        % Write the full matrix to Excel
        T = array2table(disp_counts, 'VariableNames', disp_words_global_common);

        writetable(T, unique_most_common_filename, 'Sheet', sheetName);

    end

    % generate histograms for individual groups

    page_num = 1;
    
    common_figure = figure('Position',[0,0,1400,1200]);
    tiledlayout(5,5);

    key_figure = figure('Position',[0,0,1400,1200]);
    tiledlayout(5,5);
    for i = 1:height(group_list)

        idx = group_column == group_list(i, :);
        if width(group_list) >1
            group_idx = find(all(idx{:,:}, 2));
        else
            group_idx = table2array(idx);
        end

        sub_data = data(group_idx, start_word_col:end);
   
        if height(sub_data) > 1
            plot_data = sum(sub_data, 1);
            plot_name = num2str(group_list(i));
        else
            plot_data = sub_data;
            plot_name = sprintf('%d_%d', data(i,1), data(i,2));
        end
        figure(key_figure);

        %create next tile on plot
        nexttile;

        %sort counts and words to rank order and limit histogram
        %keyword histogram

        %plots keywords in the same order as they appear in the overall
        %visualization
        keyword_counts = plot_data(sortIdxKey);

        
        if length(keyword_list) <= word_display_limit
            disp_key_counts = keyword_counts;
        else
            disp_key_counts = keyword_counts(1:word_display_limit);
        end

        %create keyword histogram here 
        key_mtr(1+i,:) = disp_key_counts;
        key_hist = histogram('Categories', disp_key_words, 'BinCounts', disp_key_counts);
        
        title(plot_name,'Interpreter','none')

        figure(common_figure);
        nexttile;
        %create common words histogram 

        if global_common_words == 1        
            counts = plot_data(sortIdxGlobalCommon);

            disp_counts = counts(1:word_display_limit);
            hist_mtr(i+1,:) = disp_counts;
     
            common_hist = histogram('Categories', disp_words_global_common, 'BinCounts', disp_counts);
        else
            [sort_counts, sortIdx] = sort(plot_data, 'descend');
            sort_words = all_words(sortIdx);
            
            disp_words = sort_words(1:word_display_limit);
            disp_counts = sort_counts(1:word_display_limit);

            common_hist = histogram('Categories', disp_words, 'BinCounts', disp_counts);
            % Create a descriptive sheet name

            if width(group_list) >1
                sheetName = sprintf("%d_%d",group_list(i,1), group_list(i,2));     
            else
                sheetName = num2str(group_list(i));
            end
            

            T = array2table(disp_counts, 'VariableNames', disp_words);

            % Write the full matrix to Excel
            writetable(T, unique_most_common_filename, 'Sheet', sheetName);
    
        end

       
        %highlight keywords for common matrix
        ax = gca;
    
        % get x-axis tick labels
        xticklabels = ax.XTickLabel; 
        
        % modify labels
        for k = 1:length(xticklabels)
            if any(strcmp(keyword_list,xticklabels{k}))
                xticklabels{k} = ['\color{red} ', xticklabels{k}];
            end
        end
        
        %apply new labels 
        ax.XTickLabel = xticklabels;
            

        
        %set hist properties
        xtickangle(90)
        yLim = get(gca,'YLim');
        set(gca,'YLim', [0 yLim(2)]);
        title(plot_name,'Interpreter','none')


        if mod(i, 25) ==0 || i == height(group_list)                
            if i ~= 1
                savefilename = fullfile(output_dir, sprintf('page%d.png', page_num));
                saveas(common_figure, savefilename);
                close(common_figure); 

                savefilename = fullfile(output_dir, sprintf('keyword_page%d.png', page_num));
                saveas(key_figure, savefilename);
                close(key_figure);

                page_num = page_num + 1;   
            end

            if i ~= height(group_list)
                common_figure = figure('Position',[0,0,1400,1200]);
                tiledlayout("flow");
            
                key_figure = figure('Position',[0,0,1600,1200]);
                tiledlayout("flow");
            end          
        end
    end


    if global_common_words == 1
        
        results = horzcat(row_labels, num2cell(hist_mtr));
    
        cell_results = num2cell(results);
      
        output_table = cell2table(cell_results, 'VariableNames', ['groupID' disp_words_global_common]);
        
        data_file = "global_common_words_histogram_data_by_group.xlsx";
        data_filename = fullfile(output_dir, data_file);
    
        writetable(output_table, data_filename)
        fprintf("Common words histogram data written out to %s\n", data_filename)
    
    else
        fprintf("Most common words (by group) histogram data written out to %s\n", unique_most_common_filename)
    end

    %write out keyword histogram
    key_results = horzcat(row_labels, num2cell(key_mtr));

    key_cell_results = num2cell(key_results);


    if width(group_list) >1
        var_labels = ['groupID' 'groupID2' disp_key_words];

    else
        var_labels = ['groupID' disp_key_words];
    end

    key_output_table = cell2table(key_cell_results, 'VariableNames', var_labels);
    
    data_file = sprintf("keyword_histogram_data.xlsx");
    data_filename = fullfile(output_dir, data_file);

    writetable(key_output_table, data_filename)

    fprintf("Keyword histogram data written out to %s\n", data_filename)

end