%%%
% Author: Jane Yang
% Last Modified: 9/07/2023
% This function returns the corresponding subID of the input kidID.
%
% Input: kidIDs - one or a list of kidIDs
%
% Output: kidIDs      subIDs
%         10039       35103
%         10061       35105
%         10061       35306
%         10064       35107
%         10064       35308
%         10058       35307
% 
% Example function call: kid2sid([10039,10061,10064,10058])

function kid_sub_list = kid2sid(kidIDs)
    sub_table = read_subject_table();

    % kid_sub_list = zeros(size(kidIDs,1),2);
    % kid_sub_list(:,1) = kidIDs;

    kid_sub_list = []; % two columns --> kidID subID

    % find matching subIDs
    for i = 1:size(kidIDs,1)
        match = find(sub_table(:,4)==kidIDs(i));
        if match ~= 0
            % check how many matches, each kid has one kidID but could have
            % more than one corresponding subID

            kid_sub_list = vertcat(kid_sub_list,[repmat(kidIDs(i),size(match,1),1),sub_table(match,1)]);

            % if size(match,1) > 1
            %     for j = 1:size(match,1)
            %         kid_sub_list(i,2) = sub_table(match,1);
            % else
            %     kid_sub_list(i,2) = sub_table(match,1);
            % end
        else
            fprintf('Subject kidID %d is not in the subject table!\n',kidIDs(i));
        end
    end

    % filter out subjects that are not in the subject table yet
    kid_sub_list = kid_sub_list(kid_sub_list(:,2) ~= 0,:);
end