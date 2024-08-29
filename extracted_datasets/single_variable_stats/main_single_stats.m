clear;


c = 3; 

switch c
    case 1 %

        var_list = {'cevent_eye_roi_child', 'cevent_eye_roi_parent'};
        exp_ids = [70 71 72 73 74 75 41 44 12 91 58 353 59 96 77 78 79 351 15 65];
        num_roi = [ 4  4  4  4  4  4  4  4 25 25 27  27 27  7 11 11 11  28 11 19] ;
        num_exp = length(exp_ids);

        for v = 1 : length(var_list)
            for i = 1 : length(exp_ids)
                extract_basic_stats(var_list{v},exp_ids(i), num_roi(i));
            end
        end

    case 2
        var_list = {'cevent_eye_joint-attend_child-lead-enter-type_both','cevent_eye_joint-attend_parent-lead-enter-type_both'};
        exp_ids = [70 71 72 73 74 75 41 44 12 91 58 353 59 96 77 78 79 351 15 65 66];
        num_roi = 6; %  6 pathways to joint attention  
        num_exp = length(exp_ids);

        for v = 1 : length(var_list)
            for i = 1 : length(exp_ids)
                extract_basic_stats(var_list{v},exp_ids(i), num_roi);
            end
        end
    case 3
        exp_ids = [60];
        var_list = {'cevent_pulling_rat1','cevent_pulling_rat2','cevent_call_cluster_accepted'};
        num_roi = [8 8 16];
         for v = 1 : length(var_list)
            for i = 1 : length(exp_ids)
                extract_basic_stats(var_list{v},exp_ids(i), num_roi(v));
            end
        end


end

    
    
     