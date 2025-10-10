% INCREMENTAL_VIDEO_BACKUP
% - Scans camNN_video_r folders under each subject
% - Copies only NEW or CHANGED video files into a time-stamped batch folder
% - Preserves experiment/subject structure (experiment_##/__parent_child/...)
% - Updates a CSV manifest so future runs are incremental
%
% Assumes your helper functions exist on path:
%   cIDs(exp_ids), get_subject_info(sub_id), get_subject_dir(sub_id), sub2exp(sub_id)

%% ====== USER CONFIG ======
exp_ids        = [12, 15, 351, 353, 361, 362, 363, 70:75, 91, 27, 77:79, 65:69, 58, 59, 96];
videoExts      = {'.mp4', '.avi', '.mov', '.mkv', '.m4v'}; % case-insensitive
camDirRegex    = '^cam\d{2}_video_r$';                     % camera folder naming
% Where to store the incremental backups (persistent location):
dest_root      = 'Y:\multiwork_active_exp_backup\video_backup_incremental';

% Optional: dry run (true = simulate, print what would be copied)
dry_run = false;
%% =========================

if ~exist(dest_root, 'dir'); mkdir(dest_root); end
manifest_path = fullfile(dest_root, 'manifest.csv');
batch_dir     = fullfile(dest_root, datestr(datetime('now'), 'yyyymmdd_HHMMSS'));
if ~exist(batch_dir, 'dir'); mkdir(batch_dir); end

% Load existing manifest (if any)
manifest = load_manifest(manifest_path);

% Collect candidate files from all subjects
sub_ids = cIDs(exp_ids);

fprintf('[%s] Scanning subjects...\n', datestr(now));
to_copy = table('Size',[0 5], ...
    'VariableTypes', {'string','double','double','string','string'}, ...
    'VariableNames', {'rel_path','size','mtime','src','dst'});

for s = 1:numel(sub_ids)
    sub_id  = sub_ids(s);
    try
        sub_info = get_subject_info(sub_id);
        sub_dir  = get_subject_dir(sub_id);
        if ~exist(sub_dir, 'dir')
            warning('Subject folder does not exist: %s', sub_dir);
            continue;
        end

        exp_num  = sub2exp(sub_id);
        rel_prefix = fullfile(sprintf('experiment_%d', exp_num), sprintf('__%d_%d', sub_info(3), sub_info(4)));

        % find all camNN_video_r folders directly under subject
        d = dir(sub_dir);
        candDirs = d([d.isdir]);
        for k = 1:numel(candDirs)
            nameK = candDirs(k).name;
            if ismember(nameK, {'.','..'}); continue; end
            if ~isempty(regexp(nameK, camDirRegex, 'once'))
                cam_root = fullfile(sub_dir, nameK);
                % enumerate video files recursively
                files = list_files_with_ext(cam_root, videoExts);
                for i = 1:height(files)
                    src = files.path(i);
                    % rel from cam_root
                    rel_under_cam = erase(src, cam_root);
                    if startsWith(rel_under_cam, filesep), rel_under_cam = extractAfter(rel_under_cam, 1); end
                    rel_path = fullfile(rel_prefix, nameK, rel_under_cam);

                    file_info = dir(src);
                    this_size = double(file_info.bytes);
                    this_mtime = datenum(file_info.datenum);

                    % decide if this file is new or changed
                    idx = find(manifest.rel_path == string(rel_path), 1);
                    is_new = isempty(idx);
                    is_changed = false;
                    if ~is_new
                        % Changed if size differs or file mod-time is newer
                        is_changed = (manifest.size(idx) ~= this_size) || (manifest.mtime(idx) < this_mtime);
                    end

                    if is_new || is_changed
                        dst = fullfile(batch_dir, rel_path);
                        to_copy = [to_copy; {string(rel_path), this_size, this_mtime, string(src), string(dst)}]; %#ok<AGROW>
                    end
                end
            end
        end
    catch ME
        warning('Error scanning subject %d: %s', sub_id, ME.message);
        continue;
    end
end

% Deduplicate rows (defensive) and ensure parent dirs exist
if ~isempty(to_copy)
    [~, ia] = unique(to_copy.rel_path, 'stable');
    to_copy = to_copy(ia, :);
end

fprintf('[%s] Files to copy: %d\n', datestr(now), height(to_copy));

% Copy changed/new files
n_ok = 0; n_fail = 0;
for i = 1:height(to_copy)
    dstDir = fileparts(to_copy.dst(i));
    if ~dry_run && ~exist(dstDir, 'dir'); mkdir(dstDir); end
    try
        if ~dry_run
            copyfile(to_copy.src(i), to_copy.dst(i), 'f');
        end
        n_ok = n_ok + 1;

        % Update manifest row for this file
        idx = find(manifest.rel_path == to_copy.rel_path(i), 1);
        if isempty(idx)
            manifest = [manifest; table(to_copy.rel_path(i), to_copy.size(i), to_copy.mtime(i), ...
                                        'VariableNames', {'rel_path','size','mtime'})]; %#ok<AGROW>
        else
            manifest.size(idx)  = to_copy.size(i);
            manifest.mtime(idx) = to_copy.mtime(i);
        end
    catch ME
        n_fail = n_fail + 1;
        warning('Copy failed: %s -> %s (%s)', to_copy.src(i), to_copy.dst(i), ME.message);
    end
end

% Save manifest if not dry-run
if ~dry_run
    save_manifest(manifest_path, manifest);
end

fprintf('[%s] Incremental backup done. Copied OK: %d, Failed: %d, Batch folder: %s\n', ...
    datestr(now), n_ok, n_fail, batch_dir);

% function

%% ===================== helpers =====================

function files = list_files_with_ext(root, exts)
% Return table with column "path" (string) of files under root that have one of exts.
    exts = lower(string(exts));
    files = table(string.empty(0,1), 'VariableNames', {'path'});

    stack = {root};
    while ~isempty(stack)
        cur = stack{end}; stack(end) = [];
        L = dir(cur);
        for i = 1:numel(L)
            if L(i).isdir
                if ~ismember(L(i).name, {'.','..'})
                    stack{end+1} = fullfile(cur, L(i).name); %#ok<AGROW>
                end
            else
                [~,~,e] = fileparts(L(i).name);
                if any(strcmpi(lower(string(e)), exts))
                    files.path(end+1,1) = string(fullfile(cur, L(i).name)); %#ok<AGROW>
                end
            end
        end
    end
end

function T = load_manifest(p)
% Load CSV with columns: rel_path,size,mtime
    if exist(p, 'file')
        T = readtable(p, 'TextType', 'string');
        if ~all(ismember({'rel_path','size','mtime'}, T.Properties.VariableNames))
            error('Manifest missing required columns.');
        end
        % Ensure types
        T.rel_path = string(T.rel_path);
        T.size     = double(T.size);
        T.mtime    = double(T.mtime);
    else
        T = table(string.empty(0,1), double.empty(0,1), double.empty(0,1), ...
            'VariableNames', {'rel_path','size','mtime'});
    end
end

function save_manifest(p, T)
% Save CSV manifest
    writetable(T, p);
end
