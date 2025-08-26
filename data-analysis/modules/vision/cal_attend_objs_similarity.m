%% 
% Author: Elton Martinez
% Modifier: Elton Martinez
% last modified: 8/26/2025
%
% For each subjects the function calculates the unique pairwise similarity within 
% categories.
%
% Parameters:
% - subexpID
%     array, list of subjects or experiment
% Optional arguments:
% - args.method
%     char array, Indicate which computations to do. First ch indicates
%     whether to do the across similarity. Second ch indicates whether to
%     do the within similarity. You can pass a convination such '10', default 
%     behavior is '11'
% - args.replace
%     boolean, If true it will recompute similarities for subjects that
%     already have data. 

% Output: 
%  One csv for across similarty, and N csvs for within object similarity
%  (one for each object)
%%


function cal_attend_objs_similarity(subexpID, varargin)
    parallel.gpu.enableCUDAForwardCompatibility(true);
    % base dir
    base_dir = 'M:/extracted_datasets/event_similarity_matrices/attend_objs';

    %optional arguments validation
    args = set_optional_args(varargin,{'method','replace'},{'11',false});

    %initialize input arguments
    subs = cIDs(subexpID);
    expID = sub2exp(subs(1));

    numel_subs = numel(subs);
    num_objs = get_num_obj(sub2exp(subs(1)));
    objs = 1:num_objs;
    
    % make sure dir exists
    exp_output_dir = fullfile(base_dir, sprintf('exp_%d',expID));
    within_obj_dir = fullfile(exp_output_dir, 'within_objs','eye_child_roi');
    across_obj_dir = fullfile(exp_output_dir, 'across_objs', 'eye_child_roi');

    required_dirs = {exp_output_dir,within_obj_dir,across_obj_dir};
    
    for required_dir  = required_dirs
        if ~isfolder(required_dir{1})
            mkdir(required_dir{1});
        end
    end

    %iterate through each subject
    for i = 1:numel_subs 
        fprintf("\nProcessing %d\n", subs(i))
        sub = subs(i);
        sub_dir = get_subject_dir(sub);

        % get path to embeds cache
        embeds_df_path = fullfile(sub_dir,'extra_p',sprintf('%d_child_attended-objs-frames_image_scores.mat',sub));

        %check if image_dataframe_path exists, then load dataframe
        if ~isfile(embeds_df_path)
            fprintf("Subject %s does not have attend image embeddings, skipping",subID)
        end
        
        embeds_df = load(embeds_df_path).dir_df;
       
         %do across calculations
        if args.method(1) == '1'
            sub_output_dir = fullfile(across_obj_dir, int2str(sub));

            if ~isfolder(sub_output_dir)
                mkdir(sub_output_dir)
            end
        
            %define output filename
            output_filename = fullfile(sub_output_dir,'child_attended-objs_frame-sim.csv');

            if ~isfile(output_filename) && ~args.replace
                % runs the actual comparison
                img_sim = cal_embed_similarity(embeds_df);

                %write comparison results to csv
                writetable(img_sim,output_filename);
                fprintf("Saved: %s\n\n",output_filename);


            else
                fprintf("Already Exists: %s\n\n",output_filename);
            end
        end
        
        %do within calculations
        if args.method(2) == '1'
            sub_output_dir = fullfile(within_obj_dir, int2str(sub));

            if ~isfolder(sub_output_dir)
                mkdir(sub_output_dir)
            end
        
            for j = objs %iterate through each object
                obj_mask = embeds_df{:,"obj_id"} == objs(j);

                %define output filename 
                %for multiple csvs per obj
                output_filename = fullfile(sub_output_dir,  sprintf('child_attended-obj%d-frame_sim.csv', objs(j)));

                %write empty csv if no obj instances
                if sum(obj_mask,'all') == 0
                    writematrix([],output_filename);
                    continue
                end

                %prepare arguments to run comparison
                obj_embeds_df = embeds_df(obj_mask,:);

                if ~isfile(output_filename) && ~args.replace

                    %runs the actual comparison
                    img_sim = cal_embed_similarity(obj_embeds_df);
    
                    %write comparison results to csv
                    writetable(img_sim, output_filename)
                    fprintf("Saved: %s\n",output_filename);
                else
                    fprintf("Already Exists: %s\n\n",output_filename);
                end
            end
            fprintf("\n")
        end
    end
end

function csv = cal_embed_similarity(embeds_df) 
    %vectorized pairwise
    Y = embeds_df.image_embedding;
    X = vertcat(Y{:});
    data = pdist2(X,X);
    roundn = @(x,n) round(x*10^n)./10^n;
    data = roundn(data,2); %round to 2 decimals

    %add frame name labels to output
    csv = array2table(data,'VariableNames',embeds_df.frame_name);
    csv = addvars(csv, embeds_df.frame_name, 'Before', 1);
    csv = renamevars(csv,"Var1","frame_name");
end