%% 
% Takes in a camera directory and outputs a table of all image frames 
% located in category subfolders under that directory
%
% Author: Elton Martinez
% Modifier: Elton Martinez
% Last modified: 8/22/2025
%
% Parameters:
% - subexpID
%   integer array of subjects or an exp number
% Output: 
%   outputs table with variables: 
%       frame_name(string), name of image file
%       category_folder_name(string), name of folder containing image file
%       obj_id(double), object/category number
%       frame_id(double), frame number
%       image_embedding(gpuArray single), vector representation of image
%       image_identifier(double), object number and frame number represented as one number
%%

function compute_image_embed(subexpID)
    subs = cIDs(subexpID);
    expID = sub2exp(subs(1));

    net = get_resnet(expID);

    if isempty(net)
        return 
    end

    % compute embedding list 
    for sub = subs'
        subject_directory = get_subject_dir(sub);
        cam_directory = fullfile(subject_directory,'cam07_attended-objs-frames_p');
        
        output_directory = fullfile(subject_directory,'extra_p');
        output_filename = sprintf('%d_child_attended-objs-frames_image_scores.mat',sub);
        output_filename = fullfile(output_directory,output_filename);
        
        if exist(output_filename,"file")
            fprintf('skipped subject %d, already has file\n',sub)
            continue
        end
        
        % actually find the embedding 
        fprintf('\nProcessing: %d\n', sub);
        tic
        dir_df = compute_image_embed_helper(cam_directory,net);
        toc
        
        % save as .mat file in the extra_p
        save(output_filename, 'dir_df');
        fprintf('Saved: %s\n', output_filename)

    end
end

function image_embed_df = compute_image_embed_helper(in_dir,net) 
    parallel.gpu.enableCUDAForwardCompatibility(true);
    
    image_embed_df = table(); % initialize eventual output

    upper_dir = dir(in_dir);
    upper_dir = {upper_dir([upper_dir.isdir]).name}; % only get folders
    upper_dir = upper_dir(~ismember(upper_dir ,{'.','..'})); %remove '.' and '..' folders
    if isempty(upper_dir)
        error("subfolders in cam directory don't exist, stopping calculation")
    end

    for lower_dir_index = 1:numel(upper_dir)
        lower_dir_name = upper_dir(lower_dir_index);
        lower_dir_path = fullfile(in_dir,lower_dir_name);

        directory = dir(lower_dir_path{1}); % directory = lower_dir contents
        directory = {directory(~[directory.isdir]).name}; % only get non-folders
        directory = directory(~ismember(directory, {'Thumbs.db'})); %remove Thumbs.db
        
        % skip empty category folders
        if isempty(directory)
            continue
        end

        directory = directory'; % turn into vert array, because code below doesnt work with horiz
        
        % takes in cam_directory and outputs table with: frame names, category folder names, obj id, frame id, img emb        
        %frame_name
        dir_df = cell2table(directory, 'VariableNames',{'frame_name'});    
        
        %category_folder_name
        dir_df.('category_folder_name') = dir_df.("frame_name");
        dir_df.('category_folder_name') = arrayfun(@(x) (lower_dir_name),dir_df{:,'category_folder_name'});
        
        %rownames = image_fullfilepath
        dir_df.Properties.RowNames = arrayfun(@(x) (fullfile(lower_dir_path,x)),dir_df{:,'frame_name'});

        %obj_id
        dir_split = cellfun(@(x) split(x, "_"), dir_df.('category_folder_name'), 'UniformOutput', false);
        obj_df = cell2table(horzcat(dir_split{:})');
        dir_df.('obj_id') = cellfun(@(x) (str2double(x)), obj_df{:,2});

        %frame_id
        dir_split = cellfun(@(x) split(x, "."), dir_df.('frame_name'), 'UniformOutput', false);
        name_df = cell2table(horzcat(dir_split{:})');
        frame_num_df = name_df{:,1};
        dir_split = cellfun(@(x) split(x, "_"), frame_num_df, 'UniformOutput', false);
        name_df = cell2table(horzcat(dir_split{:})');
        dir_df.('frame_id') = cellfun(@(x) (str2double(x)), name_df{:,end});      

        %image_embedding
        dir_df.('image_embedding') = cellfun(@(x) (get_image_embed(x,net)), dir_df.Row, 'UniformOutput', false);
        dir_df.image_embedding = cellfun(@(x) (gather(x)), dir_df.image_embedding, 'UniformOutput', false); %turn gpuarray into cpu because can't directly write gpuarray objects


        %concatenate table for each object
        image_embed_df = [image_embed_df;dir_df]; %#ok<AGROW>
    end
    image_embed_df = sortrows(image_embed_df, {'frame_id'},'ascend'); %sort only by frame num
end

% given an image path and resnet find its embedding 
function embedding = get_image_embed(image_path, net)
    inputSize = net.Layers(1).InputSize;
    I = imread(image_path);
    I = single(imresize(I,inputSize(1:2)));
    I = gpuArray(I);
    embedding = predict(net, I);
end