subs = cIDs([72]);

min_dur = 0.25;
merge_dur = 0.5;
mkdir('demo_manip_cevent');
for s = 1:numel(subs)
     subid = subs(s);
     cat_list = [1:get_num_obj(subid)+1];
     % check that variables exist
     if has_all_variables(subid, {'cevent_eye_roi_child', 'cevent_eye_roi_parent'})
         
         % load cevents
         child_eye_orig = get_variable(subid, 'cevent_eye_roi_child');
         parent_eye_orig = get_variable(subid, 'cevent_eye_roi_parent');
         
         % only consider toy looks
         child_eye = cevent_category_equals(child_eye_orig, [1 2 3]);
         parent_eye = cevent_category_equals(parent_eye_orig, [1 2 3]);
         
         % merge over small gaps
         child_eye = cevent_merge_segments(child_eye, merge_dur,cat_list);
         parent_eye = cevent_merge_segments(parent_eye, merge_dur,cat_list);
         
         % remove short events
         child_eye = cevent_remove_small_segments(child_eye, min_dur);
         parent_eye = cevent_remove_small_segments(parent_eye, min_dur);
         
         % merge again, now that new gaps may have appeared
         child_eye = cevent_merge_segments(child_eye, merge_dur,cat_list);
         parent_eye = cevent_merge_segments(parent_eye, merge_dur,cat_list);
         
         JA = cevent_shared(child_eye, parent_eye);
         
         % view new JA with original eye streams and save image to folder
         vis_streams_data({child_eye_orig, parent_eye_orig, JA}, [], {'ceye', 'peye', 'ja'});
         export_fig(sprintf('/multi-lib/user_output/demo_manip_cevent/%d.png', subid));
         close(gcf);
         
     end
end