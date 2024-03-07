%%%
% Author: Jane Yang
% Last modifier: 2/29/2024 (Leap Day!)
% 
% Description: This function is a helper function that read the
% HOME2_general_subject_info.csv file in Multiwork.
%%%
function subjects = read_home2_subject_table()
    global global_home2_subject_table;
    
    if isempty(global_home2_subject_table)
        global_home2_subject_table = readtable([ get_multidir_root() filesep() 'HOME2_general_subject_info.csv']);
        global_last_read = datetime('now');
    end
    
    global_home2_subject_table = readtable([get_multidir_root() filesep() 'HOME2_general_subject_info.csv']);
    global_last_read = datetime('now');
    
    subjects = global_home2_subject_table;
    
    current = datetime('now');
    one_hour = duration(1,0,0);
    last_read_duration = current - global_last_read;
    if last_read_duration > one_hour
        global_home2_subject_table = []; % if it's been an hour since the last read, re-read next time
    end
    
    return;
    
    for tries = 1:5
        try
            subjects = do_read();
            break
        catch ReadError
            if strcmp(ReadError.identifier, 'MATLAB:load:permissionDenied')
                fprintf('Error reading subject table, retrying %d\n', tries);
                pause(0.5);
            else
                throw(ReadError)
            end
        end
    end

    table = load([ get_multidir_root() filesep() 'home2_subject_table.txt']);

