clear; 
% extract_contingency_stats_by_subject  
% input: two input files, timing threshold, output file name

%exp_ids =[ 71 72 73 74 75 91 27];
%exp_ids = [77 78 79 80];
exp_ids = [96];
result_file_name = 'inhand-eye_child-child_exp%d.csv'; 

num_row = 1; 

for i = 1 : length(exp_ids)
    exp_id = exp_ids(i); 
    
    % how fast parents follow the child's attention to name an object 
    file_name = sprintf('M:/extracted_datasets/project_contingency/data/naming_following_exp%d.csv',exp_id);
    data1 = csvread(file_name,2,0); 
    % timing of naming  an object by following child's attention
    lag= data1(:,2)-data1(:,6); 
    %histogram(lag,[0:0.5:5],'Normalization','probability');
    %axis([0 5 0 0.3])
    index=find(lag<=5);
    data1 = data1(index,:); 
    look_after = data1(:,7) - data1(:,2); 
    median(look_after);
    look_overall = data1(:,7) - data1(:,6); 
    median(look_overall); 
    
    % child response to parent naming
    l = 9; 
    file_name = sprintf('M:/extracted_datasets/project_contingency/data/naming_led_exp%d.csv',exp_id);
    data2 = csvread(file_name,1,0); 
    
    
    % break into subs
    sub_list1 = unique(data1(:,1));
    sub_list2 = unique(data2(:,1));
    sub_list = union(sub_list1, sub_list2); 
    if isempty(sub_list)
        disp('An empty subject list. The source data is likely to be incorrect');         
        return;
    end;
    % sub_list =[9621 9622]; 
    for s = 1 : length(sub_list)
        
        index = find(data1(:,1) == sub_list(s)); 
        results(num_row+s-1,1) = sub_list(s); 
        % following cases, look first, naming after 
        f =0; 
        results(num_row+s-1,2+f)   = length(unique(data1(index,1))); 
        results(num_row+s-1,3+f)  =  size(data1(index,:),1); %length(index)/size(data1,1)
        results(num_row+s-1,4+f)  = median(look_overall(index));
        results(num_row+s-1,5+f)  = std(look_overall(index))/sqrt(length(look_overall(index)));
        results(num_row+s-1,6+f)  = median(lag(index));
        results(num_row+s-1,7+f)  = std(lag(index))/sqrt(length(lag(index)));
        results(num_row+s-1,8+f)  = median(look_after(index)); 
        results(num_row+s-1,9+f)  = std(look_after(index))/sqrt(length(look_after(index)));

        % leading cases, naming first, looking after 
        response_look_thred = 3; 
        index1 = find(data2(:,1) == sub_list(s)); 
        index = find((data2(index1,4)-data2(index1,2))<=response_look_thred);
        %size(index); 
        response_time = data2(index1(index),4)-data2(index1(index),2); 
        response_dur = data2(index1(index),5)-data2(index1(index),4);  


        % index_nonresponse = setxor([1:size(data2(index1(index),:),1)],index); 
        index_nonresponse = setxor([1:size(data2(index1,:),1)],index);
        length(index_nonresponse)
        length(index)
        data2(index1(index),2:end)
        data2(index1(index_nonresponse),2:end)

        %figure(2);
        %histogram(response_time,[0:0.5:5],'Normalization','probability');
        %axis([0 response_look_thred 0 0.3])
        %size(index,1)/size(data2,1); 
        results(num_row+s-1,l+1) = length(index);
        results(num_row+s-1,l+2) = length(index_nonresponse); 
        results(num_row+s-1,l+3) = results(num_row+s-1,l+1)/size(index1,1);
        results(num_row+s-1,l+4) = median(response_time); 
        results(num_row+s-1,l+5) = std(response_time)/sqrt(length(response_time));
        results(num_row+s-1,l+6) = median(response_dur); 
        results(num_row+s-1,l+7) = std(response_dur)/sqrt(length(response_dur));

        % change the threshold to be 1 sec
        response_look_thred = 1; 
        index = find((data2(index1,4)-data2(index1,2))<=response_look_thred);
        results(num_row+s-1,l+8) = length(index);
        results(num_row+s-1,l+9) = results(num_row+s-1,l+8)/size(index1,1);
  
    end
    
    num_row = num_row + length(sub_list); 
   
    
    
end

csvwrite(result_file_name,results); 
