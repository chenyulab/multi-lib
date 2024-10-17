function make_bbox_vars(subexpIDs,is_face)

subs = cIDs(subexpIDs);
agents = {'child','parent'};

for s = 1:length(subs)
    for a = 1:length(agents)
        flag = agents{a};
        try
            % make bbox
            make_bbox_struct(subs(s),flag,is_face)
            % make obj size vars
            box2size(subs(s),flag,is_face);
            % make obj distance vars
            box2dist(subs(s),flag,is_face);
            % make obj to gaze vars
            box2dist_eyegaze(subs(s), flag, is_face);
        catch ME
            fprintf('unable to generate %s data for %d\n',flag,subs(s));
            disp(ME.message);
        end
    end
end
end