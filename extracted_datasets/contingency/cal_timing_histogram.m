function cal_timing_histogram(load_filename, tag_col, time1_col, time2_col, header_skip, bins, save_filename)
end
%exp_id = 80; 
%file_name = sprintf('M:/extracted_datasets/contingency/data/naming_following_exp%d.csv',exp_id);
%tag_col = 1; % using this column to divide data into subsets, if 0, not divided
%time1_col = 2; % must have 
%time2_col = 6; % if 0, not time2
%header_skip = 2; 
%bins = [0:0.5:5]; 
%output_name = 'test.csv'; 
% e.g.
% cal_timing_histogram('M:/extracted_datasets/contingency/data/naming_following_exp12.csv', 1, 2, 6, 2, [0:0.5:5],'../data/test.csv')
%


data = csvread(load_filename, header_skip, 0); 

% get all the data 
if tag_col ~= 0
    tag_list = unique(data(:,tag_col));
    for i = 1 : length(tag_list)
        index = find(data(:,tag_col)==tag_list(i));
        if time2_col ~=0
            hist_data{i} = data(index,time1_col)-data(index,time2_col);
        else
            hist_data{i} = data(index,time1_col);
        end
    end
else
    if time2_col ~=0
        hist_data{1} = data(:,time1_col)-data(:,time2_col);
    else
        hist_data{i} = data(:,time1_col);
    end
end

% draw hist
for  i = 1 : length(hist_data)
    results(i,:) = hist(hist_data{i},bins);
end
csvwrite(save_filename,results);






