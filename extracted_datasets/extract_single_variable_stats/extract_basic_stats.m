%%%
% Original Author: Dr. Chen Yu
% Last modifier: Jane Yang
% Last modified date: 11/15/2023
%
% This function takes in a cevent variable, a expID, and the number of
% objects in the experiment, outputting an Excel file with three sheets for
% each experiment.
%
% Input:
%       varname - target cevent variable name
%       exp_id  - ID of the target experiment
%       num_obj - number of objects in the target experiment
%
% Output: 
% Sheet 1 contains results1 matrix, which has the total proportion of time
% each subject spent looking/holding/naming/being in JA on each object.
%
% Sheet 2 contains results2 matrix, which has the numbers of
% looking/holding/naming/being in JA on each object for each subject.
%
% Sheet 3 contains results3 matrix, which contains the distribution of
% counts that each subject spent on each object.
%
%
% Example function call: extract_basic_stats('cevent_eye_roi_child',12,24)
%%%
function extract_basic_stats(varname, exp_id, num_obj)
    % headers = {'subject_id','trial_length'};
    % get a list of subjects that have the input variable
    sub_list = find_subjects(varname, exp_id); 

    output_dir = 'M:\extracted_datasets\extract_single_variable_stats\results';
    
    if isempty(sub_list)
        disp('!!!cannot find any subject with the specified variable name!!!');
        disp('!!!the variable name is likely to be incorrect!!!');
        return; 
    end
    sub_list = sort(sub_list); 
    % initialize bins, ranging from 0 to 20 with 0.25 increment
    bins = [0:0.25:20];
    
    % iterate thru subject list
    for s = 1:length(sub_list)
        % read target variable for the current su  st, 1, num_obj);
        data = get_variable_by_trial_cat(sub_list(s),varname);
        trial_time = get_trial_times(sub_list(s));
    
        results1(s,1) = sub_list(s);
        results1(s,2) = sum(trial_time(:,2)-trial_time(:,1));
        results2(s,1:2) = results1(s,1:2);

        % set up result3 matrix for subject X object results
        temp = repmat(sub_list,1,num_obj);
        results3(:,1) = reshape(temp',length(sub_list)*num_obj, 1);
        results3(:,2) = repmat([1:num_obj]', length(sub_list),1);
        
        % initialize object-level duration list
        dur_list{s} = zeros(num_obj, length(bins));

        if ~isempty(data) % check if data is empty for current subject
            for i = 1:num_obj
                index = find(data(:,3)==i);
                
                if isempty(index) % target object not found in data
                   results1(s,i+2) = 0; 
                   %results1(s,i+2+num_obj) = 0; 
                   results2(s,i+2) = 0; 
                   %results2(s,i+2+num_obj) = 0; 
                else
                   results1(s,i+2) = sum(data(index,2)-data(index,1));  
                   results2(s,i+2) = length(index);  
                   
                   duration = data(index,2)-data(index,1); 
                   dur_list{s}(i,:) = hist(duration, bins); 
                end
            end

            % for total looking time, get prop of time
            results1(s,2+num_obj+1:2+num_obj*2) = results1(s,3:2+num_obj) ./results1(s,2); 
            % for # of looks, normalized to frequency (# per min) 
            results2(s,2+num_obj+1:2+num_obj*2) = results2(s,3:2+num_obj)*60/results2(s,2); 


        else % set three matrices to zero if data is empt
            fprintf('Variable %s is empty for subject %d!\n',varname,sub_list(s));
            results1(s,3:num_obj*2+2) = zeros(1,num_obj*2);
            results2(s,3:num_obj*2+2) = zeros(1,num_obj*2);
            results3(s,3:length(bins)+2) = zeros(1,length(bins));
        end
    end
    % concate duration histogram across subjects
    results3(:,3:length(bins)+2) = vertcat(dur_list{:});
    
    % save results to Excel files, each result occupies one sheet
    filename = [varname sprintf('_exp%d.xlsx',exp_id)];
    t1 = array2table(results1); 
   

    header ={'subID','total time'}; 
    prefix_header={'time','prop'};
    for i = 1 : length(prefix_header)
         for j = 1  : num_obj
              header{2+j+(i-1)*num_obj}=sprintf('%s-cat-%d',prefix_header{i},j);
         end 
    end
    t1.Properties.VariableNames  =header; 
    writetable(t1,fullfile(output_dir,filename),'Sheet',1);

    header ={'subID','total time'};
    t2 = array2table(results2);
    prefix_header={'freq','normalized freq'};
    for i = 1 : length(prefix_header)
         for j = 1  : num_obj
              header{2+j+(i-1)*num_obj}=sprintf('%s-cat-%d',prefix_header{i},j);
         end 
    end
    t2.Properties.VariableNames  =header;
    writetable(t2,fullfile(output_dir,filename),'Sheet',2);

    header ={'subID','cat-id'};
    t3 = array2table(results3);
    for j = 1  : length(bins)
         header{2+j}=sprintf('%s',num2str(bins(j)));
    end 

    t3.Properties.VariableNames  =header;
    writetable(t3,fullfile(output_dir,filename),'Sheet',3);

end

