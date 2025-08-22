%%
% This function trains a resnet model to categorize the objects under
% cam0N_attended-objs-frames_p. Where the folder above has N folders for
% each object. You need this
% https://www.mathworks.com/matlabcentral/fileexchange/64626-deep-learning-toolbox-model-for-resnet-50-network,
% along with the prerequisites of the project
% 
% Author: Elton Martinez
% Modifier: Elton Martinez
% last modified: 8/22/2025
% 
% Input Parameters:
% - subexpID
%      array, list of subjects
% - output_filename
%     string, name of the output mat object 
% - epochs
%     integer, how many data passes do you want to train for

function train_resnet(subexpID, varargin)
    parallel.gpu.enableCUDAForwardCompatibility(true)
    args = set_optional_args(varargin,["epochs","split","val_patience"],{1,0.9,10});
    
    % gather subject & experiment path data
    subjects = cIDs(subexpID);
    expID = sub2exp(subjects(1));
    output_filename = fullfile(get_multidir_root(), sprintf('experiment_%d',expID),'resnet_attend_objs.mat');

    Folder = strings(numel(subjects),1);

    for i = 1:numel(subjects)
        Folder(i) = fullfile(get_subject_dir(subjects(i)),'cam07_attended-objs-frames_p');
    end
    
    % turn folders into data store 
    disp("Loading data")
    imds = imageDatastore(Folder,IncludeSubFolders=true,LabelSource="foldernames");
    disp("Finished Loading data")
    
    % partition into training and testing sets 
    nFiles = length(imds.Files);
    RandIndices = randperm(nFiles);
    nNPercent = round(args.split*nFiles);
    train_indices = RandIndices(1:nNPercent);
    test_indices = RandIndices(nNPercent+1:end);

    imdsTrain = subset(imds, train_indices);
    imdsTest = subset(imds, test_indices);
    
    % get constants for training
    classNames = categories(unique(imds.Labels));
    numClasses = numel(classNames);
    
    net = imagePretrainedNetwork("resnet50", NumClasses=numClasses);
    inputSize = net.Layers(1).InputSize;
    
    pixelRange = [-30 30];
    
    % transform images into the format resNet expects 
    imageAugmenter = imageDataAugmenter( ...
        RandXReflection=true, ...
        RandXTranslation=pixelRange, ...
        RandYTranslation=pixelRange);
    
    % Define augmented datastore
    augimdsTrain = augmentedImageDatastore(inputSize(1:2),imdsTrain,DataAugmentation=imageAugmenter);
    augimdsTest = augmentedImageDatastore(inputSize(1:2),imdsTest);
    
    % training options 
    options = trainingOptions("adam", ...
        InitialLearnRate=0.001, ...
        ValidationData=augimdsTest, ...
        ValidationFrequency=50, ... 
        ValidationPatience=args.val_patience,...
        Plots="training-progress", ...
        Metrics="accuracy", ...  
        Verbose=true, ...
        MaxEpochs=args.epochs);
    
    % train 
    disp("Starting Training..")
    tic
    net = trainnet(augimdsTrain,net,"crossentropy",options);
    save(output_filename, "net");
    toc
end