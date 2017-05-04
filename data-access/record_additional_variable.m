function [ filename ] = record_additional_variable( subject_id, variable_name, data )
%Records the given data under the given subject and name.
%   record_variable(SUBJECT_ID, VARIABLE_NAME, DATA)
%
%   Finds the filename that the data should be recorded in, using
%   get_variable_path.  Then, creates the little structure that goes in
%   that file, and records the data there using MATLAB's SAVE function.
%
%   If the given variable name does not have documentation, for now the
%   function will complain, but eventually the data will not be saved in
%   the requested place, but instead will be put in a temporary directory.
%
%   The return value is the filename where the data was saved.
%

if is_core_variable(variable_name)
    fprintf('====== NOT SAVED ========\n');
    warning('%s is a core variable, cannot overwrite', variable_name);
    fprintf('=========================\n');
    return;
end

filename = get_variable_path(subject_id, variable_name);

if isempty(getenv('IU_username'))
    IU_username = input('enter IU username: ', 's');
    setenv('IU_username', IU_username);
end

sdata.variable = variable_name;
sdata.data = data;
sdata.info.stack = get_stack();
sdata.info.timestamp = datestr(now);
sdata.info.subject = subject_id;
sdata.info.path = filename;
sdata.info.hostname = getenv('computername');
sdata.info.user = getenv('IU_username');

record_variable_log(sdata);

save(filename, 'sdata');
fprintf('Saved variable "%s" for subject %d\n', variable_name, subject_id);

end



function stack = get_stack()
try
    error('Caught');
catch ME
    stack = ME.stack(2:end); % don't show get_stack() on the list
end
end