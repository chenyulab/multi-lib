function box2size_dist_maskrcnn(sID, agent, num_of_toys, mappings)
if ~exist('agent', 'var')
    agent = 'both';
end

if ~exist('num_of_toys', 'var')
    num_of_toys = NaN;
end

if ~exist('mappings', 'var')
    mappings = [];
end

switch agent
    case 'child'
        record_size_dist_vars(sID, agent, num_of_toys, mappings)
    case 'parent'
        record_size_dist_vars(sID, agent, num_of_toys, mappings)
    case 'both'
        record_size_dist_vars(sID, 'child', num_of_toys, mappings)
        record_size_dist_vars(sID, 'parent', num_of_toys, mappings)
    otherwise
        error('[-] Error: Invalid agent. Valid agent options are: child / parent / both')
end

% contents = load(boxpath);
% boxdata = contents.box_data;
% img = imread([imgpath sep boxdata(1).frame_name(strfind(boxdata(1).frame_name, 'img_'):end)]);
% [n_rows, n_cols, ~] = size(img);
% result = zeros(numel(boxdata), 25);
% 
% %assignin('base', 'boxdata', boxdata)
% 
% result(:,1) = frame_num2time([boxdata(:).frame_id]', sID);
% 
% for i = 1:numel(boxdata)
% 
%     boxes = boxdata(i).post_boxes; % presumably [x_c y_c w h] in norm. [0-1] coordinates'
%     boxes(:,1) = boxes(:,1)*n_cols;
%     boxes(:,2) = boxes(:,2)*n_rows;
%     boxes(:,3) = boxes(:,3)*n_cols;
%     boxes(:,4) = boxes(:,4)*n_rows;
%     boxes(:,1) = boxes(:,1) - boxes(:,3)/2;
%     boxes(:,2) = boxes(:,2) - boxes(:,4)/2;
%     boxes = ceil(boxes); % [x y w h] in abs. coordinates
%     %result(i, 1) = timestamp;
%     for j = 1:24
%         box = boxes(j,:);
%         if sum(box == 0)
%             result(i, j+1) = NaN;
%         else
%             box = trim_box_to_frame(box, n_rows, n_cols);
%             pixSize = (box(3) * box(4)) / (n_rows * n_cols);
%             result(i, j+1) = pixSize;
%         end
%     end
% end

% for i = 1:num_of_toys
%     record_variable(sID, sprintf('cont_vision_size_obj%d_%s', i, parentOrChild), horzcat(result(:, 1), result(:, i+1)));
% end
end

function record_size_dist_vars(subID, agent, num_of_toys, mappings)
root = get_subject_dir(subID);
boxpath = [root filesep 'extra_p' filesep num2str(subID) '_' agent '_boxes.mat'];
load(boxpath);
switch agent
    case 'child'
        imgpath = [root filesep 'cam07_frames_p'];
        %gaze_data = get_variable(subID, 'cont2_eye_xy_child');
    case 'parent'
        imgpath = [root filesep 'cam08_frames_p'];
        % gaze_data = get_variable(subID, 'cont2_eye_xy_parent');
end

if isa(box_data, 'cell')
    disp('[!] The loaded box_data is a cell array')
    bboxes = box_data(:, 4);
    img_IDs = box_data(:, 3);
end

t_num = size(bboxes{1}, 1);
if ~isempty(mappings)
    toys_num = numel(unique(mappings));
    t_num = min(t_num, toys_num);
end
if isnan(num_of_toys)
    num_of_toys = t_num;
elseif t_num ~= num_of_toys
    error("[-] Error: The number of toys entered does not match with the bbox detections")
end
img = imread([imgpath filesep 'img_' num2str(img_IDs{1}) '.jpg']);
[n_rows, n_cols, ~] = size(img);

size_result = zeros(size(bboxes, 1), t_num+1);
dist_result = zeros(size(bboxes, 1), t_num+1);
gaze_to_bbox_center_result = zeros(size(bboxes, 1), t_num+1);
ts = frame_num2time(double(cell2mat(img_IDs')), subID);
size_result(:, 1) = ts;
dist_result(:, 1) = ts;
gaze_to_bbox_center_result(:, 1) = ts;

for i = 1:size(bboxes, 1)
    bbox_current = bboxes{i};
    for j = 1:numel(mappings)
        bbox = bbox_current(j, :);
        bbox = trim_box_to_frame(bbox, 1, 1);
        
        % cal box size results
        obj_size = bbox(3) * bbox(4);
        if obj_size == 0
            obj_size = NaN;
        end
        size_result(i, mappings(j)+1) = obj_size;
        
        %cal box to center dist results
        if isnan(obj_size)
            center_to_gaze_dist = NaN;
            dist = NaN;
        else
            left = bbox(1);
            right = bbox(1)+bbox(3);
            top = bbox(2);
            bottom = bbox(2)+bbox(4);
            %midx = (left+right)/2*n_cols;
            %midy = (top+bottom)/2*n_rows;
            %gaze_xy = gaze_data(gaze_data(:, 1)-ts(i) < 0.01, 2:3);
            %center_to_gaze_dist = sqrt((midx-gaze_xy(1))^2 + (midy-gaze_xy(2))^2) / ...
                %(sqrt(sum([n_cols/2, n_rows/2].^2)));
        
            tl = [left, top];
            tr = [right, top];
            bl = [left, bottom];
            br = [right, bottom];
        
            if max([left, right, 0.5]) ~= 0.5 && min([left, right, 0.5]) ~= 0.5 % x overlap
                if max([top, bottom, 0.5]) ~= 0.5 && min([top, bottom, 0.5]) ~= 0.5 % y overlap
                    dist = 0;
                else
                    dist = min(abs(top-0.5), abs(bottom-0.5));
                end
            elseif max([top, bottom, 0.5]) ~= 0.5 && min([top, bottom, 0.5]) ~= 0.5 % only y overlap
                dist = min(abs(left-0.5), abs(right-0.5));
            else
                dist = min([sqrt(sum((tl-0.5).^2)), ...
                    sqrt(sum((tr-0.5).^2)), ...
                    sqrt(sum((bl-0.5).^2)), ...
                    sqrt(sum((br-0.5).^2))]);
            end
            dist = dist/(sqrt(sum([0.5, 0.5].^2)));
        end
        %gaze_to_bbox_center_result(i, mappings(j)+1) = center_to_gaze_dist;
        dist_result(i, mappings(j)+1) = dist;
    end
end

% record variables
for i = unique(mappings)
    
     record_variable(subID, sprintf('cont_vision_min-dist_center-to-obj%d_%s', i, agent), horzcat(dist_result(:, 1), dist_result(:, i+1)));
     record_variable(subID, sprintf('cont_vision_size_obj%d_%s', i, agent), horzcat(size_result(:, 1), size_result(:, i+1)));
     record_variable(subID, sprintf('cont_eye-vision_min-dist_gaze-to-obj%d_%s', i, agent), horzcat(gaze_to_bbox_center_result(:, 1), gaze_to_bbox_center_result(:, i+1)))
end

end

function [box] = trim_box_to_frame(box, n_rows, n_cols)
% box = x y w h
x = box(1);
y = box(2);
w = box(3);
h = box(4);
x = min(max(0, x), n_cols);
y = min(max(0, y), n_rows);
w = min(max(0, w), n_cols - x);
h = min(max(0, h), n_rows - y);
box = [x y w h];
end

