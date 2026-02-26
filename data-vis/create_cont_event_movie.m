% visualize an event continuously by drawing a green border around the frames that are within the event
%
% to get a thicker border pass args as last parameter
% args.thickness = 10
% create_cont_event_movie(subsexpID, event, camID, outpath, args)
%
% example call
% create_cont_event_movie(7010, 'event_motion_pos_right-hand_resting_child', 7, 'output')

function create_cont_event_movie(subsexpID, event, camID, outpath, varargin)
args = set_optional_args(varargin,{'thickness'},{2});

req_vars = {event, 'cevent_trials'};
thickness = args.thickness;
color = [0 255 0];
rate = 1/30;

[rsubs,~,rsubDirs] = cIDs(subsexpID,false);
mask = arrayfun(@(x) has_all_variables(x, req_vars), rsubs);

subs = rsubs(mask);
subDirs = rsubDirs(mask);

[fsz, camDirs] = get_frame_sz(subs,subDirs,camID);
numSubs = height(subs);

for s = 1:numSubs
    try
    subID = subs(s);
    isEmpty = isempty(dir(camDirs{s})) || numel(dir(camDirs{s})) <= 2;

    if isEmpty
        fprintf('[SKIPPING] subID %d  \n%s is empty\n', subID, camDirs{s})
        continue
    end

    vevent = get_variable(subID, req_vars{1});
    trials = get_variable(subID, req_vars{2});

    cevent = zeros(height(vevent),3);
    cevent(:,1:2) = vevent(:,1:2);
    cevent(:,3) = 1;

    rsevent = cevent2cstream(cevent, trials(1,1), rate);
    sevent = extract_ranges(rsevent, 'cont', trials(:,1:2));
    sevent = vertcat(sevent{:});

    frames = time2frame_num(sevent(:,1), subID);
    numFrames = height(frames);

    % write video
    out_name = sprintf('%d_%s',subID,event);
    out_pname = fullfile(outpath, out_name);
    
    v = VideoWriter(out_pname, "MPEG-4");
    v.Quality = 50;
    open(v)

    fprintf("[%d/%d WRITTING FRAMES] %d\n",s,numSubs, subID)
    bar = waitbar(0,'1','Name','writting..');
    
    for f = 1:numFrames
        fid = frames(f,1);
        imn = sprintf('img_%d.jpg',fid);
        imp = fullfile(camDirs{s}, imn);
        RGB = imread(imp);
        

        if sevent(f,2) == 1
            RGB = drawBorder(RGB, thickness, color, fsz);
        end

        writeVideo(v, RGB);
        waitbar(f/numFrames, bar, sprintf('frame %d/%d',f,numFrames))
    end

    close(v);
    disp("------")
    close(bar)

    catch ME
       disp(ME.message)
        close(bar);
        close(v);
    
    end
end

% copilot <3
function J = drawBorder(I, thickness, color, isz)
h = isz(2);
w = isz(1);

% Clamp thickness so it fits image
t = min([thickness, floor(h/2), floor(w/2)]);

% Create output and paint borders
J = I;
% top
J(1:t, :, 1) = color(1);  % R
J(1:t, :, 2) = color(2);  % G
J(1:t, :, 3) = color(3);  % B
% bottom
J(end-t+1:end, :, 1) = color(1);
J(end-t+1:end, :, 2) = color(2);
J(end-t+1:end, :, 3) = color(3);
% left
J(:, 1:t, 1) = color(1);
J(:, 1:t, 2) = color(2);
J(:, 1:t, 3) = color(3);
% right
J(:, end-t+1:end, 1) = color(1);
J(:, end-t+1:end, 2) = color(2);
J(:, end-t+1:end, 3) = color(3);
%byton