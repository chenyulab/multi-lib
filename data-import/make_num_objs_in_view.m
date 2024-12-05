function make_num_objs_in_view(subexpIDs,min_size_list)
% Author: Chen Yu
% Last Editor: Jingwen Pang
% Date Modified: 11/14/2024
% Variable generation function: given subject/exp IDs and list of min size,
% count the number of objects in each timestamp that are larger than min size.
% 
% Input:
%   - subexpIDs
%       list of subjects or experiments
%   - min_size_list
%       list of min size for object size
%       min size is in percentage, e.g min size 2 is 2% and 0.02, 5 is 5% and 0.05
% 
% example call: 
%   make_num_objs_in_view(351,[0, 2, 5])
% 
% output variables:
%   - cont_vision_objs-in-view_min-size-0_child
%   - cont_vision_objs-in-view_min-size-2_child
%   - cont_vision_objs-in-view_min-size-5_child
    
    agents = ['child','parent'];
    
    num_objs = get_num_obj(subexpIDs);
    % sub_list = find_subjects('cont_vision_size_obj1_child',exp_id);
    
    sub_list = cIDs(subexpIDs);
    
    for s = 1 : length(sub_list)
    
        sub_id = sub_list(s);
    
        for a = 1: length(agents)
            agent = agents(a);
        
            if has_variable(sub_id,sprintf('cont_vision_size_obj1_%s',agent))
        
                % load object size variables 
                for i = 1 : num_objs
                    var_name = sprintf('cont_vision_size_obj%d_%s',i,agent); 
                    raw_data = get_variable_by_trial_cat(sub_id,var_name);
                    data{s}(:,i) = raw_data(:,2); 
                end
            
                clear new_data; 
                new_data(:,1) = raw_data(:,1);
            
                for i = 1 : length(min_size_list)
            
                    min_size = min_size_list(i);
            
                    for j = 1 : size(data{s},1)
                        new_data(j,2) = length(find(data{s}(j,:) >=min_size/100));
                    end
            
            
                    output_var_name =sprintf('cont_vision_objs-in-view_min-size-%d_%s',min_size,agent);
                
                    record_additional_variable(sub_id,output_var_name,new_data); 
            
                end
        
            end
        end
    end
end
