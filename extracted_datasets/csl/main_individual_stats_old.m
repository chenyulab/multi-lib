function extract_individual_naming_measure(exp_id, num_objs)
%clear;
%exp_id = 12; 
%num_objs = 24; 
data  = csvread(sprintf('naming_exp%d.csv',exp_id), 4,0);
target_col = 5;
col_offset = 8; 
obj_size_col = (num_objs+1)*3+col_offset; 
prop_col = 8; 
freq_col = (num_objs+1)*2+col_offset;

% copy basic info for each naming instance 
results(:,1:7) =data(:,1:7);

% extract a few measurements from each naming instance 
for i = 1 : size(data,1)
   time_window = data(i,4)-data(i,3); 
   results(i,8) = length(find(data(i,obj_size_col:obj_size_col + num_objs-1)>0));  % # of objs in view 
   results(i,9) = data(i,obj_size_col+results(i,target_col)-1);  % size of the target object 
   results(i,10) = length(find(data(i,prop_col:prop_col + num_objs-1)>0));   % num of attended objs 
   results(i,11) = sum(data(i,freq_col:freq_col+num_objs-1))*time_window/60; % num of looks 
   [value, index]=max(data(i,prop_col:prop_col + num_objs-1));
   results(i,12) = value; % prop of time on the most attended object 
   results(i,13) = index==results(i,5); % most attended one is target (1) or not (0) 
   results(i,14) = data(i,prop_col+results(i,5)-1); % prop of time on the target object 
   results(i,15) = data(i,freq_col+results(i,5)-1)*time_window/60; % num of looks on the target object 
   results(i,16) = results(i,10) - ceil(results(i,14)); % num of attended distractors  
   results(i,17) = results(i,11) - results(i,15); % num of looks on distractors 
   results(i,18) = results(i,10)/results(i,8);  % prop of visiable objs that are attended 

    % calculate (O_t - O_d)/max(O_t, O_d)

   % get the closer competitor 
   others_idx = setxor([1:num_objs],results(i,5));
   [value competitor_idx] = max(data(i,prop_col+others_idx-1));
   results(i,19)= value;  % prop on the most looked competitor 
end

csvwrite(sprintf('individual_stats_exp%d.csv',exp_id),results); 

