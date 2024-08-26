% Author: Ruchi Shah
% Last modified: 02/28/2024
% 

function cal_duration_histogram(file_dir, variable_name, exp_id, tag_col,save_dir)
    filepath = fullfile(sprintf('%s/%s_exp%d.xlsx', file_dir, variable_name, exp_id));
    data = readmatrix(filepath, 'Sheet', 3);
    size(data)
    bin_size = size(data,2)-2; 
    % get all the data  
    if tag_col ~= 0
        tag_list = unique(data(:,tag_col));
        results = zeros(length(tag_list),bin_size+1); 
        for i = 1 : length(tag_list)
           index = find(data(:,tag_col)==tag_list(i));
           results(i,1:bin_size) = sum(data(index,3:end));
           results(i,1:bin_size) = results(i,1:bin_size)./sum(results(i,1:bin_size)); 
           results(i,end) = sum(sum(data(index,3:end)));
        end
    else
        results(1,:) = sum(data(:,3:end));
        results(1,:) = results(1,:)./sum(results(1,:));
        results(1,end+1) = sum(sum(data(:,3:end)));
    end
    bar(results(1,1:bin_size));
    saveas(gcf,sprintf('%s/%s_exp%d.jpg', save_dir, variable_name, exp_id)); 
    writematrix(results, sprintf('%s/%s_exp%d_hist.csv', save_dir, variable_name, exp_id))
end 

%file_name = sprintf('M:/extracted_datasets/single_variable_stats/results/eye_joint-attend_both_exp%d.xlsx',exp_id);
%tag_col = 1; % 0-no grouping; 1 -- grouping based subjects; 2 -- grouping based on items/words/objects
%output_name = 'test.csv'; 
% e.g.
%   cal_duration_histogram('..\results\', 'eye_roi_child', 70, 0, '..\duration_hist');



% data = xlsread(sprintf('%s/%s_exp%d.xlsx', load_dir, variable_name, exp_id),3);
% size(data)
% bin_size = size(data,2)-2; 
% % get all the data  
% if tag_col ~= 0
%     tag_list = unique(data(:,tag_col));
%     results = zeros(length(tag_list),bin_size+1); 
%     for i = 1 : length(tag_list)
%        index = find(data(:,tag_col)==tag_list(i));
%        results(i,1:bin_size) = sum(data(index,3:end));
%        results(i,1:bin_size) = results(i,1:bin_size)./sum(results(i,1:bin_size)); 
%        results(i,end) = sum(sum(data(index,3:end)));
%     end
% else
%    results(1,:) = sum(data(:,3:end));
%    results(1,:) = results(1,:)./sum(results(1,:));
%    results(1,end+1) = sum(sum(data(:,3:end)));
% end
% bar(results(1,1:bin_size));
% saveas(gcf,sprintf('%s/%s_exp%d.jpg', save_dir, variable_name, exp_id)); 
% csvwrite(sprintf('%s/%s_exp%d_hist.csv', save_dir, variable_name, exp_id),results);
