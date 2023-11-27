function subjects = read_subject_table()
% Return an array containing information on each subject.
% The array has four columns:
% subject_id experiment_num date kid_id
% date is in the format YYYYMMDD
% all fields are returned as numbers.
%
% Sometimes when the file server is under heavy load, it returns spurious
% "permission denied" errors.  In this case, read_subject_table will retry
% up to 5 times, waiting a short time between tries.
%
global global_subject_table;
global global_last_read;

if isempty(global_subject_table)
    global_subject_table = load([ get_multidir_root() filesep() 'subject_table.txt']);
    global_last_read = datetime('now');
end
subjects = global_subject_table;

current = datetime('now');
one_hour = duration(0,1,0);
last_read_duration = current - global_last_read;
if last_read_duration > one_hour
    global_subject_table = []; % if it's been an hour since the last read, re-read next time
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
    
function table = do_read()
table = load([ get_multidir_root() filesep() 'subject_table.txt']);
