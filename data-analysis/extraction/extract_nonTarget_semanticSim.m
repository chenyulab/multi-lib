%%
%  During a naming event, find all the objects in child's view (either by using
%  cevent pages or cont_obj_size) and assign them to 3 groups: target
%  (named object) (1), attended_non-target (2), and not-attended_non-target (3).
%  Then for each group take each object and find its semantic similarity to
%  the target and average them. So you will have two averages during each naming instance 
%
%  Author: Elton Martinez
%  Modified: 
%  Last modified: 9/4/2025
%  
%  Parameters
%  type 
%       -- int, 1 means book reading, 2 means toy play. Based on how you
%       extract the emm file
%  input_file 
%       -- ch/str, name of the extract_multi_measures_file, see demo 
%          to see how to get the expected emm file
%   output_name
%       -- ch/str, name of the file
%  
%  Optional Paramers
%  args.list 
%       -- boolean, will show and extract column with all the objects in
%          each group
%       -- min_dur, excluded roi instances that are less than this value
%       -- obj_nr_and_idenity_by_page, the page2obj dictionary for all book
%          reading experiments
%
%%

function extract_nonTarget_semanticSim(type, input_file, output_name, varargin)
    warning('off','MATLAB:table:ModifiedAndSavedVarnames')
    % define default arguments
    args = set_optional_args(varargin,{'list','min_dur','obj_nr_and_identity_by_page'},{false,0,''});

    extract_cell_all = readcell(input_file);
    header = extract_cell_all(1:3,:);
    extract_cell = extract_cell_all(5:end,:);
    expID = extract_cell{1,2};    

    % find how many columns until the next variable
    % whether pages or cont 
    for i = 9:numel(header(1,:))
        val = header{1,i};

        if ~ismissing(val)
            next_var_start = i;
            break
        end
    end
    
    % get the actual number of objects
    % might have columns 1-2-4 so i would not refer to the ith object
    obj_strs = extract_cell_all(4,8:next_var_start-1);
    obj_idx = zeros(1,numel(obj_strs));
    
    for i =1:numel(obj_strs)
        n =  regexp(obj_strs{i},'\d+', 'match');
        obj_idx(i) = str2double(n);
    end

    % get label-wise semantic sim matrix  
    sim_table = get_obj_label_sim_matrix(expID);

    if isempty(sim_table)
        fprintf("file saved: [NaN]\n");
        return
    end
    
    % get objs num and labels 
    obj_num = get_num_obj(expID);
    obj_array = 1:obj_num;
    raw_obj_labels = get_object_label(expID,obj_array);
    obj_labels = cell(1,numel(raw_obj_labels));

    % use the first "name" of the label (default) 
    for i = 1:numel(obj_labels)
        val = split(raw_obj_labels{i},',');
        obj_labels{i} = val{1};
    end
    
    % objs_in_view is a binary matrix indicating whether the ith object is in the view
    % for that row. Where what a row means depends on the activity. For
    % bookread row is page and for toyplay row is naming instance 
    if type == 1
        objsInPage = get_objsInPage(expID);
        bool_objsInView = objsInPage{:,4:obj_num+3};

        instanceName = 'page';

    elseif type == 2
        bool_objsInView_cont = cell2mat(extract_cell(:,next_var_start:end));
        bool_objsInView = bool_objsInView_cont > 0;
        
        instanceName = 'instance';
    end

    % preallocate output data 
    col_names = {'subID','expID','onset','offset','target',instanceName,'non-target_attend_semantic-sim','non-target_non-attend_semantic-sim',...
                 'non_target-attend_num_objs','non-target_non-attend_num_objs','nt_na_sim-min','nt_na_sim-max','nt-a_list','nt-na_list','3','4'};
    data = cell(height(extract_cell),16);

    for i = 1:height(extract_cell)
        gattend_vals = zeros(1,obj_num);
        lattend_vals = [extract_cell{i,8:next_var_start-1}];
        
        % broadcast 
        % the objects in the emm ouput may be a subset of 
        % the total set of objects 
        for j = 1:numel(lattend_vals)
            idx = obj_idx(j);
            if idx <= obj_num
                gattend_vals(idx) = lattend_vals(j);
            end
        end
    
        target_obj = extract_cell{i,5};
        
        data{i,1} = extract_cell{i,1}; %subID
        data{i,2} = extract_cell{i,2}; %expID
        data{i,3} = extract_cell{i,3}; %onset
        data{i,4} = extract_cell{i,4}; %offset
        data{i,5} = target_obj;

        %$ only for book reading 
        % so curr_ref means what page for bookreading 
        % and which row in the input file for toyplay
        % the values assigned to col 6 are not equal 
        if type == 1
            curr_poss_page = [extract_cell{i, next_var_start:end}];
            curr_ref = find(curr_poss_page > 0.5);
    
            if isempty(curr_ref) | curr_ref > height(bool_objsInView) | target_obj > obj_num
                if ~isempty(curr_ref)
                    data{i,6} = curr_ref;
                else
                    data{i,6} = NaN;
                end
                data{i,7} = NaN;
                data{i,8} = NaN;
    
                data{i,9} = 0;
                data{i,10} = 0;
    
                data{i,11} = NaN;
                data{i,12} = NaN;
                continue
            end
            data{i,6} = curr_ref;
        elseif type == 2
            data{i,6} = extract_cell{i,7};
            curr_ref = i;
        end
        
        % get obj subsets without target 
        non_target_cats = obj_array([1:target_obj-1 target_obj+1:end]);
        non_target_vals = gattend_vals(non_target_cats);
        
        % find groups 
        attend_mask = non_target_vals > args.min_dur;
        nt_attend_cats = non_target_cats(attend_mask);
        nt_n_attend_cats = non_target_cats(~attend_mask);

        groups = {nt_attend_cats, nt_n_attend_cats};
        objs_in_view = bool_objsInView(curr_ref,:);

        for j = 1:2
            % Subset the above to only include objects in the current page
            group = groups{j};
            is_present = logical(objs_in_view(group));
            group_in_page = group(is_present);

            if isempty(group_in_page)
                data{i,6+j} = NaN;
                data{i,8+j} = 0;

                if j == 2
                    data{i,11} = NaN;
                    data{i,12} = NaN;
                end
            else
                target_label = obj_labels{target_obj};
                group_labels = obj_labels(group_in_page);
                try
                    sim_instance = sim_table{target_label,group_labels};
                    sim = mean(sim_instance);
                    % wow so if sim is a double matlab freaks 
                    data{i,6+j} = sim(1);

                    if j == 2
                       data{i,11} = min(sim_instance);
                       data{i,12} = max(sim_instance);
                    end
                catch ME

                    if strcmp(ME.identifier, 'MATLAB:table:UnrecognizedVarName')
                        error_label = regexp(ME.message,'''([^]+)''','match');
                        error_label = error_label{1}(2:end-1);
                        fprintf("Could not find semantic sim for label: %s\n Most likely a dictionary-sim_matrix mismatch\n",error_label)
                    
                    else
                        disp(ME.message)
                    
                    end 
                    data{i,6+j} = NaN;
                    data{i,11} = NaN;
                    data{i,12} = NaN;
                end
                
                data{i,8+j} = numel(group_in_page);
                data{i,12+j} = group_in_page;
                data{i,14+j} = group_labels;
            end
        end
    end
    
    if ~args.list 
        remove = 4;
    else
        remove = 2;
    end

    data = data(:,1:end-remove);
    col_names = col_names(1:end-remove);

    data = [col_names; data];
    writecell(data, output_name);
    fprintf('Saved file: %s\n\n',output_name);
end
