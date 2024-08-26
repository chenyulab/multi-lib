%%%
% Author: Jingwen Pang
% Last modifier: 05/13/2024
% 
% This function separate the naming events and naming measures from a csv
% file.
%
% Input Parameters:
% - num_obj: number of objects in this experiment
% - input_filename: input csv file
%
% Output
% - MAT File: A MAT file containing two variables: 'naming_events' and 'naming_measure'.
%
% Example:
% reformat_naming_event_measure(24,'../data/all_naming_onset_after3_target_exp27.mat')
%%%

function [naming_events, naming_measure] = reshape_naming_event_measure(num_obj,input_filename)

    % save them as Matlab variabe
    raw_data = csvread(input_filename, 4);
    sub_list = unique(raw_data(:,1));
    for sub = 1: length(sub_list)
        index = find(raw_data(:,1)==sub_list(sub));
        data_sub = raw_data(index,:);
        for obj = 1: num_obj
            naming_events{sub,obj} =[];
            index = find(data_sub(:,5) == obj);
            naming_events{sub,obj} = data_sub(index,1:7);
            naming_measure{sub,obj} = data_sub(index,8:end);

        end
    end

    output_filename = strrep(input_filename,'.csv','.mat');
    save(output_filename, "naming_events", "naming_measure");

end

