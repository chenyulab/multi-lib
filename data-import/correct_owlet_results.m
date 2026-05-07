function out_path = correct_owlet_results(subID, varargin)
% correct_owlet_results
%
% Correct OWLET camera gaze output using manually coded inclusion intervals.
%
% This function reads a synced camera gaze CSV file, applies manual inclusion
% coding, and saves a corrected CSV file with the same columns as the input.
% Only the Tag column is modified.
%
% Output Tag values are limited to:
%   left, right, away
%
% Default file structure:
%   supporting_files/lowcam/lowcam_synced.csv
%   supporting_files/lowcam/inclusion.csv
%   supporting_files/lowcam/lowcam_synced_corrected.csv
%
% Example:
%   correct_owlet_results(31024)
%
% Example for highcam:
%   correct_cam_with_inclusion_simple(31024, 'cam_name', 'highcam')
%
% Inputs:
%   subID      - subject ID
%
% Optional name-value inputs:
%   cam_name       - camera folder/name, default: 'lowcam'
%                    examples: 'lowcam', 'highcam'
%
%   sub_dir        - folder containing camera files.
%                    default:
%                    fullfile(get_subject_dir(subID), ...
%                    'supporting_files', cam_name)
%
%   input_file     - synced camera CSV file.
%                    default: [cam_name '_synced.csv']
%
%   inclusion_file - manual inclusion coding file.
%                    default: 'inclusion.csv'
%
%   output_file    - corrected output CSV file.
%                    default: [cam_name '_synced_corrected.csv']
%
% Output:
%   out_path       - full path of the saved corrected CSV file


%% -------- parse inputs --------
p = inputParser;

addRequired(p, 'subID', @isnumeric);

addParameter(p, 'cam_name', 'lowcam', @(x) ischar(x) || isstring(x));
addParameter(p, 'sub_dir', '', @(x) ischar(x) || isstring(x));
addParameter(p, 'input_file', '', @(x) ischar(x) || isstring(x));
addParameter(p, 'inclusion_file', 'inclusion.csv', @(x) ischar(x) || isstring(x));
addParameter(p, 'output_file', '', @(x) ischar(x) || isstring(x));

parse(p, subID, varargin{:});

cam_name = char(p.Results.cam_name);

if strlength(string(p.Results.sub_dir)) == 0
    sub_dir = fullfile(get_subject_dir(subID), 'supporting_files', cam_name);
else
    sub_dir = char(p.Results.sub_dir);
end

if strlength(string(p.Results.input_file)) == 0
    input_file = sprintf('%s_synced.csv', cam_name);
else
    input_file = char(p.Results.input_file);
end

if strlength(string(p.Results.output_file)) == 0
    output_file = sprintf('%s_synced_corrected.csv', cam_name);
else
    output_file = char(p.Results.output_file);
end

inclusion_file = char(p.Results.inclusion_file);

cam_path  = fullfile(sub_dir, input_file);
incl_path = fullfile(sub_dir, inclusion_file);
out_path  = fullfile(sub_dir, output_file);


%% -------- load --------
cam_data = readtable(cam_path);
incl = readtable(incl_path);

if ~any(strcmpi(cam_data.Properties.VariableNames, 'Time'))
    error('%s must contain a column named "Time" (ms).', input_file);
end

if ~any(strcmpi(cam_data.Properties.VariableNames, 'Tag'))
    error('%s must contain a column named "Tag".', input_file);
end

t = cam_data.Time;  % ms
tagRaw = lower(strtrim(string(cam_data.Tag)));


%% -------- normalize starting Tag to {left,right,away} --------
Tag = strings(height(cam_data), 1);

Tag(tagRaw == "left"  | tagRaw == "l") = "left";
Tag(tagRaw == "right" | tagRaw == "r") = "right";
Tag(tagRaw == "away") = "away";

% If anything is missing/unknown, default to away
Tag(Tag == "") = "away";

% Track which frames were manually corrected by look coding
manualLookMask = false(height(cam_data), 1);


%% -------- read inclusion intervals --------
lookOn   = incl.look_onset;
lookOff  = incl.look_offset;
lookSide = lower(strtrim(string(incl.look_side)));

validLook = ~isnan(lookOn) & ...
            ~isnan(lookOff) & ...
            (lookOff > lookOn) & ...
            (lookSide ~= "");

lookOn   = lookOn(validLook);
lookOff  = lookOff(validLook);
lookSide = lookSide(validLook);


errOn  = incl.error_onset;
errOff = incl.error_offset;
errTyp = lower(strtrim(string(incl.error_err_type)));

validErr = ~isnan(errOn) & ...
           ~isnan(errOff) & ...
           (errOff > errOn) & ...
           (errTyp ~= "");

errOn  = errOn(validErr);
errOff = errOff(validErr);
errTyp = errTyp(validErr);


%% -------- apply manual LOOK first --------
% look_side:
%   l -> left
%   r -> right

for i = 1:numel(lookOn)
    idx = (t >= lookOn(i)) & (t <= lookOff(i));

    if ~any(idx)
        continue;
    end

    if lookSide(i) == "l"
        Tag(idx) = "left";
        manualLookMask(idx) = true;

    elseif lookSide(i) == "r"
        Tag(idx) = "right";
        manualLookMask(idx) = true;
    end
end


%% -------- apply manual ERROR second --------
% error_err_type:
%   l -> away always
%   o -> away only if that frame was not manually corrected by look coding

for i = 1:numel(errOn)
    idx = (t >= errOn(i)) & (t <= errOff(i));

    if ~any(idx)
        continue;
    end

    if errTyp(i) == "l"
        Tag(idx) = "away";

    elseif errTyp(i) == "o"
        idx_no_manual = idx & ~manualLookMask;
        Tag(idx_no_manual) = "away";
    end
end


%% -------- write output --------
cam_data.Tag = Tag;
writetable(cam_data, out_path);

fprintf('Saved corrected file: %s\n', out_path);

end