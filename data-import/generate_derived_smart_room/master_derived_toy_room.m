function master_derived_toy_room(subexpIDs, option, flagReliability, args)
% postfixation
% all
%   trial
%   inhand
%   roi
%   ja
%   inhand-roi

% disp(ismember(floor(subexpIDs/100),351:398));

if ~exist('args', 'var') || isempty(args)
    args = struct([]);
end
if ~isfield(args, 'agents')
    agents = {'child', 'parent'};
else
    agents = args.agents;
end

switch true
    case ismember(floor(subexpIDs/100),351:398)
        fixation1 = 30;
        fixation2 = 31;
    case ismember(subexpIDs,[5809 5810 5812])
        fixation1 = 28;
        fixation2 = 29;
    otherwise
        fixation1 = 27;
        fixation2 = 28;
end

if ~exist('flagReliability', 'var')
    flagReliability = 0;
end
subs = cIDs(subexpIDs);

if isempty(subs)
    disp('Can not find subjects in subject table, please check your subject id!')
end

for s = 1:numel(subs)
    sub = subs(s);
    fprintf('%d\n', sub);
    fprintf('%d\n',fixation1);
    fprintf('%d\n',fixation2);
    read_trial_info(sub);
    fs = filesep;
    root = get_subject_dir(sub);
    % agents = {'child', 'parent'};
    extract_range_fn = fullfile(root, 'supporting_files', 'extract_range.txt');
    if ~exist(extract_range_fn, 'file')
        movefile(fullfile(root, 'extra_p', 'extract_range.txt'), extract_range_fn);
    end
    % fix cstreams
    %     remove_nan(sub);
    % parse config to get video cuts
    %     config = parse_ini([root fs 'config.ini']);
    %     b_offset = config.s_extractframes.o_begin;
    %     b_offset = parse_time(b_offset);
    %     b_offset_frame = ceil(b_offset.total_sec*30) + 1;
    %
    %     e_offset = config.s_extractframes.o_end;
    %     e_offset = parse_time(e_offset);
    %     e_offset_frame = e_offset.total_sec*30 + 1;
    
    if sum(ismember(option, {'postfixation'})) > 0
        % generate eye roi
        fprintf('\nProcessing postfixation for %d\n', sub);
        cat_list = [1:get_num_obj(sub)+1];
        pause(1);
        for a = 1:length(agents)
            agent = agents{a};
            if flagReliability
                fn = [root fs 'reliability' fs sprintf('coding_eye_roi_%s_reliability.mat', agent)];
            else
                fn = [root fs 'supporting_files' fs sprintf('coding_eye_roi_%s.mat', agent)];
            end
            if exist(fn, 'file')
                load(fn);
                data = sdata.data;
                if flagReliability
                    fixations = get_csv_data_v2([root fs 'reliability' fs 'fixation_frames_' agent '_reliability.txt']);
                else
                    fixations = get_csv_data_v2([root fs 'supporting_files' fs 'fixation_frames_' agent '_reliability.txt']);
                end
                for f = 1:size(fixations, 1)
                    % data(fixations(f,1):fixations(f,2),2) = data(fixations(f,3),2);
                    % the old script propagates the middle frame's ROI to the whole prefixation and 
                    % replaces the other coded frames' value with the middle frame value; the updated
                    % code only replaces 27s and 28s and keeps the other coding - DZ
                    data((data(:, 2)==fixation1 | data(:, 2)==fixation2) & data(:, 1) >= fixations(f,1) & data(:, 1) < fixations(f,2), 2) = data(fixations(f,3),2);
                end
                log = ismember(data(:,2), [fixation1 fixation2]);
                data(log,2) = -1;
                data(data(:,2)==-1,2) = NaN;
                data(:,1) = (data(:,1) - 1)/30 + 30;
                % data(isnan(data(:,2)), 2) = 0;
                cev = cstream2cevent(data);
                if flagReliability
                    record_variable(sub, ['cstream_eye_roi_fixation_' agent '_reliability'], data);
                    record_variable(sub, ['cevent_eye_roi_fixation_' agent '_reliability'], cev);
                else
                    record_variable(sub, ['cstream_eye_roi_fixation_' agent], data);
                    record_variable(sub, ['cevent_eye_roi_fixation_' agent], cev);
                end
                
                cev = cevent_merge_segments(cev, 0.50001, cat_list);
                cst = cevent2cstreamtb(cev, data);
                
                if flagReliability
                    record_variable(sub, ['cstream_eye_roi_' agent '_reliability'], cst);
                    record_variable(sub, ['cevent_eye_roi_' agent '_reliability'], cev);
                else
                    record_variable(sub, ['cstream_eye_roi_' agent], cst);
                    record_variable(sub, ['cevent_eye_roi_' agent], cev);
                end

                % record_eyegaze_toyroom(sub, agent); % added by Sven to automatically generate cont2_eye_xy_child/parent
            end
        end
    end
    
    if sum(ismember(option, {'postframebyframe'})) > 0
        fprintf('\nProcessing postframebyframe for %d\n', sub);
        pause(1);
        for a = 1:length(agents)
            agent = agents{a};
            cst = get_variable(sub, sprintf('cstream_eye_roi_%s', agent));
            cev = cstream2cevent(cst);
            cev(isnan(cev(:,3)),:) = [];
            record_variable(sub, sprintf('cevent_eye_roi_%s', agent), cev);
        end
    end
    
    if sum(ismember(option, {'trial', 'all'})) > 0
        make_trials_vars(sub);
    end
    
    if sum(ismember(option, {'ja', 'roi', 'trial', 'all'})) > 0
        fprintf('\nProcessing roi for %d\n', sub);
        pause(1);
        make_joint_attention_smart_room(sub);
        make_synched_attention(sub);
    end
    
    if sum(ismember(option, {'inhand', 'all'})) > 0
        fprintf('\nProcessing inhand for %d\n', sub);
        pause(1);
        for a = 1:length(agents)
            agent = agents{a};
            cstlh = get_variable(sub, sprintf('cstream_inhand_left-hand_obj-all_%s', agent));
            cstrh = get_variable(sub, sprintf('cstream_inhand_right-hand_obj-all_%s', agent));
            cevlh = cstream2cevent(cstlh);
            cevrh = cstream2cevent(cstrh);
            cevlh(isnan(cevlh(:,3)),:) = [];
            cevrh(isnan(cevrh(:,3)),:) = [];
            cevboth = cat(1, cevlh, cevrh);
            cevboth = sortrows(cevboth, [1 2 3]);
            
            record_variable(sub, sprintf('cevent_inhand_left-hand_obj-all_%s', agent), cevlh);
            record_variable(sub, sprintf('cevent_inhand_right-hand_obj-all_%s', agent), cevrh);
            record_variable(sub, sprintf('cevent_inhand_%s', agent), cevboth);
        end
        make_both_inhand(sub);
    end
    
    if sum(ismember(option, {'inhand-roi', 'roi', 'inhand', 'all'})) > 0
        fprintf('\nProcessing inhand/roi for %d\n', sub);
        pause(1);
        make_joint_eye_inhand_smart_room(sub);
    end
end
end
