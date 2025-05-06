function make_inhand_activity(subexpIDs)
subs = cIDs(subexpIDs);
agents = {'child', 'parent'};
hands = {'left', 'right'};
for s = 1:numel(subs)
    timebase = get_variable(subs(s), 'cstream_trials');
    for a = 1:numel(agents)
        agent = agents{a};
        for h = 1:2
            hand = hands{h};
            if has_variable(subs(s), sprintf('cont_motion_pos-speed_%s-hand_%s', hand, agent))
                sub = subs(s);
                gt = get_trial_times(sub);
                data = get_variable(sub, sprintf('cont_motion_pos-speed_%s-hand_%s', hand, agent));
                param.threshold = 150;
                param.flag = 'above';
                active = cont2event(data, param);
                active(:,3) = 1;
                active = cevent_merge_segments(active, 0.5,unique(active(:,3))');
                log = active(:,2)- active(:,1) < 0.5;
                active(log,:) = [];
                active = active(:,[1 2]);
                record_variable(sub, sprintf('event_motion_pos_%s-hand_active_%s', hand, agent), active);
                
                param.threshold = 50;
                passive = cont2event(data, param);
                passive(:,3) = 1;
                passive = cevent_merge_segments(passive, 0.5, unique(passive(:,3))');
                active_not = event_NOT(active, [gt(1) gt(end)]);
                passive = extract_ranges(passive, 'event', active_not);
                passive = vertcat(passive{:});
                passive = sortrows(passive, [1 2]);
                log = passive(:,2) - passive(:,1) < 0.5;
                passive(log,:) = [];
                passive = passive(:,[1 2]);
                record_variable(sub, sprintf('event_motion_pos_%s-hand_passive_%s', hand, agent), passive);
                
                resting = event_NOT(passive, [gt(1) gt(end)]);
                resting = event_AND(resting, active_not);
                
                record_variable(sub, sprintf('event_motion_pos_%s-hand_resting_%s', hand, agent), resting);
                
                inhand = get_variable(sub, sprintf('cstream_inhand_%s-hand_obj-all_%s', hand, agent));
                
                cev = cstream2cevent(inhand);
                inhand = cevent2cstreamtb(cev, timebase);
%                 cevinhand = cstream2cevent(inhand);
%                 cevinhand = cevent_merge_segments(cevinhand, 0.1);
%                 log = cevinhand(:,2) - cevinhand(:,1) < 0.1;
%                 cevinhand(log,:) = [];
%                 cevinhand = cevent_merge_segments(cevinhand, 0.1);
%                 inhand = cevent2cstreamtb(cevinhand, inhand);
                activity_inhand = inhand;
                active_inhand = inhand;
                passive_inhand = inhand;
                resting_inhand = inhand;
                
                log = inhand(:,2) > 0;
                log1 = mark_ranges(activity_inhand, active) & log;
                log2 = mark_ranges(activity_inhand, passive) & log;
                log3 = mark_ranges(activity_inhand, resting) & log;
                
                activity_inhand(log1,2) = 3; % active
                activity_inhand(log2,2) = 2; % passive
                activity_inhand(log3,2) = 1; % resting
                
                record_variable(sub, sprintf('cstream_motion-inhand_%s-hand_all_%s', hand, agent), activity_inhand);
%                 cev = cstream2cevent(activity_inhand);
%                 record_variable(sub, sprintf('cevent_motion-inhand_%s-hand_all_%s', hand, agent), cev);
                
                log = mark_ranges(active_inhand, active);
                active_inhand(~log, 2) = 0;
                
                log = mark_ranges(passive_inhand, passive);
                passive_inhand(~log, 2) = 0;
                log = mark_ranges(resting_inhand, resting);
                resting_inhand(~log, 2) = 0;
                
                record_variable(sub, sprintf('cstream_motion-inhand_%s-hand_active_%s', hand, agent), active_inhand);
%                 cev = cstream2cevent(active_inhand);
%                 record_variable(sub, sprintf('cevent_motion-inhand_%s-hand_active_%s', hand, agent), cev);
                
                record_variable(sub, sprintf('cstream_motion-inhand_%s-hand_passive_%s', hand, agent), passive_inhand);
%                 cev = cstream2cevent(passive_inhand);
%                 record_variable(sub, sprintf('cevent_motion-inhand_%s-hand_passive_%s', hand, agent), cev);
                
                record_variable(sub, sprintf('cstream_motion-inhand_%s-hand_resting_%s', hand, agent), resting_inhand);
%                 cev = cstream2cevent(resting_inhand);
%                 record_variable(sub, sprintf('cevent_motion-inhand_%s-hand_resting_%s', hand, agent), cev);
 
            end        
        end
    end
end


for s = 1:numel(subs)
    sub = subs(s);
    timebase = get_variable(sub, 'cstream_trials');
    for a = 1:2
        agent = agents{a};
        dl = get_variable(sub, sprintf('cstream_motion-inhand_left-hand_all_%s', agent), 1);
        dr = get_variable(sub, sprintf('cstream_motion-inhand_right-hand_all_%s', agent), 1);
        hl = get_variable(sub, sprintf('cstream_inhand_left-hand_obj-all_%s', agent), 1);
        cev = cstream2cevent(hl);
        hl = cevent2cstreamtb(cev, timebase);
        hr = get_variable(sub, sprintf('cstream_inhand_right-hand_obj-all_%s', agent), 1);
        cev = cstream2cevent(hr);
        hr = cevent2cstreamtb(cev, timebase);
        if ~isempty(dl) && ~isempty(dr)
            both = cat(2, dl(:,2), dr(:,2));
            objid = cat(2, hl(:,2), hr(:,2));
            [maxact, idx] = max(both, [], 2);
            log = idx == 2;
            targobj = zeros(length(log),1);
            mapping = targobj;
            targobj(log) = objid(log,2);
            log = idx == 1;
            targobj(log) = objid(log, 1);
            log = maxact > 0 & targobj > 0;
            mapping(log) = sub2ind([3 3], maxact(log), targobj(log));
            cst = cat(2,dl(:,1), mapping);
            cev = cstream2cevent(cst);
            cev = cevent_merge_segments(cev, .1, unique(cev(:,3))');
            log = cev(:,2) - cev(:,1) <.1;
            cev(log,:) = [];
            cev = cevent_merge_segments(cev, .1, unique(cev(:,3))');
            cst = cevent2cstreamtb(cev, timebase);
            record_variable(sub, sprintf('cstream_motion-inhand_either-hand_all_%s', agent), cst);
            record_variable(sub, sprintf('cevent_motion-inhand_either-hand_all_%s', agent), cev);
            
            log = ismember(cev(:,3), [3 6 9]);
            cev = cev(log,:);
            cev(:,3) = cev(:,3) / 3;
            record_variable(sub, sprintf('cevent_motion-inhand_either-hand_active_%s', agent), cev);
            log = ismember(cst(:,2), [3 6 9]);
            cst(~log,2) = 0;
            cst(:,2) = cst(:,2) / 3;
            record_variable(sub, sprintf('cstream_motion-inhand_either-hand_active_%s', agent), cst);
        end
    end
end