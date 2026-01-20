clear; 

var_list = {'cevent_eye_roi_child'};
subexpIDs = [27]; % this can also be a list of experiments
num_objs = 24; 


for i = 1:num_objs
    varname = sprintf('cont_vision_size_obj%d_child',i);
    var_list{end+1} = varname;
end

% output file naming_expXX.csv
path = 'M:/extracted_datasets/project_csl';
filename = fullfile(path,sprintf('naming_exp%d.csv',subexpIDs));
args.cevent_name = 'cevent_speech_naming_local-id';
args.cevent_values = 1:num_objs;
args.whence = 'start'; 
args.interval = [-1 3];
args.cont_measures = 'individual_mean'; 

extract_multi_measures(var_list, subexpIDs, filename, args);