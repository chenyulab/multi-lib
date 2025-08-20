%% 
% Author: Elton Martinez
% Modifier: Eric Zhao
% last modified: 8/1/2025
%
% For each subjects the function calculates the unique pairwise similarity within 
% categories.
%
% Input parameters:
% - subexpID
%     array, list of subjects or experiment
% - resNet_path
%     string, the path of the resnet mat file
% - output_directory
%     string, the path of the output file(s)
% - within_directory_name
%     string, the name of the folder containing all the within object csv files
% 
% Optional arguments:
% - args.skip_within
%     boolean, indicate whether to skip within object calculations, 
%     functions does all calculations by default
% - args.skip_across
%     boolean, indicate whether to skip across object calculations, 
%     functions does all calculations by default
% - args.output_to_attended_obj_folder
%     boolean, indicate whether to output to attended-objs-frames folder in multiwork
%     instead of output_directory in input parameters
%
% Output: 
%  One xlsx file per subject containing sheets for each category 
%%

%{
potential problems with replacing files: image dataframe
wont replace so if we want to update, have to delete prior file somehow.
likely nonissue
%}

function cal_attend_obj_similarity(subexpID, resNet_path, output_directory, vargin)
    warning('off', 'MATLAB:xlswrite:AddSheet') ;
    parallel.gpu.enableCUDAForwardCompatibility(true);
    
    %optional arguments validation
    if isempty(vargin)
        args = struct();
    else
        args = vargin(1);
    end

    %initialize input arguments
    sub_list = cIDs(subexpID);
    numel_sub_list = numel(sub_list);            
    net = get_resnet(resNet_path);
    num_objs = get_num_obj(sub2exp(sub_list(1)));
    objs = 1:num_objs;
    
    %progress display
    f = waitbar(0,sprintf('subjects to complete: %d', numel_sub_list),'Name','calculating subject-object level sim...');
    finished_sub_count = 0;

    %iterate through each subject
    for i = 1:numel_sub_list 
        sub = sub_list(i);            

        %subject level progress bar
        ff = waitbar(0,sprintf('subject%d: 0/%d',sub,num_objs),'Name','calculating image sim...');

        %get dir names and check if subject has a cropped img folder
        subject_directory = get_subject_dir(sub);
        cam_directory = fullfile(subject_directory,"cam07_attended-objs-frames_p");
        if ~exist(cam_directory,'dir') 
            fprintf("subject %d is missing cropped frames directory, skipping subject\n", sub)
            continue
        end
        within_directory_name = sprintf('%d_Within_Obj_Comparisons',sub);

        %check if image_dataframe_path exists, then load dataframe
        image_dataframe_directory = fullfile(subject_directory,'extra_p');
        image_dataframe_name = sprintf('%d_child_attended-objs-frames_image_scores.mat',sub);
        image_dataframe_path = fullfile(image_dataframe_directory,image_dataframe_name);
        if ~exist(image_dataframe_path,"file")
            waitbar(0, ff, 'getting image scores')
            compute_image_score(sub,net)
            waitbar(0, ff, 'image scores done')
        end
        load(image_dataframe_path,"dir_df")

        %output to cam_directory of each subject in multiwork, rather than aggregate folder from input parameter
        if isfield(args, 'output_to_attended_obj_folder') && args.output_to_attended_obj_folder
            output_directory = cam_directory;
        end

        %do across calculations
        if ~isfield(args, 'skip_across') || ~args.skip_across
        
            %define output filename
            output_filename = sprintf('%d_child_attended-allobjs-frames_image_similarity.csv', sub_list(i));
            output_filename = fullfile(output_directory, output_filename);

            %prepare arguments to run comparison
            img_list = dir_df;

            % runs the actual comparison
            img_sim = cal_embed_similarity(img_list);

            %write comparison results to csv
            writetable(img_sim,output_filename);       
        end
        
        %do within calculations
        if ~isfield(args, 'skip_within') || ~args.skip_within          
            for j = objs %iterate through each object
                cat_mask = dir_df{:,"obj_id"} == objs(j);

                %define output filename 
                output_filename = sprintf('%d_child_attended-obj%d-frames_image_similarity.csv', sub_list(i), objs(j)); %for multiple csvs per obj
                % output_filename = sprintf('%d_child_attended-within-obj-frames_image_similarity.xlsx', sub_list(i)); % for 1 file many sheets
                within_directory_path = fullfile(output_directory,within_directory_name);
                if ~exist(within_directory_path,"dir")            
                    mkdir(within_directory_path)
                end
                output_filename = fullfile(output_directory,within_directory_name, output_filename);

                % %write empty sheet if no obj instances
                % if sum(cat_mask,'all') == 0
                %     writetable(table.empty,output_filename,'Sheet',"obj"+j);
                %     continue
                % end

                %write empty csv if no obj instances
                if sum(cat_mask,'all') == 0
                    writematrix([],output_filename);
                    continue
                end

                %prepare arguments to run comparison
                cat_df = dir_df(cat_mask,:);
                img_list = cat_df;

                %runs the actual comparison
                img_sim = cal_embed_similarity(img_list);

                %write comparison results to csv
                writetable(img_sim,output_filename)
                % writetable(img_sim,output_filename,'Sheet',"obj"+j,'AutoFitWidth',0,'PreserveFormat',false); % write table to sheets

                %update per subject progress bar
                waitbar(j/num_objs, ff, sprintf('subject%d obj%d: %d/%d',sub,j,j,num_objs))
            end
        end
        
        %delete per subject progress bar
        delete(ff) 
        
        %update per experiment progress bar
        finished_sub_count = finished_sub_count + 1;
        waitbar_message = sprintf('subjects completed: %d/%d',finished_sub_count,numel(sub_list));
        waitbar(finished_sub_count / numel(sub_list), f, waitbar_message)
        
        %print subject once finished
        fprintf("subject %d finished\n", sub)
    end
    
    delete(f) %delete per experiment progress bar
end

function csv = cal_embed_similarity(img_list) 
    %vectorized pairwise
    Y = img_list.image_embedding;
    X = vertcat(Y{:});
    data = pdist2(X,X);
    roundn = @(x,n) round(x*10^n)./10^n;
    data = roundn(data,2); %round to 2 decimals
  
    % %add image identifier to output
    % id_df = img_list.image_identifier;
    % csv = horzcat(id_df,data);
    % csv = vertcat([nan id_df'],csv);

    %add frame name labels to output
    csv = array2table(data,'VariableNames',img_list.frame_name);
    csv = addvars(csv, img_list.frame_name, 'Before', 1);
    csv = renamevars(csv,"Var1","frame_name");
end