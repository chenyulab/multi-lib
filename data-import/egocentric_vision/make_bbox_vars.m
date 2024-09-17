function make_bbox_vars(subexpIDs)

subs = cIDs(subexpIDs);
agents = {'child','parent'};

for s = 1:length(subs)
    for a = 1:length(agents)
        flag = agents{a};
        try
            % make bbox
            make_bbox_struct(subs(s),flag,0)
            % make obj size vars
            box2size(subs(s),flag,0);
            % make obj distance vars
            box2dist(subs(s),flag,0);
        catch ME
            fprintf('unable to generate %s data for %d\n',flag,subs(s));
            disp(ME.message);
        end
    end
end
end