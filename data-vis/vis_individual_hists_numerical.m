% input_csv = "M:\extracted_datasets\multipathways\data\JA_child-lead_before_exp44.csv";
% 
%vis_individual_hists_numerical(input_csv, 'Z:\bryanna\subject_level\results', 1, 5, 'cat')
%vis_individual_hists_numerical(input_csv, 'Z:\bryanna\subject_level\results', 1, 13, 'num', 'JA_prop', [0:0.1:1])
%vis_individual_hists_numerical(input_csv2, 'Z:\bryanna\subject_level\results', 1, 12, 'num', 'JA_12_prop',[0:0.1:1])
%vis_individual_hists_numerical(input_csv3, 'Z:\bryanna\subject_level\results', 1, 9, 'cat', 'query_key')
%vis_individual_hists_numerical("M:\extracted_datasets\multipathways\data\JA_child-lead_before_exp58.csv", 'Z:\bryanna\subject_level\results', 1, 5, 'cat', 'JA_58_a_cat')


function [output_table] = vis_individual_hists_numerical(input_csv,output_dir, group_col, var_col, data_type, bins)
    data = readtable(input_csv);

    data(all(ismissing(data),2), :) = [];

    group_column = table2array(data(:, group_col));
    
    group_list = sort(unique(group_column(~isnan(group_column))));


    % histogram for all plots 

    all_data = table2array(data(:, var_col));

    if ~exist('bins', 'var')
        bins = unique(all_data);
    end
    
    fig = figure;

    if strcmp(data_type, 'num')
        histogram(all_data, bins, 'Normalization', 'probability')
        ylim([0 1])
        
        %set up header for the hist matrix
        header = {'groupID'};
        for i = 1:length(bins)-1
            bin = bins(i);
            header{end+1} = num2str(bin);
        end
        
    elseif strcmp(data_type, 'cat')
        all_data = categorical(all_data);
        all_cat = categorical(bins);
        
        histogram(categorical(all_data, all_cat), 'Normalization', 'probability')
        ylim([0 1])
        
        %set up excel file header 
        header = {'groupID'};
        for i = 1:length(bins)
            bin = bins(i);
            if isa(bin, 'double')
                bin = num2str(bin);
            else
                bin = cell2mat(bin);
            end
            header{end+1} = bin;
        end

    else
        disp('invalid data type entered. enter num or cat as datatype')
    end

    title('Overall Visualization');
    
    savefilename = fullfile(output_dir, 'overall_vis.png');
    saveas(fig, savefilename);
    close(fig)


    % histogram by pages     

    page_num = 1;
    
    if length(group_list) < 9
        max_plots = 9;
        fig = figure('Position',[0,0,1000,600]);
    else
        max_plots = 25;
        fig = figure('Position',[0,0,2000,1200]);
        
    end
    
    tiledlayout('flow');
    for i = 1:height(group_list)
        idx = group_column == group_list(i);
 
        sub_data = table2array(data(idx, var_col));

        nexttile;
       
        if strcmp(data_type, 'num')
            
            hh = histogram(sub_data, bins, 'Normalization', 'probability');
            ylim([0 1])
            counts = hh.BinCounts;
            
        else
            
            all_data = categorical(sub_data);
            all_cat = categorical(bins);
            hh = histogram(categorical(all_data, all_cat),'Normalization', 'probability');
            ylim([0 1])
            counts = hh.BinCounts;
           
        end
            hist_mtr(i, :) = counts;

            title(num2str(group_list(i)))

        if mod(i, max_plots) ==0 || i == height(group_list)                
            if i ~= 1
                savefilename = fullfile(output_dir, sprintf('page%d.png', page_num));
                saveas(fig, savefilename);
                close(fig)
                page_num = page_num + 1;   
            end

            if i ~= height(group_list)
                fig = figure('Position',[0,0,2000,1200]);
                tiledlayout("flow");
            end          
        end
    
    end
    
    %put histcount matrix into an excel file and write out 

    results = horzcat(group_list,hist_mtr);
    cell_results = num2cell(results);

    output_table = cell2table(cell_results, "VariableNames", header);

    filename = 'hist.csv';

    writetable(output_table,fullfile(output_dir,filename));
end