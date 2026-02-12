function [cellOfVectors,words_during_pages_table] = create_cell_of_vectors(expID)    % main directory
    % main directory
    main_dir = fullfile(get_multidir_root, 'extracted_datasets','project_book_reading_vector');
    
    warning('off','stats:pdist2:ZeroPoints')

    num_pages = get_num_pages(expID);

    % Initialize a cell array to hold vectors
    cellOfVectors = cell(3,num_pages);
    
    %% attention
    %run extract_multi_measures/emm
    var_list = 'cevent_eye_roi_child';
    filename = [];    
    args.cevent_measures = 'individual_prop_by_cat';
    args.cevent_name = 'cevent_pages';
    args.cevent_values = 1:num_pages;
    [emm_matrix,emm_header] = extract_multi_measures(var_list,expID,filename,args);
    
    %create table from emm
    filter_page_header = split(emm_header(4),',');
    emm_table = array2table(emm_matrix,"VariableNames",filter_page_header);
    
    %write to cellOfVectors
    for page = 1:num_pages
        filter_page_idx = emm_table.category == page;
        rois_on_page = get_rois_on_page(expID,page);
        filter_table_col_idx = ['subID',arrayfun(@(x) ['cat-' num2str(x)],rois_on_page,'UniformOutput',false)]; %columns to keep, exclude category col
        filter_page_mat2_header = ["subID",split(num2str(rois_on_page))'];
        filter_page_mat2 = [cellstr(filter_page_mat2_header);table2cell(emm_table(filter_page_idx,filter_table_col_idx))]; %as cell
        cellOfVectors{1,page} = filter_page_mat2;
    end
    
    %% saliency 
    % get directories for obj masks and saliency
    obj_mask_dir = fullfile(main_dir,"Book_Saliency\page_obj_masks",num2str(expID));
    saliency_dir = fullfile(main_dir,"Book_Saliency\page_heatmaps",num2str(expID));        

    % Load object vectors
    obj_size_vector     = cal_page_obj_size_vectors(obj_mask_dir);
    obj_saliency_vector = cal_page_obj_saliency_vectors(saliency_dir,obj_mask_dir);

    % Construct saliency vectors
    for page = 1:num_pages
        rois_on_page = get_rois_on_page(expID,page);
        saliency_data = vertcat( ...
            rois_on_page, ...
            obj_size_vector{page}(2,:), ...
            obj_saliency_vector{page}(3,:) ...
            );

        %add labels onto data
        saliency_data_labeled = [{"roi";"obj_size";"obj_saliency"},num2cell(saliency_data)];
        
        cellOfVectors{2,page} = saliency_data_labeled; % Store saliency data in the cell array
    end
    
    %% speech
    %extract speech during pages
    cevent_var = 'cevent_pages';
    category_list = 1:num_pages;
    output_dir = fullfile(main_dir,"Bookreading_Attention\Output_Files"); 
    output_filename = sprintf('exp_%d_speech_during_page.csv',expID);
    output_filepath = char(fullfile(output_dir,output_filename));
    extract_speech_in_situ(expID,cevent_var,category_list,output_filepath); %outputs stuff to console
    
    %turn extracted speech into table variable
    utterances_during_pages_table = readtable(output_filepath); 
    cleaned_utts = strrep(utterances_during_pages_table.utterances,';','');
    split_utts = arrayfun(@(x) split(x,' '),cleaned_utts,'UniformOutput',false);
    nostopwords = cellfun(@(x) x(~ismember(x,stopWords)),split_utts,'UniformOutput',false);
    words_during_pages_table = addvars(utterances_during_pages_table,split_utts,'NewVariableNames','wordlist');
    words_during_pages_table = addvars(words_during_pages_table,cleaned_utts,'NewVariableNames','cleaned_utts');
    words_during_pages_table = addvars(words_during_pages_table,nostopwords,'NewVariableNames','wordlist_filtered');
    
    %numberbatch embeddings
    load(fullfile(main_dir,'Semantic_Similarity\numberbatch-en.mat'),'embeddingtable')
    %merge dimensions into 1 table column, as 1x300 cell
    num_dimensions = width(embeddingtable);
    embeddingtable = mergevars(embeddingtable,1:num_dimensions);
    embeddingtable.Var1 = table2cell(embeddingtable);

    function vocablist_embeddings = get_word_embeddings(vocablist_word)
        vocablist_id = 1:numel(vocablist_word);

        %check if word in vocablist has numberbatch embedding
        wordincluded_mask = ismember(vocablist_word,embeddingtable.Row);
        wordexcluded_mask = ~wordincluded_mask;
        wordincluded_list = vocablist_word(wordincluded_mask);
        wordincluded_list_word = wordincluded_list(:);
        wordincluded_list_id = vocablist_id(wordincluded_mask);
        wordexcluded_list_id = vocablist_id(wordexcluded_mask);

        %get embeddings for all included words
        wordincluded_embeddings = embeddingtable(wordincluded_list_word,:);

        %fill embeddings with zero vectors for words with no embeddings
        vocablist_embeddings(wordincluded_list_id) = table2cell(wordincluded_embeddings);
        vocablist_embeddings(wordexcluded_list_id) = mat2cell(zeros(1,num_dimensions),1);

        %all vocablist embeddings
        vocablist_embeddings = vertcat(vocablist_embeddings{:});
    end
    
    %write to cellOfVectors
    for page = 1:num_pages
        rois_on_page = get_rois_on_page(expID,page);
        obj_word_list = cellstr(get_object_label(expID,rois_on_page));
        sublist = words_during_pages_table{words_during_pages_table.category == page,"subID"};
    
        speech_vector_table = cellstr(["subID",split(num2str(rois_on_page))']);
    
        vocablist_embeddings2 = get_word_embeddings(obj_word_list);

        for sub_idx = 1:numel(sublist)
            sub = sublist(sub_idx);
    
            %get vocablist
            vocablist_word = words_during_pages_table(words_during_pages_table.category == page,:);
            vocablist_word = vocablist_word{sub_idx,"wordlist_filtered"}{1};
    
            %get spoken words embeddings
            vocablist_embeddings1 = get_word_embeddings(vocablist_word);
    
            %calculate cosine similarity
            sem_sim_matrix = 1 - pdist2(vocablist_embeddings1,vocablist_embeddings2,"cosine");

            %get sums of columns
            sem_sim_matrix = fillmissing(sem_sim_matrix,"constant",0); %replace nan with 0
            sub_speech_vector = num2cell([sub,sum(sem_sim_matrix,1)]); %sum each column
            speech_vector_table(sub_idx + 1,:) = sub_speech_vector; %assign to table
        end
        cellOfVectors{3,page} = speech_vector_table;
    end
    
    %add labels to outermost cell
    cellOfVectors = vertcat(num2cell(1:num_pages),cellOfVectors);
    vector_labels = {"page";"attention";"saliency";"speech"};
    cellOfVectors = horzcat(vector_labels,cellOfVectors);
    
    %save variable as .mat file
    save_var_name = sprintf("exp%d_bookvector",expID);
    savedata.(save_var_name) = cellOfVectors;
    output_filename2 = fullfile(main_dir,'data',sprintf('%s.mat',save_var_name)); %placeholder before output to multiwork
    % output_filename2 = fullfile(main_dir,save_var_name);
    save(output_filename2,'-struct',"savedata")
end

function rtr_list = get_num_pages(subexpIDs,varargin)
    exp_ids = [];
    for s = 1:length(subexpIDs)
        id = subexpIDs(s);
        try
            sub_list = list_subjects(id);  % try to get subject list
            exp_ids = [exp_ids, id];
        catch
            exp_ids = [exp_ids, sub2exp(id)];
        end
    end
    rtr_list = [];
    for e = 1:length(exp_ids)
        exp = exp_ids(e);
        stim = fullfile(get_experiment_dir(exp), 'mapping_file2.xlsx');
        try
            stim_data = readtable(stim);
        catch
            error('mapping_file2.xlsx file not found under experiment directory')
        end
        num_pages = stim_data{end,2};
    end
    rtr_list = [rtr_list, num_pages];
end

function [list_rois] = get_rois_on_page(expID,page_num)
    try
        pages_table = readtable(fullfile(get_experiment_dir(expID),'obj_identity_by_page.csv'));
    catch
        error('obj_identity_by_page.csv file not found under experiment directory')
    end
    selected_row = pages_table((pages_table.exp == expID & pages_table.pg == page_num),:);
    roi_idx = (selected_row ~= 0);
    list_rois_table = selected_row(:,roi_idx{:,:});
    list_rois_str = strrep(list_rois_table.Properties.VariableNames(3:end),'cat_',''); %remove exp and pg columns
    list_rois = str2double(list_rois_str);
end

function obj_size_vector = cal_page_obj_size_vectors(folder_path)
% Reads binary mask images named: pageX-objID-objName.jpg
% For each page, computes object pixel counts, then normalizes by the
% total object pixels on that page:
%   prop(obj) = obj_pixels / sum_obj_pixels_on_page
%
% Output:
%   obj_size_vector{pageID} = [obj_id_vec; prop_size_vec]

    files = dir(fullfile(folder_path, '*.jpg'));
    
    % page_map: pageID -> (obj_map), where obj_map: objID -> obj_pixels (count)
    page_map = containers.Map('KeyType','double','ValueType','any');
    
    for i = 1:length(files)
        fname = files(i).name;
    
        % Parse filename: pageX-objID-objName.jpg
        tokens = regexp(fname, '^page(\d+)-(\d+)-.*\.jpg$', 'tokens', 'once');
        if isempty(tokens)
            warning('Skipping file with unexpected name: %s', fname);
            continue;
        end
    
        pageID = str2double(tokens{1});
        objID  = str2double(tokens{2});
    
        % Read mask
        img = imread(fullfile(folder_path, fname));
        if ndims(img) == 3
            img = rgb2gray(img);
        end
    
        % Binary mask: background is 0, object is nonzero
        obj_pixels = nnz(img > 0);
    
        % Init inner map if needed
        if ~isKey(page_map, pageID)
            page_map(pageID) = containers.Map('KeyType','double','ValueType','double');
        end
    
        % Store pixel counts (not ratios)
        obj_map = page_map(pageID);
        obj_map(objID) = obj_pixels;
        page_map(pageID) = obj_map;
    end
    
    % Convert to cell output
    page_keys = sort(cell2mat(keys(page_map)));
    obj_size_vector = {};
    
    for idx = 1:numel(page_keys)
        p = page_keys(idx);
        obj_map = page_map(p);
    
        obj_ids = sort(cell2mat(keys(obj_map)));
        pix_vec = zeros(1, numel(obj_ids));
        for k = 1:numel(obj_ids)
            pix_vec(k) = obj_map(obj_ids(k));
        end
    
        total_pix = sum(pix_vec);
        if total_pix > 0
            prop_vec = pix_vec ./ total_pix;
        else
            prop_vec = zeros(size(pix_vec)); % or NaN(size(...)) if you prefer
        end
    
        obj_size_vector{p} = vertcat(obj_ids, prop_vec);
    end

end

function page_obj_saliency_cell = cal_page_obj_saliency_vectors(heat_dir,mask_dir)
% get_page_object_saliency_vectors
%
% For each page, sum heatmap saliency values within each object mask,
% then normalize each object's saliency by the total saliency across
% all objects on that page.
%
% Folder structure:
%   main_dir/
%       obj mask/
%           pageX-X-objName.jpg
%       obj saliency heatmap/
%           Page_01_heatmap.png
%
% Output:
%   page_obj_saliency_cell{p} = [obj_id_vec; saliency_sum_vec; saliency_norm_vec]

    mask_files = dir(fullfile(mask_dir, '*.jpg'));

    % ---- parse mask filenames ----
    page_ids = [];
    obj_ids  = [];
    mask_paths = {};

    for i = 1:numel(mask_files)
        fname = mask_files(i).name;
        tok = regexp(fname, '^page(\d+)-(\d+)-.*\.jpg$', 'tokens', 'once');
        if isempty(tok)
            warning('Skipping mask with unexpected name: %s', fname);
            continue;
        end

        page_ids(end+1) = str2double(tok{1}); 
        obj_ids(end+1)  = str2double(tok{2}); 
        mask_paths{end+1} = fullfile(mask_dir, fname); 
    end

    pages = unique(page_ids);
    page_obj_saliency_cell = cell(1, numel(pages));

    % ---- process each page ----
    for p = 1:numel(pages)
        pageID = pages(p);

        idx = find(page_ids == pageID);
        objID_vec = obj_ids(idx);
        mask_vec  = mask_paths(idx);

        % find heatmap for this page
        heatmap_path = find_heatmap(heat_dir, pageID);
        if isempty(heatmap_path)
            warning('No heatmap found for page %d', pageID);
            page_obj_saliency_cell{p} = [];
            continue;
        end

        % heatmap is already grayscale (lighter = higher saliency)
        heatmap = imread(heatmap_path);
        if ndims(heatmap) == 3
            heatmap = rgb2gray(heatmap);
        end
        heatmap = double(heatmap);

        saliency_sum = zeros(1, numel(objID_vec));

        for k = 1:numel(objID_vec)
            mask = imread(mask_vec{k});

            % convert mask to logical
            if ndims(mask) == 3
                mask = rgb2gray(mask);
            end
            mask = mask > 0;

            % resize mask if needed
            if ~isequal(size(mask), size(heatmap))
                mask = imresize(mask, size(heatmap), 'nearest');
            end

            saliency_sum(k) = sum(heatmap(mask), 'all');
        end

        % normalize within page (handle all-zero safely)
        total_sal = sum(saliency_sum);
        if total_sal > 0
            saliency_norm = saliency_sum ./ total_sal;
        else
            saliency_norm = zeros(size(saliency_sum)); % or NaN(size(...)) if you prefer
        end

        % sort by object ID
        [objID_vec, order] = sort(objID_vec);
        saliency_sum  = saliency_sum(order);
        saliency_norm = saliency_norm(order);

        page_obj_saliency_cell{p} = [objID_vec; saliency_sum; saliency_norm];
    end
end

% ---------- helper for cal_page_obj_saliency_vectors ----------
function heatmap_path = find_heatmap(heat_dir, pageID)

    candidates = {
        sprintf('Page_%02d_heatmap.png', pageID)
        sprintf('Page_%d_heatmap.png', pageID)
        sprintf('page_%02d_heatmap.png', pageID)
        sprintf('page_%d_heatmap.png', pageID)
    };

    heatmap_path = '';

    for i = 1:numel(candidates)
        p = fullfile(heat_dir, candidates{i});
        if exist(p, 'file')
            heatmap_path = p;
            return;
        end
    end
end