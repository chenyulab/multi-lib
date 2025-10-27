%% split one cevent into four temporal types: isolated, same, different, mixed
% see split_cevent_by_temp_type for info on input parameters 

function demo_split_cevent_by_temp_type(option)
    switch option

        case 1
            % get plots of temp types and 
            % one csv with the classification of each event 
            output_name = 'data/naming_78_start-53.csv';
            plot_dir = '';
            subexpIDs = 78;
            cevent_name = 'cevent_speech_naming_local-id';
            whence = 'start';
            interval = [-5 3];
    
            split_cevent_by_temp_type(output_name,plot_dir, subexpIDs, cevent_name, whence, interval)
        case 2
            % make the temp type variables 
            % creates four variables given a cevent
            % wil make a variable even if empty 

            subexpIDs = [77, 78, 81];
            cevent_name = 'cevent_speech_naming_local-id';
            whence = 'start';
            interval = [-5 0];

            split_cevent_by_temp_type('','',subexpIDs, cevent_name, whence, interval)

    end
end