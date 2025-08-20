% removes last layer of net and returns initialized net
function net = get_resnet(net_path)
    [~, netname, ext] = fileparts(net_path);
    fprintf("loading resnet:%s%s\n",netname, ext) %display net name
    x = load(net_path);
    net = x.net;
    net = removeLayers(net, "fc1000_softmax");
    net = initialize(net);
    disp("finished")
end