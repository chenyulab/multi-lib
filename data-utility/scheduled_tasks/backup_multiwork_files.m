function backup_multiwork_files(sourceRoot, destRoot, opts)
    arguments
        sourceRoot (1,:) char
        destRoot   (1,:) char
        opts.extensions cell = {'.txt','.png','.jpg','.csv','.xlsx'}
        opts.overwrite (1,1) logical = true
        opts.dryRun   (1,1) logical = false
        opts.verbose  (1,1) logical = true
    end

    sourceRoot = char(string(sourceRoot)); if sourceRoot(end)==filesep, sourceRoot(end)=[]; end
    destRoot   = char(string(destRoot));   if destRoot(end)==filesep,   destRoot(end)  =[]; end
    if ~isfolder(sourceRoot), error('Source folder does not exist: %s', sourceRoot); end
    if ~opts.dryRun && ~isfolder(destRoot), mkdir(destRoot); end

    tstamp = datestr(now,'yyyy-mm-dd_HHMMSS');
    logFile = fullfile(destRoot, sprintf('backup_log_%s.txt', tstamp));
    if opts.dryRun
        logFID = 1;
    else
        logFID = fopen(logFile, 'w'); if logFID<0, error('Failed to open log file: %s', logFile); end
    end
    cleaner = onCleanup(@() safeClose(logFID, opts));

    exts = lower(string(opts.extensions));
    targetSubfolders = {'stimuli_images','survey_data','MCDI'};

    % Nested logger
    function say(fmt, varargin)
        msg = sprintf(fmt, varargin{:});
        fprintf(logFID, '%s\n', msg);
        if opts.verbose && logFID ~= 1
            fprintf(1, '%s\n', msg);
        end
    end

    say('=== BACKUP START %s ===', datestr(now));
    say('Source: %s', sourceRoot);
    say('Destination: %s', destRoot);
    say('Extensions: %s', strjoin(exts, ', '));
    say('Overwrite: %d  DryRun: %d  Verbose: %d', opts.overwrite, opts.dryRun, opts.verbose);
    say('---');

    % 1) Top-level files (non-recursive)
    say('Step 1: Top-level files in sourceRoot');
    copyMatchesInFolder(sourceRoot, destRoot, exts, opts, @say);  % <-- @say

    % 2) Experiment folders
    say('Step 2: Experiment folders');
    d = dir(sourceRoot);
    childDirs = {d([d.isdir]).name};
    childDirs = childDirs(~ismember(childDirs, {'.','..'}));
    expPat = '^experiment_\d{2,3}$';

    for i = 1:numel(childDirs)
        expName = childDirs{i};
        if ~~regexp(expName, expPat, 'once')
            expSrc = fullfile(sourceRoot, expName);
            expDst = fullfile(destRoot,  expName);
            say('> Found experiment: %s', expName);
            if ~opts.dryRun && ~isfolder(expDst), mkdir(expDst); end

            % 2a) Files in experiment root (non-recursive)
            copyMatchesInFolder(expSrc, expDst, exts, opts, @say);  % <-- @say

            % 2b) Selected subfolders (recursive)
            for s = 1:numel(targetSubfolders)
                subName = targetSubfolders{s};
                subSrc = fullfile(expSrc, subName);
                if isfolder(subSrc)
                    say('  - Including subfolder (recursive): %s', fullfile(expName, subName));
                    subDst = fullfile(expDst, subName);
                    if ~opts.dryRun && ~isfolder(subDst), mkdir(subDst); end
                    copyMatchesRecursive(subSrc, subDst, exts, opts, @say);  % <-- @say
                else
                    say('  - Missing subfolder (skipped): %s', fullfile(expName, subName));
                end
            end
        end
    end

    say('=== BACKUP COMPLETE %s ===', datestr(now));
end

% --------- Helpers ---------

function copyMatchesInFolder(srcFolder, dstFolder, exts, opts, logger)
% Non-recursive copy of matching files in srcFolder to dstFolder
    for k = 1:numel(exts)
        listing = dir(fullfile(srcFolder, ['*' char(exts(k))]));
        for j = 1:numel(listing)
            if listing(j).isdir, continue; end
            src = fullfile(srcFolder, listing(j).name);
            dst = fullfile(dstFolder, listing(j).name);
            doCopy(src, dst, opts, logger);
        end
    end
    % Case-insensitive safety pass
    listingAll = dir(srcFolder);
    for j = 1:numel(listingAll)
        if listingAll(j).isdir, continue; end
        [~,~,e] = fileparts(listingAll(j).name);
        if any(strcmpi(e, exts))
            src = fullfile(srcFolder, listingAll(j).name);
            dst = fullfile(dstFolder, listingAll(j).name);
            doCopy(src, dst, opts, logger);
        end
    end
end

function copyMatchesRecursive(srcFolder, dstFolder, exts, opts, logger)
% Recursive copy within srcFolder, mirroring to dstFolder
    stack = {srcFolder};
    baseLen = length(srcFolder);
    seen = containers.Map('KeyType','char','ValueType','logical');

    while ~isempty(stack)
        curr = stack{end}; stack(end) = [];
        dd = dir(curr);
        for i = 1:numel(dd)
            if dd(i).isdir && ~ismember(dd(i).name, {'.','..'})
                stack{end+1} = fullfile(curr, dd(i).name);
            end
        end
        files = dir(curr);
        for i = 1:numel(files)
            if files(i).isdir, continue; end
            [~,~,e] = fileparts(files(i).name);
            if any(strcmpi(e, exts))
                src = fullfile(curr, files(i).name);
                rel = src(baseLen+2:end);
                dst = fullfile(dstFolder, rel);
                dstDir = fileparts(dst);
                if ~opts.dryRun && ~isfolder(dstDir), mkdir(dstDir); end
                if ~isKey(seen, src)
                    doCopy(src, dst, opts, logger);
                    seen(src) = true;
                end
            end
        end
    end
end

function doCopy(src, dst, opts, logger)
    if exist(dst, 'file') && ~opts.overwrite
        logger('SKIP (exists): %s', dst);
        return;
    end
    if opts.dryRun
        logger('COPY: %s  -->  %s', src, dst);
    else
        [ok, msg] = copyfile(src, dst, 'f'); %#ok<NASGU>
        if ok
            logger('COPIED: %s  -->  %s', src, dst);
        else
            logger('ERROR copying: %s  -->  %s', src, dst);
            logger('  Reason: %s', msg);
        end
    end
end

function safeClose(fid, opts)
    if fid > 2 && ~opts.dryRun
        try, fclose(fid); catch, end
    end
end
