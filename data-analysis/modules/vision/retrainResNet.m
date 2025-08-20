%% 
% Author: Elton Martinez
% Modifier: Eric Zhao
% last modified: 6/30/2025
% 
% This function trains a resnet model to categorize the objects under
% cam0N_attended-objs-frames_p. Where the folder above has N folders for
% each object.
% 
% Input Parameters:
% - subexpID
%      array, list of subjects
% - output_filename
%     string, name of the output mat object 
% - epochs
%     integer, how many data passes do you want to train for

function retrainResNet(subexpID, output_filename, epochs)
    
    % gather subject path data
    subjects = cIDs(subexpID);
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
    nNinetyPercent = round(0.9*nFiles);
    train_indices = RandIndices(1:nNinetyPercent);
    test_indices = RandIndices(nNinetyPercent+1:end);

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
        ValidationFrequency=50, ... %default value=5, larger values to not slow down training in large datasets
        Plots="training-progress", ...
        Metrics="accuracy", ...  
        Verbose=true, ...
        MaxEpochs=epochs);
    
    % train 
    net = trainnet(augimdsTrain,net,"crossentropy",options);
    save(output_filename, "net");
end