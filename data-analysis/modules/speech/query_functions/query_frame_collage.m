%%% Helper function to generate a collage of frames where the word instance
%%% occurs in the target experiments
function query_frame_collage(query_word_table,row,column,cam,filename,args)
    % hard-coded resolution for skipped frame
    x_res = 480;
    y_res = 640;

    if ~exist('args', 'var') || isempty(args)
        args = struct([]);
    end

    if isfield(args, 'whence')
        whence = args.whence;
    else
        whence = '';
    end

    if isfield(args, 'interval')
        interval = args.interval;
    else
        interval = [0 0];
    end

    subID_list = query_word_table.subID;
    onset_time_list = query_word_table.onset1;
    onset_frame_list = query_word_table.onset1_frame;
    offset_time_list = query_word_table.offset1;
    offset_frame_list = query_word_table.offset1_frame;

    map = [];

    for i = 1 : size(query_word_table,1)
        subID = str2double(subID_list(i));

        if strcmp(whence,'start')
            time = str2double(onset_time_list(i));
            time = time+interval(1);
            frame = str2double(onset_frame_list(i))+interval(1)*30;
        elseif strcmp(whence,'end')
            time = str2double(offset_time_list(i));
            time = time+interval(2);
            frame = str2double(offset_frame_list(i))+interval(2)*30;
        elseif strcmp(whence,'startend')
            time = str2double(onset_time_list(i));
            time = time+interval(1);
            frame = str2double(onset_frame_list(i))+interval(1)*30;
        else
            time = str2double(onset_time_list(i));
            frame = str2double(onset_frame_list(i));
        end

        sub_dir = get_subject_dir(subID);

        % get beginning and end trial frame number
        trial_timing = get_trials(subID);
        trial_start = trial_timing(:,1);
        trial_end = trial_timing(:,2);
        within_trial = frame >= trial_start & frame <= trial_end;

        if sum(within_trial == 1)
            % get pixel-wise RGB data for each target frame
            imdata = get_image_by_time(subID, cam, time);
            % add it to the image tile map
            map{end+1} = imdata;
        else
            fprintf('Time %f is not within trial for subject %d!\n',time,subID);
            % get pixel-wise RGB data for each target frame
            imdata = zeros(x_res,y_res,3,'uint8');
            % add it to the image tile map
            map{end+1} = imdata;
        end
    end

    for i = 1:ceil(size(query_word_table,1)/(row*column))
        start_frame = 1+(i-1)*(row*column);
        end_frame = i*(row*column);

        if end_frame > size(query_word_table,1)
            end_frame = size(query_word_table,1);
        end

        out = imtile(map, 'Frames', start_frame:end_frame,'GridSize',[row,column]);
        figure;
        imshow(out);
        imwrite(out,strcat(extractBefore(filename,"."),sprintf('_collage%d.png',i)));
    end

    if strcmp(whence,'end')
        fprintf('Displaying images %d seconds away from original offset.\n',interval(2));
    else
        fprintf('Displaying images %d seconds away from original onset.\n',interval(1));
    end   
end