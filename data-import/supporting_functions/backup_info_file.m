% saves the current _info txt file to an archive in extra_p
function success = backup_info_file(subID, varargin)
    args = set_optional_args(varargin,{'sub_dir'},{''});
    
    if isempty(args.sub_dir)
       sub_dir = get_subject_dir(subID);
    else
        sub_dir = args.sub_dir;
    end

    cl = datetime('now','Format','yyyy-MM-dd');
    backupfolder = fullfile(sub_dir, 'extra_p', sprintf('archive_%d-%d-%d', cl.Month, cl.Day, cl.Year));
    varfn = dir(sprintf('%s/*_info.txt',sub_dir));
    
    if ~isempty(varfn)
        if ~isfolder(backupfolder)
            mkdir(backupfolder);
        end
        fname = varfn.name;
        fnam = fname(1:end-4);
        info_file_path = fullfile(sub_dir, fname);

        to_save = fullfile(backupfolder,[fnam '_manual.txt']);
        i = 1;
        while isfile(to_save)
            to_save = fullfile(backupfolder, sprintf('%s_manual-%d.txt', fnam, i));
            i = i + 1;
        end
        fprintf('saving file:\n %s\n', to_save);
        copyfile(info_file_path, to_save);

        success = true;
    else
        success = false;
    end
end
