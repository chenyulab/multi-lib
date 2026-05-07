%% correct_lowcam_with_inclusion_simple.m
% Output format: same as program output, Tag in {left,right,away} only.

clear; clc;

subIDs = 31024;
sub_dir = fullfile(get_subject_dir(subIDs),'supporting_files','lowcam');

lowcam_path = fullfile(sub_dir, "lowcam_synced.csv");
incl_path   = fullfile(sub_dir, "inclusion.csv");
out_path    = fullfile(sub_dir, "lowcam_synced_corrected.csv");

%% -------- load --------
low  = readtable(lowcam_path);
incl = readtable(incl_path);

if ~any(strcmpi(low.Properties.VariableNames,'Time'))
    error('lowcam_synced.csv must contain a column named "Time" (ms).');
end
if ~any(strcmpi(low.Properties.VariableNames,'Tag'))
    error('lowcam_synced.csv must contain a column named "Tag".');
end

t = low.Time;  % ms
tagRaw = lower(strtrim(string(low.Tag)));

%% -------- normalize starting Tag to {left,right,away} --------
Tag = strings(height(low),1);

Tag(tagRaw=="left"  | tagRaw=="l") = "left";
Tag(tagRaw=="right" | tagRaw=="r") = "right";
Tag(tagRaw=="away")               = "away";

% If anything is missing/unknown, default to away (safe)
Tag(Tag=="") = "away";

%% -------- read inclusion intervals --------
% look intervals
lookOn   = incl.look_onset;
lookOff  = incl.look_offset;
lookSide = lower(strtrim(string(incl.look_side)));

validLook = ~isnan(lookOn) & ~isnan(lookOff) & (lookOff > lookOn) & (lookSide ~= "");
lookOn    = lookOn(validLook);
lookOff   = lookOff(validLook);
lookSide  = lookSide(validLook);

% error intervals
errOn  = incl.error_onset;
errOff = incl.error_offset;
errTyp = lower(strtrim(string(incl.error_err_type)));

validErr = ~isnan(errOn) & ~isnan(errOff) & (errOff > errOn) & (errTyp ~= "");
errOn  = errOn(validErr);
errOff = errOff(validErr);
errTyp = errTyp(validErr);

%% -------- apply manual LOOK first (writes left/right) --------
for i = 1:numel(lookOn)
    idx = (t >= lookOn(i)) & (t <= lookOff(i));
    if ~any(idx), continue; end

    if lookSide(i) == "l"
        Tag(idx) = "left";
    elseif lookSide(i) == "r"
        Tag(idx) = "right";
    end
end

%% -------- apply manual ERROR second (override rules) --------
% 'l' => away always
% 'o' => if no manual look already set there, set away (since OWLET unusable)

for i = 1:numel(errOn)
    idx = (t >= errOn(i)) & (t <= errOff(i));
    if ~any(idx), continue; end

    if errTyp(i) == "l"
        Tag(idx) = "away";

    elseif errTyp(i) == "o"
        % Only overwrite where Tag is NOT already manual left/right
        idx_no_manual = idx & ~(Tag=="left" | Tag=="right");
        Tag(idx_no_manual) = "away";
    end
end

%% -------- write output: same columns, only Tag corrected --------
low.Tag = Tag;
writetable(low, out_path);
fprintf("Saved corrected file: %s\n", out_path);