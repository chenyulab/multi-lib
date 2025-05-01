
% Input:
%     input_csv: the csv file you want grouped statistics for 
%     output_dir: where the visualizations will save to 
%     group_col: the column number you want grouped by 
%         - if you want subject level data input the column number that has the subject information
%         - can also be category columns
%     var_col: the column number of the variable you want to visualize
% 
%     data type: 'cat' for categorical data like counts of categories, word counts, etc.
%                     - categorical data will be displayed bar chart style
%                'num' for numeric data 
%                    - numeric data will be in histograms
% 
%     bins: for numeric data, the bins you want the histogram 
%                 ex. [0 0.2 0.4 0.6 0.8 1]
%           for categorical data, all categories (or blank)
%                 ex. if there are 24 objects in an experiment, bins will be [1:24]
%                 if left blank, objects not in that specific file will not appear in histogram
                
% Output:
%     - a histogram showing overall distribution of variable specified by var_col for every instance in group variable
%     - n number of histograms organized in 5x5 grids where n is the unique number of instances in the group variabel
%             ex. one plot for each subject if subject is your group variable
%     - an excel file that is the histogram counts by subject
%     - the contents of teh excel file also output in output_table



function output_table = demo_extract_subject_vis_data(option)

    output_dir = "Z:\demo_output_files\extract_subject_vis_data";

    switch option

        case 1
            input_csv = fullfile(output_dir,"JA_child-lead_before_exp44.csv");
            output_dir = fullfile(output_dir,'demo1');
            group_col = 1; %subject id column
            var_col = 5; %object label (categories 1-4)
            data_type = 'cat';
            bins = [1:4];

            output_table = extract_subject_vis_data(input_csv,output_dir, group_col, var_col, data_type, bins);

            %output are histograms depicting the counts of each category
            %for each subject

         case 2
            input_csv = fullfile(output_dir,"JA_child-lead_before_exp44.csv");
            output_dir = fullfile(output_dir,'demo2');
            group_col = 1; %subject_id column
            var_col = 8; %cevent_eye_roi individual prop target cat-all
            data_type = 'num';
            bins = [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];

            output_table = extract_subject_vis_data(input_csv,output_dir, group_col, var_col, data_type, bins);

            %output is a histogram of the proportions of time spent on the
            %target object - the bin 0.9-1 indicates the number of times a
            %subject spent a proportion greater than 0.9 looking at the
            %target object within a joint attention bout
        case 3
            % in this case, the column we want to visualize is word1 
            % leaving bins blank means that the x values will be all unique
            % words in the file
            % 
            % if you want each plot to contain all of the words from the
            % query keywords call, specify the words as bins
            input_csv = fullfile(output_dir,"exp58_verbs.csv");
            output_dir = fullfile(output_dir,'demo3');
            group_col = 1;
            var_col = 9; %words from query keywords call - pbj action verbs 
            data_type = 'cat';


            output_table = extract_subject_vis_data(input_csv,output_dir, group_col, var_col, data_type);

         case 4
             %if you want to group by category instead of subject
            input_csv = fullfile(output_dir,"JA_child-lead_before_exp44.csv");
            output_dir = fullfile(output_dir,'demo4');
            group_col = 5; % category
            var_col = 8; %cevent_eye_roi individual prop target cat-all
            data_type = 'num';
            bins = [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];

            output_table = extract_subject_vis_data(input_csv,output_dir, group_col, var_col, data_type, bins);

            %output would show a histogram for every object which shows the
            %count of each proportion of time the gaze was on the
            %target object 

            %for example, for the histogram of object 1, the bin 0.9-1
            %shows the count of times the proportion on the target during
            %the joint attention bout was above 0.9 
     

    end
end
