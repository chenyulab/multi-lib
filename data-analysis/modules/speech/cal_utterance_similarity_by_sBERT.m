%%%
% Author: Connor & Bella
% Modifier: Jingwen
% Date: 8/7/2025
% 
% Given a speech data file in experiment level, this function calculate 
% utterance simarity into different grouping
% 
% input:
%   - input_csv
%   - keep_dups: boolean, whether to keep the duplicate utterance
%   - py_path: python path
%   - output_dir
% 
% output
% ├── expXX_utt_similarity.xlsx      % Experiment-level similarities
% │   ├── [overall exp-level sheet]
% │   └── [category-level sheets]
% └── {subID}_utt_similarity.xlsx    % Subject-level similarities
%     ├── [overall subject-level sheet]
%     └── [subject-category level sheets]
% 
% see demo_utterance_similarity for example
%%%
function cal_utterance_similarity_by_sBERT(input_csv, keep_dups, py_path, output_dir)
    round_dec = 4;       % decimals in similarity

    % all the column should align with extract_speech_in_situ &
    % extract_multi_measure
    subID_col = 1;
    expID_col = 2;
    onset_col = 3;
    offset_col = 4;
    cat_col = 5;
    trialsID_col = 6;
    instanceID_col = 7;
    utt_col = 10;
    
    % initialize python
    pyenv('Version', py_path);
    py.importlib.import_module('sentence_transformers')
    
    % — Load & parse the raw CSV —
    data = readtable(input_csv);
    subID_list = unique(data{:,subID_col});
    
    % — Load sBERT Model Once —
    st    = py.importlib.import_module('sentence_transformers');
    model = st.SentenceTransformer('all-MiniLM-L6-v2');
    dim   = 384;  % embedding dimension
    
    % get category list
    cat_list = sort(unique(data{:,cat_col}))';
    
    fprintf('\n Calculating similarity score in subject level ... \n');
    
    % — Loop Over Each Subject ID —
    for i = 1:numel(subID_list)
        subID       = subID_list(i);
    
        if keep_dups
            output_excel = fullfile(output_dir, ...
                         sprintf('%d_utt_similarity.xlsx', subID));  % I like to add "dups" to end of file if keep_dups == true
        else
            output_excel = fullfile(output_dir, ...
                         sprintf('%d_utt_similarity_unique.xlsx', subID));  % I like to add "dups" to end of file if keep_dups == true
        end

        % Filter rows for this subject
        subtab     = data(data{:,subID_col} == subID, :);
        
    
        % If nothing is left, skip this subject
        if isempty(subtab)
            fprintf('  No non‑cat28 utterances for subID %d – skipping\n', subID);
            continue;
        end
      
        expID      = subtab{:,expID_col};
        onset      = subtab{:,onset_col};
        offset     = subtab{:,offset_col};
        instanceID = subtab{:,instanceID_col};
        trialsID   = subtab{:,trialsID_col};
        category   = subtab{:,cat_col};
    
        % — Clean, Normalize & (Optionally) Deduplicate Utterances —
        rawSents = strip(string(subtab{:,utt_col}));      % trim whitespace
        rawSents = replace(rawSents, ';', '');               % drop semicolons
        rawSents = lower(rawSents);                          % lowercase all
        rawSents = regexprep(rawSents, '\s+', ' ');          % collapse spaces
    
        % drop missing/empty
        validMask = ~ismissing(rawSents) & rawSents~= "";
        rawSents    = rawSents(validMask);
        expID       = expID(validMask);
        onset       = onset(validMask);
        offset      = offset(validMask);
        instanceID  = instanceID(validMask);
        trialsID    = trialsID(validMask);
        category    = category(validMask);
    
    
        if keep_dups
            sentences = rawSents;
        else
            [sentences, ia] = unique(rawSents, 'stable');
            % sync metadata
            expID       = expID(ia);
            onset       = onset(ia);
            offset      = offset(ia);
            instanceID  = instanceID(ia);
            trialsID    = trialsID(ia);
            category    = category(ia);
        end
    
        % — Encode Each Sentence —
        n       = numel(sentences);
        emb_mat = zeros(n, dim);
        for k = 1:n
            py_emb       = model.encode(char(sentences(k)), ...
                              pyargs('normalize_embeddings', false));
            flat         = double(py.array.array('d', py.numpy.nditer(py_emb)));
            emb_mat(k,:) = reshape(flat,1,[]);
        end
    
        % — Compute Cosine Similarity Matrix —
        norms    = vecnorm(emb_mat, 2, 2);
        emb_norm = emb_mat ./ norms;
        sim_mat  = round(emb_norm * emb_norm.', round_dec);
    
        % % — Build & Write Global Similarity Sheet —
        utterances_col = cellstr(sentences);
        sim_tbl = array2table([utterances_col, num2cell(sim_mat)]);  % each row: utterance, sim1, sim2, ...
        
        % optionally rename columns
        n = size(sim_mat, 2);
        instance_labels = strcat('utt_', string(instanceID(:)));  % e.g., utt_1001
        col_names = ['utterance', matlab.lang.makeValidName(cellstr(instance_labels)')];
        sim_tbl.Properties.VariableNames = col_names;
    
        % Metadata columns
        subID_col_meta     = repmat(subID,     n,1);
        expID_col_meta     = repmat(expID(1),    n,1);
        onset_col_meta     = onset(:);
        offset_col_meta    = offset(:);
        trialsID_col_meta  = trialsID(:);
        instanceID_col_meta = instanceID(:);
        category_col_meta  = category(:);
    
        meta = table(subID_col_meta, expID_col_meta, onset_col_meta, offset_col_meta, ...
                     category_col_meta, trialsID_col_meta, instanceID_col_meta, ...
                     'VariableNames',{...
                       'subID','expID','onset','offset', ...
                       'category','trialsID','instanceID'});
    
        sim_tbl = [meta sim_tbl];
        writetable(sim_tbl, output_excel, ...
                   'Sheet','All_Similarity','WriteRowNames',false);
        fprintf('  Saved Global similarity for subID %d\n', subID);
    
        allCats = cat_list;
    
        for j = allCats
            thisCAT = j;
            idx     = find(category == thisCAT);
            sheetName = sprintf('cat_%d_sim', thisCAT);
    
            if ~isempty(idx)
                cat_sents    = sentences(idx);
                sim_cat      = sim_mat(idx, idx);
    
                labels_cat = cellstr(cat_sents);
                sim_tbl_cat = array2table([labels_cat, num2cell(sim_cat)]);
                nc = size(sim_cat, 2);
                instance_labels_cat = strcat('utt_', string(instanceID(idx)));
                col_names_cat = ['utterance', matlab.lang.makeValidName(cellstr(instance_labels_cat)')];
                sim_tbl_cat.Properties.VariableNames = col_names_cat;
    
                nc = numel(cat_sents);
                subID_cat      = repmat(subID,      nc,1);
                expID_cat      = repmat(expID(1),     nc,1);
                onset_cat      = onset(idx);
                offset_cat     = offset(idx);
                trialsID_cat   = trialsID(idx);
                instanceID_cat = instanceID(idx);
                category_cat   = category(idx);
    
                meta_cat = table(subID_cat, expID_cat, onset_cat, offset_cat, ...
                                 category_cat, trialsID_cat, instanceID_cat, ...
                                 'VariableNames',{...
                                   'subID','expID','onset','offset', ...
                                   'category','trialsID','instanceID'});
    
                sim_tbl_cat = [meta_cat sim_tbl_cat];
                writetable(sim_tbl_cat, output_excel, ...
                           'Sheet',sheetName,'WriteRowNames',false);
                fprintf('    Saved category %d for subID %d\n', thisCAT, subID);
            else
                note = sprintf('No utterances for category %d', thisCAT);
                sim_tbl_cat = table(subID, expID(1), {note}, ...
                              'VariableNames',{'subID','expID','Note'});
                writetable(sim_tbl_cat, output_excel, ...
                           'Sheet',sheetName,'WriteRowNames',false);
                fprintf('    Blank sheet for category %d\n', thisCAT);
            end
        end
    end
    
    fprintf('\nAll sub‑ID & category sheets exported!\n');
    
    
    
    %% ================== EXP LEVEL ===========================================
    fprintf('\n Calculating similarity score in exp level ... \n');
    
    % 1) LOAD + CLEAN (entire experiment)
    u = string(data{:,utt_col});
    u = strip(u);                           % trim whitespace
    u = replace(u, ';', '');                % drop semicolons
    u = lower(u);                           % lowercase
    u = regexprep(u,'\s+',' ');             % collapse spaces
    
    meta = table(data{:,subID_col}, data{:,expID_col}, data{:,onset_col}, data{:,offset_col}, ...
                 data{:,cat_col}, data{:,trialsID_col}, data{:,instanceID_col}, ...
        'VariableNames', {'subID','expID','onset','offset', ...
                          'category','trialsID','instanceID'});
    
    % mask out empties & missing
    valid = ~ismissing(u) & u~="";
    u     = u(valid);
    meta  = meta(valid,:);
    
    % dedupe if asked
    if ~keep_dups
        [u, ia] = unique(u, 'stable');
        meta    = meta(ia,:);
    end
    
    n = numel(u);
    if n == 0
        error('No utterances left!');
    end
    
    % 2) EMBED + SIMILARITY
    emb = zeros(n, dim);
    for k = 1:n
        pe = model.encode(char(u(k)), pyargs('normalize_embeddings', false));
        fv = double(py.array.array('d', py.numpy.nditer(pe)));
        emb(k,:) = reshape(fv, 1, []);
    end
    
    % Normalize & cosine sim
    norms    = vecnorm(emb, 2, 2);
    emb_norm = emb ./ norms;
    sim_mat  = round(emb_norm * emb_norm.', round_dec);
    
    % 3) Build global label names
    global_labels = strcat("utt_", string(meta.subID), "_", string(meta.instanceID));
    col_names = ['utterance', matlab.lang.makeValidName(cellstr(global_labels)')];
    
    % Build global table
    utterances_col = cellstr(u);
    sim_tbl_global = array2table([utterances_col, num2cell(sim_mat)]);
    sim_tbl_global.Properties.VariableNames = col_names;
    
    % Add metadata
    sim_tbl_global = [meta sim_tbl_global];

    exp_level_excel = fullfile(output_dir, sprintf('exp%d_utt_similarity.xlsx',expID(1)));

    disp('writing overall category-level sheet...')
    
    % 4) Write per-category sheets
    cats = unique(meta.category);
    
    for c = cats'
        idx = find(meta.category == c);
        u_c      = u(idx);
        meta_c   = meta(idx,:);
        sim_c    = sim_mat(idx, idx);
        labels_c = strcat("utt_", string(meta_c.subID), "_", string(meta_c.instanceID));
    
        % Table
        tblC = array2table([cellstr(u_c), num2cell(sim_c)]);
        col_names_c = ['utterance', matlab.lang.makeValidName(cellstr(labels_c)')];
        tblC.Properties.VariableNames = col_names_c;
    
        % Add meta
        tblC = [meta_c tblC];
    
        sheet = sprintf('cat_%d', c);
        writetable(tblC, exp_level_excel, 'Sheet', sheet, 'WriteRowNames', false);
        fprintf('  Wrote %s (%d×%d)\n', sheet, numel(idx), numel(idx));
    end
    
    
    % 5) Write global sheet
    disp('writing overall exp level sheet...')
    writetable(sim_tbl_global, exp_level_excel, ...
               'Sheet','All_Utterances', ...
               'WriteRowNames',false);
    fprintf('  Wrote All_Utterances (%d×%d)\n', n, n);

    fprintf('\nExperiment workbook saved: %s\n', exp_level_excel);

end