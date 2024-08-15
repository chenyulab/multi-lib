%%%
% Author: Jane Yang
% Last Modified: 07/03/2024
% This function genenerates secondary known/unknown naming/inhand/eye
% variables by selecting subsets of each of the input variables
% based on a binary mapping file. The binary file indicates which objects
% or names of the objects were known to a kid.
%
% Input: subexpIDs     - a list of subject or experiment IDs
%        var_list      - a list of base vars to generate known/unknown
%                        vars from
%        mapping_file  - a CSV file indicating the binary mapping of
%                        which object was known to the kid
%        type          - a list indicating types of known/unknown
%                        vars one wants to create: {'toys','words'}
%                        This will also be the var name extension at the 
%                        end.
%
% Dependent function calls: kid2sid(kidIDs)
% 
% Example function call: make_known_unknown_vars(35125, {'cevent_inhand_child','cevent_inhand_parent','cevent_eye_roi_child','cevent_eye_roi_parent'}, 'M:\HOME_survey.xlsx',{'toys','words'})
%%%

function make_known_unknown_vars(subexpIDs, var_list, mapping_file, type)

    % hard-coded index for accessing the right tab in the survey excel file
    toyMapIdx = 3;
    formatOut = 'yyyymmdd'; % format template for study session's date
    dateCol = 1;
    kidIDCol = 2;
    mapStartCol = 3;
    subInfoColCount = 2;

    % check if input type is valid
    if ~any(ismember(type,{'toys','words'}))
        error('Please input a valid type: toys or/and words.');
    end
    
    % get a list of subjects
    subs = cIDs(subexpIDs);
    
    % read survey mapping file
    survey = readtable(mapping_file,'sheet',toyMapIdx);
    ism = ismissing(survey);
    survey(sum(ism,2)==size(survey,2),:) = []; % remove empty rows
    
    % parse subject mapping info from the survey data
    % copy = rmmissing(survey); % filter out objID header row
    date = str2num(datestr(survey{2:end,dateCol},formatOut));
    kidID = survey{2:end,kidIDCol};
    subInfo = horzcat(date,kidID);
    
    % split the rest of survey into two matrices: one for toy objects,
    % one for toy names
    surveyMap = survey{:,mapStartCol:end};
    surveyMapTranspose = sortrows(surveyMap',1); % sort mapping based on objIDs
    surveyMap = surveyMapTranspose';
    surveyMap = surveyMap(2:end,:); % remove the objID row
    surveyMap = horzcat(subInfo,surveyMap); % concate subject info to the mapping matrix
    
    % iterate thru subject list
    for s = 1:length(subs)
        subID = subs(s);
    
        currSubInfo = get_subject_info(subID);
        subDate = currSubInfo(3);
        subKID = currSubInfo(4);
    
        % find the row in mapping matrix for current subject
        subMap = surveyMap(surveyMap(:,dateCol)==subDate&surveyMap(:,kidIDCol)==subKID,:);
    
        if ~isempty(subMap)
            % iterate through survey question types and generate known/unknown vars
            for m = 1:size(type,2)
                currType = type{m};
        
                % choose the mapping file based on the type
                if strcmp(currType,'toys')
                    subNewMap = horzcat(subMap(1:2),subMap(3:2:end-1)); % odd columns for toy-object mapping, starting from the 3rd column
                elseif strcmp(currType,'words')
                    subNewMap = horzcat(subMap(1:2),subMap(4:2:end));% even columns for toy-words mapping, starting from the 4th column
                else
                    error('Please input a valid type: toys or/and words.');
                end
    
                score2_obj = find(subNewMap==2) - subInfoColCount; % subtract by the offset of two subject info columns -> 3rd column index means object 1
                score1_obj = find(subNewMap==1) - subInfoColCount; % subtract by the offset
                score0_obj = find(subNewMap==0) - subInfoColCount; % subtract by the offset
    
                % sanity check
                if (width(score2_obj) + width(score1_obj) + width(score0_obj)) ~= width(subNewMap(:,mapStartCol:end))
                    error('Numbers of known and unknown objects don''t add up!');
                end
    
                % iterate through variable list
                for j = 1:length(var_list)
                    % make a copy of the current base var
                    base_var = get_variable(subID,var_list{j});
    
                    % create score2 var
                    score2_var = base_var(ismember(base_var(:,3),score2_obj),:);
                    % create score1 var
                    score1_var = base_var(ismember(base_var(:,3),score1_obj),:);
                    % create score0 var
                    score0_var = base_var(ismember(base_var(:,3),score0_obj),:);
    
                    % record known-0/1/2 variables
                    score2_varname_base = strcat('_','known-',type{m},'-2');
                    score1_varname_base = strcat('_','known-',type{m},'-1');
                    score0_varname_base = strcat('_','known-',type{m},'-0');
                    var_split = strsplit(var_list{j},'_');
    
                    if strcmp(var_split(end),'child') || strcmp(var_split(end),'parent')
                        score2_varname = strcat(strjoin(var_split(1:end-1),'_'),score2_varname_base,'_',var_split{end});
                        score1_varname = strcat(strjoin(var_split(1:end-1),'_'),score1_varname_base,'_',var_split{end});
                        score0_varname = strcat(strjoin(var_split(1:end-1),'_'),score0_varname_base,'_',var_split{end});
                    else
                        score2_varname = strcat(var_list{j},score2_varname_base);
                        score1_varname = strcat(var_list{j},score1_varname_base);
                        score0_varname = strcat(var_list{j},score0_varname_base);
                    end
    
                    record_variable(subID,score2_varname,score2_var);
                    record_variable(subID,score1_varname,score1_var);
                    record_variable(subID,score0_varname,score0_var);
                end
            end
        else
            fprintf("Subject %d doesn't have survey info!\n",subID);
        end
    end
end