function create_dom_vars(subexpIDs, rel_prop, threshold, obj_list, max_threshold)

subs = subexpIDs;

person = {'child' 'parent'};
if ~exist('obj_list', 'var') || isempty(obj_list)
    obj = {'obj1', 'obj2', 'obj3'};
else
    obj = {};
    for j = obj_list
        obj{j} = sprintf('obj%d',j);
    end
end

for p = 1 : numel(person)
    for o = 1 : numel(obj)
        names{o} = ['cont_vision_size_' obj{o} '_' person{p}];
    end
    for s = 1 : numel(subs)
        vars = cellfun(@(a) get_variable(subs(s), a), names, 'un', 0);
        for t = 1 : numel(threshold)
            for r = 1:numel(rel_prop)
                if exist('max_threshold', 'var')
                    z = cont_dominant(vars, rel_prop(r), threshold(t), max_threshold);
                else
                    z = cont_dominant(vars, rel_prop(r), threshold(t));
                end
                cevent_dom = cstream2cevent(z);
                if isempty(cevent_dom)
                    continue
                end
                cevent_dom = cevent_merge_segments(cevent_dom, 0.31,unique(cevent_dom(:,3))');
                cevent_dom = cevent_remove_small_segments(cevent_dom, 0.11);
                %                 cevent_dom = cevent_merge_segments(cevent_dom, 0.31);
                %             cevent_dom = cleanup_dom(cevent_dom);
                if threshold(t) == 5
                    if rel_prop(r) == 2/3
                        record_variable(subs(s), sprintf('%s_%s', 'cevent_vision_size_obj-dominant-2x',...
                            person{p}), cevent_dom);
                        record_variable(subs(s), sprintf('%s_%s', 'cstream_vision_size_obj-dominant-2x',...
                            person{p}),z);
                    elseif rel_prop(r) == 1/2
                        record_variable(subs(s), sprintf('%s_%s', 'cevent_vision_size_obj-dominant',...
                            person{p}), cevent_dom);
                        record_variable(subs(s), sprintf('%s_%s', 'cstream_vision_size_obj-dominant',...
                            person{p}),z);
                    end
                elseif threshold(t) == 3
                    if rel_prop(r) == 2/3
                        record_variable(subs(s), sprintf('%s_%s', 'cevent_vision_size_obj-big-2x',...
                            person{p}), cevent_dom);
                        record_variable(subs(s), sprintf('%s_%s', 'cstream_vision_size_obj-big-2x',...
                            person{p}),z);
                    elseif rel_prop(r) == 1/2
                        record_variable(subs(s), sprintf('%s_%s', 'cevent_vision_size_obj-big',...
                            person{p}), cevent_dom);
                        record_variable(subs(s), sprintf('%s_%s', 'cstream_vision_size_obj-big',...
                            person{p}),z);
                    end
                end
            end
            
        end
    end
end


    function cevent = cleanup_dom(var)
        cevent_size = size(var, 1);
        cevent = cevent_merge_segments(var, 0.21, unique(var(:,3))');
        merge_size = size(cevent, 1);
        while cevent_size ~= merge_size
            cevent = cevent_merge_segments(cevent, 0.21, unique(cevent(:,3))');
            cevent_size = merge_size;
            merge_size = size(cevent, 1);
            fprintf('cevent is %d and merge is %d\n', cevent_size, merge_size);
        end
        
        
        %filter out small duration events
        dur = cevent(:,2) - cevent(:,1);
        cevent(dur < .15, :) = [];
        cevent = cevent_merge_segments(cevent, 0.21, unique(cevent(:,3))');
    end


    function has = has_all_vars(variables, subject_id)
        % returns true if the subject has all of the requested variables available
        
        has = [];
        for i = 1:length(variables)
            has(i) = has_variable(subject_id, variables{i});
        end
        has = prod(has) > 0;
        
    end
end