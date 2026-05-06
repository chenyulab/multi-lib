% output_dir = '.\data';
% 
% Set experiment and variables
% subexpID = 15;
% base_var = 'cevent_speech_utterance';
% depend_vars = {'cevent_eye_roi_child','cevent_inhand_child','cevent_eye_roi_parent','cevent_inhand_parent'};
% 
% Set up extract_multi_measures args
% obj_num = get_num_obj(subexpID);
% args.cevent_name = base_var;
% args.label_matrix = ones(obj_num) * 2 + diag(-ones(obj_num,1));
% args.label_names = {'target', 'other'};
% args.cevent_values = 1:(obj_num + 1);  % Include non-naming utterances
% 
% Run extract_multi_measures
% emm_csv = fullfile(output_dir, sprintf('exp%d_child_attention_inhand_within_speech.csv', subexpID));
% extract_multi_measures(depend_vars, subexpID, emm_csv, args);
% 
% Define first-word list and get object labels
% first_words = {'a', 'the', 'this', 'that'};
% obj_ids = 1:obj_num;
% obj_names = get_object_label(subexpID, obj_ids);
% instead of using object label, use object naming words
% T = readtable(fullfile(get_experiment_dir(subexpID),'object_word_pairs.xlsx'));
% obj_names = unique(T.name);
% obj_names = obj_names(~cellfun(@(x) isempty(x) || all(isspace(x)), obj_names));
% 
% Loop over all first words
% for w = 1:length(first_words)
%     fw = first_words{w};
% 
%     Helper function to generate keyword list
%     build_keyword_list = @(joiner) cellfun(@(name) [fw, joiner, name], obj_names, 'UniformOutput', false);
% 
%     Direct sequence (e.g., 'the car') ---
%     args.target_words = build_keyword_list(' ');
%     disp(args.target_words)
%     ess_csv_1 = fullfile(output_dir, sprintf('exp%d_speech_%s+obj.csv', subexpID, fw));
%     extract_speech_in_situ(subexpID, base_var, obj_ids, ess_csv_1, args);
% 
%     output_csv_1 = fullfile(output_dir, sprintf('exp%d_child_attention_inhand_within_speech_%s+obj.csv', subexpID, fw));
%     filter_extracted_instances(emm_csv, ess_csv_1, output_csv_1);
% 
%     Wildcard sequence (e.g., 'the * car') ---
%     args.target_words = build_keyword_list(' * ');
%     ess_csv_2 = fullfile(output_dir, sprintf('exp%d_speech_%s+X+obj.csv', subexpID, fw));
%     extract_speech_in_situ(subexpID, base_var, obj_ids, ess_csv_2, args);
% 
%     output_csv_2 = fullfile(output_dir, sprintf('exp%d_child_attention_inhand_within_speech_%s+X+obj.csv', subexpID, fw));
%     filter_extracted_instances(emm_csv, ess_csv_2, output_csv_2);
% end


output_dir = '.\data';
subexpID = 15;
% Set experiment and variables
base_var = 'cevent_speech_utterance';
depend_vars = {'cevent_eye_roi_child','cevent_inhand_child','cevent_eye_roi_parent','cevent_inhand_parent'};
% Set up extract_multi_measures args
obj_num = get_num_obj(subexpID);
args.cevent_name = base_var;
args.label_matrix = ones(obj_num) * 2 + diag(-ones(obj_num,1));
args.label_names = {'target', 'other'};
args.cevent_values = 1:obj_num;
args.whence = 'start'; % the point of reference, which is either the 'start' of the cevent (onset), or the 'end' of the cevent (offset)
args.interval = [0 3];
% Run extract_multi_measures
emm_csv = fullfile(output_dir, sprintf('exp%d_child_attention_inhand_within_speech.csv', subexpID));
extract_multi_measures(depend_vars, subexpID, emm_csv, args);
% Define first-word list and get object labels
first_words = {'a', 'the', 'this', 'that'};
obj_ids = 1:obj_num;
% obj_names = get_object_label(subexpID, obj_ids);
% instead of using object label, use object naming words
T = readtable(fullfile(get_experiment_dir(subexpID),'object_word_pairs.xlsx'));
obj_names = unique(T.name);
obj_names = obj_names(~cellfun(@(x) isempty(x) || all(isspace(x)), obj_names));
patterns = {' ', ' * '};
%
%
% Loop over all first words
for p = 1 : length(patterns)
for w = 1:length(first_words)
fw = first_words{w};
% Helper function to generate keyword list
build_keyword_list = @(joiner) cellfun(@(name) [fw, joiner, name], obj_names, 'UniformOutput', false);
% Direct sequence (e.g., 'the car') ---
args.target_words = build_keyword_list(patterns{p});
disp(args.target_words)
ess_csv = fullfile(output_dir, sprintf('exp%d_speech_%s+obj_%d.csv', subexpID, fw,p));
extract_speech_in_situ(subexpID, base_var, obj_ids, ess_csv, args);
output_csv = fullfile(output_dir, sprintf('exp%d_child_attention_inhand_within_speech_%s+obj_%d.csv', subexpID, fw,p));
filter_extracted_instances(emm_csv, ess_csv, output_csv);
end
end