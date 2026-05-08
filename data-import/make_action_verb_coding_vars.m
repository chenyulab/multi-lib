clear;

%sub_ids = find_subjects('cevent_speech_verb_word-id_parent',12);
sub_ids = [35352:35353, 35356, 35360:35363, 35366:35367, 35370, 35373:35380, 35382, 35384:35386];


for s = 1:length(sub_ids)

sub_id = sub_ids(s);

disp(sub_id);

start_time = 30;
fps = 30;
[extract_onset,~] = get_extract_range(sub_id);
system_time_offset = start_time - extract_onset/fps;

sub_info = get_subject_info(sub_id);
mapping_root = fullfile(get_multidir_root(),['experiment_' num2str(sub_info(2))]);

try
    coding_raw_file = fullfile(get_subject_dir(sub_id),'supporting_files','verb_coding_file.csv');
    coding_file = fullfile(get_subject_dir(sub_id),'supporting_files','action_verb_coding2.csv');
    mapping_verb_coding_file = fullfile(mapping_root,'mapping_file2.xlsx');
    mapping_verb_file = fullfile(mapping_root,'mapping_file_verbs.csv');
    mapping_obj_file = fullfile(mapping_root,'mapping_file1.xlsx');
    
    
    data = readtable(coding_file);
    data_raw = readtable(coding_raw_file);
    mapping_verb_coding = readtable(mapping_verb_coding_file);
    mapping_verb = readtable(mapping_verb_file);
    mapping_obj = readtable(mapping_obj_file);

catch ME
    disp(ME.message)
    continue
end

onset = data.verb_coding_new_onset;
offset = data.verb_coding_new_offset;
verb = data.verb_coding_new_verb;
bdan = data.verb_coding_new_overlap_bdan;
pcb = data.verb_coding_new_agent_pcb;
ref_1 = data.verb_coding_new_ref_1;
ref_2 = data.verb_coding_new_ref_2;


%% fix the repeat instance based on the raw coding file
if size(data_raw,1) ~= size(onset,1)

    new_data = table([], [], [], [], [], [], [], ...
        'VariableNames', {'verb_coding_new_onset', ...
                          'verb_coding_new_offset', ...
                          'verb_coding_new_verb', ...
                          'verb_coding_new_overlap_bdan', ...
                          'verb_coding_new_agent_pcb', ...
                          'verb_coding_new_ref_1', ...
                          'verb_coding_new_ref_2'});

    handled_onsets = [];
    
    for i = 1:size(data_raw,1)
        onset_raw = round(data_raw.onset_cevent_speech_verb_word_id_parent(i));
        idx = find(abs(onset - onset_raw) <= 2);
        if isscalar(idx)
            % Single match → keep as-is
            new_data = [new_data; {onset(idx), offset(idx), verb{idx}, bdan{idx}, pcb{idx}, ref_1{idx}, ref_2{idx}}];
        
        else
            % Multiple matches within ±2 frames of onset_raw
            uverbs = unique(verb(idx));
        
            if numel(uverbs) > 1
                % Co-occurring *different* verbs: handle this onset only once
                if ismember(onset_raw, handled_onsets)
                    % We've already added the co-occurrence for this onset; skip this raw row
                    continue;
                end
        
                % Add exactly one row per verb (choose the best matching row per verb)
                diffs_all = abs(onset(idx) - onset_raw);
                durations_all = offset(idx) - onset(idx);
        
                for v_i = 1:numel(uverbs)
                    v = uverbs{v_i};
                    mask = strcmp(verb(idx), v);
                    cand_idx = idx(mask);
                    cand_diffs = diffs_all(mask);
                    cand_durs  = durations_all(mask);
        
                    [~, ord] = sortrows([cand_diffs(:), -cand_durs(:)]); % closest onset, then longest
                    k = cand_idx(ord(1));
        
                    new_data = [new_data; {onset(k), offset(k), verb{k}, bdan{k}, pcb{k}, ref_1{k}, ref_2{k}}];
                end
        
                handled_onsets(end+1) = onset_raw; 
        
            else
                % All matches share the *same verb* → true repeats: replicate them
                for j = 1:numel(idx)
                    k = idx(j);
                    new_data = [new_data; {onset_raw, offset(k), verb{k}, bdan{k}, pcb{k}, ref_1{k}, ref_2{k}}];
                end
            end
        end
    
    end
    
    data = new_data;


end

data = data(~isnan(data{:,1}),:);

    onset = data.verb_coding_new_onset;
    offset = data.verb_coding_new_offset;
    verb = data.verb_coding_new_verb;
    bdan = data.verb_coding_new_overlap_bdan;
    pcb = data.verb_coding_new_agent_pcb;
    ref_1 = data.verb_coding_new_ref_1;
    ref_2 = data.verb_coding_new_ref_2;

%% check co-occurance instance, adjust the onset time 
dup_groups = {};
i = 1;
while i < numel(onset)
    j = i;
    while j < numel(onset) && onset(j+1) == onset(i) && ~strcmp(verb{j+1},verb{i})
        j = j + 1;
    end
    if j > i  % found a duplicate sequence
        dup_groups{end+1} = i:j;
    end
    i = j + 1;
end

EPS = 30;  % desired inter-segment gap in seconds

if ~isempty(dup_groups)
    for g = 1:numel(dup_groups)
        idxg = dup_groups{g};        % indices for this co-occurrence group
        n = numel(idxg);
        if n <= 1, continue; end

        % Shared start/end for the group
        t0 = double(onset(idxg(1)));             % same onset by construction
        t1 = double(min(offset(idxg)));          % safe common end (don’t exceed anyone’s offset)
        if t1 <= t0, continue; end

        L = t1 - t0;                              % total available duration

        % Pick an effective gap that fits; prefer 0.03, but shrink if needed
        eps_eff = min(EPS, (L - 1e-6) / (n - 1));
        base_len = (L - (n - 1) * eps_eff) / n;   % per-segment duration

        % Assign non-overlapping segments: [on, off] then +gap to next onset
        cur = t0;
        for k = 1:n
            seg_on  = cur;
            seg_off = cur + base_len;

            onset(idxg(k))  = round(seg_on, 3);   % keep millisecond-ish precision
            offset(idxg(k)) = round(seg_off, 3);

            cur = seg_off + eps_eff;              % start next after a gap
        end

        % Clamp last offset (numerical safety) and ensure strict non-overlap
        offset(idxg(end)) = min(offset(idxg(end)), t1);
        for k = 2:n
            if onset(idxg(k)) <= offset(idxg(k-1))
                onset(idxg(k)) = round(offset(idxg(k-1)) + eps_eff, 3);
            end
        end
    end

    data.verb_coding_new_onset  = onset;
    data.verb_coding_new_offset = offset;
end

%% generate speech word id variables
onset = onset/1000 + system_time_offset;
offset = offset/1000 + system_time_offset;
mappingV = containers.Map(mapping_verb.verb, mapping_verb.id_num);
mappingVC = containers.Map(mapping_verb_coding.Var1, mapping_verb_coding.Var2);
mapObj = containers.Map(mapping_obj.Var1, mapping_obj.Var2);

verb_id = cellfun(@(s) mappingV(s),verb);
bdan_id = cellfun(@(s) mappingVC(s),bdan);
pcb_id = cellfun(@(s) mappingVC(s),pcb);

verb_data = [onset,offset,verb_id];
bdan_data = [onset,offset,bdan_id];
pcb_data = [onset,offset,pcb_id];

record_additional_variable(sub_id,'cevent_speech_verb_word-id_parent',verb_data);
record_additional_variable(sub_id,'cevent_speech_verb_action_parent',bdan_data);
record_additional_variable(sub_id,'cevent_speech_verb_agent_parent',pcb_data);


%%  merge ref 1 and ref 2 and generate cevent_speech_verb_obj-id _parent

% If ref_1 / ref_2 are cellstr:
ref_1_id = cellfun(@(s) mapObj(s), ref_1);
ref_2_id = cellfun(@(s) mapObj(s), ref_2);

ref_1_data = [onset, offset, ref_1_id];
ref_2_data = [onset, offset, ref_2_id];

valid_idx = ref_2_data(:,3) ~= 26;
ref_2_data = ref_2_data(valid_idx, :);

ref_data = vertcat(ref_1_data,ref_2_data);

ref_data = sortrows(ref_data,1);

record_additional_variable(sub_id,'cevent_speech_verb_obj-id_parent',ref_data);

end