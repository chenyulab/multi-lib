%% 
% Returns a initialized attend-objs resnet without the last layer for the 
% target experiment. If .mat file is not found returns an empty array
%
% Author: Elton Martinez
% Modifier: Elton Martinez
% Last modified: 8/22/2025
%%

function net = get_attend_objs_resnet(expID)
    resnet_path = fullfile(get_multidir_root(), sprintf('experiment_%d',expID),'resnet_attend_objs.mat');

    if isfile(resnet_path)
        fprintf("loading resnet: %s\n", resnet_path) %display net name
        x = load(resnet_path);
        net = x.net;
        net = removeLayers(net, "fc1000_softmax");
        net = initialize(net);
        fprintf("  finished\n")
    else
        fprintf('No resnet model found for exp %d\n', expID)
        net = [];
    end
end