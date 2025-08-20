%% 
% Author: Elton Martinez
% Modifier: Eric Zhao
% Last modified: 8/8/2025
%
% Takes in a camera directory and outputs a table of all image frames 
% located in category subfolders under that directory
%
% Input parameters:
% - subexpID
%   integer array of subjects or an exp number
% - net
%   the initialized resnet or the resnet path
% - in_dir
%   path of directory, where directory contains subfolders(cam directory)
%   files within subfolders should be formatted with frame number after an underscore and before the file extension 
%   e.g. for frame 12, 'image_12.jpg' or 'anything_1234_12.ext'    
%
% Output: 
%   outputs table with variables: 
%   frame_name(string), name of image file
%   category_folder_name(string), name of folder containing image file
%   obj_id(double), object/category number
%   frame_id(double), frame number
%   image_embedding(gpuArray single), vector representation of image
%   image_identifier(double), object number and frame number represented as one number
%%

%maybe have an input parameter to specify if want for cam directory or just category directory
function compute_image_embed_cID(subexpID,net)
    sub_list = cIDs(subexpID);
    
    %if inputted path to net instead of initialized net
    if ischar(net) || isstring(net) || iscellstr(net)
        net = get_resnet(net);
    end

    for sub = sub_list'
        subject_directory = get_subject_dir(sub);
        cam_directory = fullfile(subject_directory,'cam07_attended-objs-frames_p');
        
        output_directory = fullfile(subject_directory,'extra_p');
        % output_directory = "Z:\EricZ\Obj Similarity\data\subject_dataframes"; %testline
        output_filename = sprintf('%d_child_attended-objs-frames_image_scores.mat',sub);
        output_filename = fullfile(output_directory,output_filename);
        
        if exist(output_filename,"file")
            fprintf('skipped subject %d, already has file\n',sub)
            continue
        end

        dir_df = compute_image_embed(cam_directory,net);
        
        save(output_filename, 'dir_df');

    end
end

function image_embed_df = compute_image_embed(in_dir,net) 
    parallel.gpu.enableCUDAForwardCompatibility(true);
    
    % in_dir = 'M:\experiment_351\included\__20240921_10118\cam07_attended-objs-frames_p'; %testline
    % in_dir = 'M:\experiment_351\included\__20230214_10055\cam07_attended-objs-frames_p'; %testline
    % in_dir = 'M:\experiment_91\included\__20161130_9101\cam07_attended-objs-frames_p'; %testline
    
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
        
        %% OLD: requires files formatted as 'obj_{obj_id}_{frame_id}.jpg' e.g. 'obj_1_1.jpg'
        % dir_split = cellfun(@(x) split(x, "_"), directory, 'UniformOutput', false);
        % % dir_df = dir_split; %debugline
        % dir_df = cell2table(horzcat(dir_split{:})');
        % num_ext = cellfun(@(x) split(x, "."), dir_df{:,3}, 'UniformOutput', false);
        % num_ext = horzcat(num_ext{:})';
        % dir_df.("frame_id") = num_ext(:,1);
        % dir_df.("frame_name") = directory;
        % dir_df = removevars(dir_df,{'Var1','Var3'});
        % dir_df = renamevars(dir_df,"Var2","obj_id");
        % 
        % % dir_df.("frame_name") = fullfile(dir_df{:,"frame_id"},dir_df{:,"frame_name"});
        % dir_df.('obj_id') = arrayfun(@(x) str2double(x{1}), dir_df{:,'obj_id'});
        % dir_df.('frame_id') = arrayfun(@(x) str2double(x{1}), dir_df{:,'frame_id'});
        % dir_df = sortrows(dir_df, {'obj_id','frame_id'},{'ascend'});
        % full_dir_df = [full_dir_df;dir_df];
        
        %% NEW: takes in cam_directory and outputs table with: frame names, category folder names, obj id, frame id, img emb        
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

        % %image_identifier
        % decimal_df = floor(log10(dir_df.frame_id)) + 1;
        % decimal_df = dir_df.frame_id ./ 10 .^ decimal_df;
        % dir_df.('image_identifier') = dir_df.obj_id + decimal_df;

        %concatenate table for each object
        image_embed_df = [image_embed_df;dir_df]; %#ok<AGROW>
    end
    % full_dir_df = sortrows(full_dir_df, {'obj_id','frame_id'},'ascend'); %sort by objects then frame num
    image_embed_df = sortrows(image_embed_df, {'frame_id'},'ascend'); %sort only by frame num
end

function embedding = get_image_embed(I, net)
    inputSize = net.Layers(1).InputSize;
    I = imread(I);
    I = single(imresize(I,inputSize(1:2)));
    I = gpuArray(I);
    embedding = predict(net, I);
end