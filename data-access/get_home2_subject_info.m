%%%
% Author: Jane Yang
% Last modifier: 2/29/2024 (Leap Day!)
% 
% Description: Return the Subj_id, Exper. #, date, and kid_id of a subj.
%   get_home2_subject_info(SUBJECT_ID)
%       Given a subject ID (a small integer, usually 1-100 or so), returns a
%       one-row array with the subject ID, the experiment number, the date of
%       the subject's experiment (in YYYYMMDD form, as a number), and the
%       kid_id of the subject.
%%%
function [ subj_info ] = get_home2_subject_info(subID)
    subTable = read_home2_subject_table();
    
    % return only the line of the table that has the first field (the subject
    % ID) equal to the search query's subject ID.
    subj_info = table2array(subTable(subTable.SubID == subID,2:end));
end