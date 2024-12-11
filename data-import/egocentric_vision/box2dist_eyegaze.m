function box2dist_eyegaze(sID, flag,is_face)

if ~exist('flag', 'var')
    flag = 'child';
end
sep = filesep();
root = get_subject_dir(sID);
switch flag
    case 'child'
        if is_face
            boxpath = [root sep 'extra_p' sep num2str(sID) '_child_boxes_face.mat'];
            num_objs = 1;
        else
            boxpath = [root sep 'extra_p' sep num2str(sID) '_child_boxes.mat'];
            num_objs = get_num_obj(sID);
        end
        imgpath = [root sep 'cam07_frames_p'];
        parentOrChild = flag;
    case 'parent'
        if is_face
            boxpath = [root sep 'extra_p' sep num2str(sID) '_parent_boxes_face.mat'];
            num_objs = 1;
        else
            boxpath = [root sep 'extra_p' sep num2str(sID) '_parent_boxes.mat'];
            num_objs = get_num_obj(sID);
        end
        imgpath = [root sep 'cam08_frames_p'];
        parentOrChild = flag;
    otherwise
        disp('[-] Error: Invalid flag')
        return
end

contents = load(boxpath);
boxdata = contents.box_data;
img = imread([imgpath sep boxdata(1).frame_name(strfind(boxdata(1).frame_name, 'img_'):end)]);
assignin('base', 'img', img);
[n_rows, n_cols, ~] = size(img);
result = zeros(numel(boxdata), num_objs+1);
diag = sqrt(n_rows^2 + n_cols^2);
eyegaze_data = get_variable_by_trial_cat(sID,sprintf('cont2_eye_xy_%s',flag));


%assignin('base', 'boxdata', boxdata)


result(:,1) = frame_num2time([boxdata(:).frame_id]', sID);



for i = 1:numel(boxdata)

    boxes = boxdata(i).post_boxes; % presumably [x_c y_c w h] in norm. [0-1] coordinates'
    boxes(:,1) = boxes(:,1)*n_cols;
    boxes(:,2) = boxes(:,2)*n_rows;
    boxes(:,3) = boxes(:,3)*n_cols;
    boxes(:,4) = boxes(:,4)*n_rows;
    boxes(:,1) = boxes(:,1) - boxes(:,3)/2;
    boxes(:,2) = boxes(:,2) - boxes(:,4)/2;
    boxes = ceil(boxes); % [x y w h] in abs. coordinates

    try
        gaze_x = eyegaze_data(i,2);
        gaze_y = eyegaze_data(i,3);
    catch ME
        result(i,2:end) = NaN;
        continue
    end
    %result(i, 1) = timestamp;
    for j = 1:num_objs
        box = boxes(j,:);
        if box(3) == 0 || box(4) == 0
            dist = NaN;
        elseif isnan(gaze_x) || isnan(gaze_y)
            dist = NaN;
        else
            box = trim_box_to_frame(box, n_rows, n_cols);
            vertices = get_vertices(box);
            xs = [vertices(:, 1); gaze_x];
            ys = [vertices(:, 2); gaze_y];
            if max(xs) ~= gaze_x && min(xs) ~= gaze_x %if x overlap
                if max(ys) ~= gaze_y && min(ys) ~= gaze_y % if y overlap
                    dist = 0;
                else
                    dist = min(abs(ys(1)-gaze_y), abs(ys(3)-gaze_y));
                end
            elseif max(ys) ~= gaze_y && min(ys) ~= gaze_y %if only y overlap
                dist = min(abs(xs(1)-gaze_x), abs(xs(2)-gaze_x));
            else
    %             dist = min(sqrt(vertices(:, 1).^2 + vertices(:, 2).^2));
                dist = min(sqrt((vertices(:, 1) - gaze_x).^2 + (vertices(:, 2) - gaze_y).^2));
            end
        end
        result(i, j+1) = dist / diag;
    end
end

function [vertices] = get_vertices(box)
vertices = zeros(4, 2);
x = box(1);
y = box(2);
w = box(3);
h = box(4);
vertices(1, :) = [x y];
vertices(2, :) = [x + w, y];
vertices(3, :) = [x, y + h];
vertices(4, :) = [x + w, y + h];
end

function [box] = trim_box_to_frame(box, n_rows, n_cols)
% box = x y w h
x = box(1);
y = box(2);
w = box(3);
h = box(4);
x = min(max(1, x), n_cols);
y = min(max(1, y), n_rows);
w = min(max(1,w), n_cols - x);
h = min(max(1,h), n_rows - y);
box = [x y w h];
end

assignin('base', 'result', result);
if is_face
    % filter the short instance that is smaller than 6 timestamp
    min_length = 6;
    cont_data = horzcat(result(:, 1), result(:, 1+1));
    filtered_data = filter_cont_instance(cont_data,min_length);
    record_additional_variable(sID, sprintf('cont_vision_min-dist_gaze-to-face_%s', parentOrChild), filtered_data);
else
    for i = 1:num_objs
        record_additional_variable(sID, sprintf('cont_vision_min-dist_gaze-to-obj%d_%s', i, parentOrChild), horzcat(result(:, 1), result(:, i+1)));
    end
end

end


