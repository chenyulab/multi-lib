function  make_trials_by_child_roi_vyu(subexpIDs)
    numInfoLines = 21;
    subs = cIDs(subexpIDs);

    for i = 1:numel(subs)
        subID = subs(i);
        sub_dir = get_subject_dir(subID);
        %% get new trials
        % read _info file
        info_file_path = get_info_file_path(subID);
        trialInfo = load(info_file_path).trialInfo;
        
        % get new trials and format it 
        trials = cal_trials_by_child_roi_vyu(subID, trialInfo);
        if isnan(trials)
            continue
        end
        newNumTrials = height(trials);
         
        % go from seconds to frame num
        trials(:,[1 2]) = time2frame_num(trials(:,[1,2]),trialInfo);

        % pre allocate new info file 
        newNumInfoLines = numInfoLines + newNumTrials;
        fnew = strings(newNumInfoLines,1);
        %% write new trials 
        % find idx of new trials
        names = dir(sprintf('%s/*_info.txt',sub_dir));
        fname = names(1).name;
        info_name = fullfile(sub_dir,fname);

        f = readlines(info_name);

        emptyIdx = find(strlength(f)==0);
        trialIdx = emptyIdx(1) + 3;
        newTrialIdx = trialIdx : (trialIdx + newNumTrials)-1;

        % populate new __info file
        fnew([1:6 newTrialIdx(end)+1:newNumInfoLines]) ...
            = f([1:6 emptyIdx(2):height(f)]);
        
        for j = 1:newNumTrials
            tj = sprintf('%d,%d,%d',trials(j,3),trials(j,1),trials(j,2));
            fnew(newTrialIdx(j)) = tj;
        end
        
        % back up old _info file 
       args.sub_dir = sub_dir;
       success = backup_info_file(subID, args);

       if ~success
           fprintf('Could not find __info file: Trials were not generated for sub %d\n', subID)
            return
        end
   
        % write new __info
        writelines(fnew, info_name);
        vars = {'cevent_trials','cstream_trials'};
        delete_variables(subID, vars)
        
        % get .mat file from .txt info file
        read_trial_info(subID)
        % use .mat to get cevent/cstream_trials
        make_trials_vars(subID)
    end
end
