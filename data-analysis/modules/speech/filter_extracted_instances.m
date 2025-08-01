%%
% Author: Elton Martinez
% Modifier: Elton Martinez
% Last modified: 8/1/2025
% 
% Filters the extract_multi_measures(emm) output to included only
% utterances(instances) that are extracted from the
% extract_speech_in_situ(ess) output. It also adds a keywords and utterance 
% column to the end of the emm output. 
% For this function to work properly the
% base variable in emm must match the cevent_var in ess
% 
% Input:
%  - emm_csv: 
%       the path to the extract_multi_measures file
%  - ess_csv: 
%       the path to the extract_speech_in_situ file
%  - output_name
%       the name of the output file, include .csv extension
%
% Output:
% - a csv file 
%
%%

function filter_extracted_instances(emm_csv, ess_csv, output_name)
    warning('off','MATLAB:table:ModifiedAndSavedVarnames')
    % read emm output as cell
    % to conserve header spacing 
    emm_cell = readcell(emm_csv);
    header = emm_cell(1:3,:);
    
    % turn actual data into table
    var_cols = numel(emm_cell(4,:)) - numel(emm_cell(4,1:7));
    var_names = cell(1,var_cols);

    for i = 1:var_cols
        var_names{i} = num2str(i);
    end

    unique_var_names = cat(2,emm_cell(4,1:7), var_names);
    emm = cell2table(emm_cell(5:end,:),'VariableNames', unique_var_names);
    
    % remove [<missing>] from header
    for i = 1:height(header)
        for j = 1:width(header)
            if ismissing(header{i,j})
                header{i,j} = [];
            end
        end
    end
    
    % add extract two columns for keywords and utterance 
    header = [header(1:3,1:7), cell(3,2), header(1:3,8:end)];
    
    % read ess as table
    ess = readtable(ess_csv);
    
    % do the actual join 
    shared = cell(height(ess),width(emm)+2);

    unique_subs = ess{:,"subID"};
    ess.ID = (1:height(ess))';

    for i = 1:numel(unique_subs)
        subID = unique_subs(i);
        ess_sub = ess(ess{:,"subID"} == subID,:);
        emm_sub = emm(emm{:,"#subID"} == subID,:);
        
        n = 1;
        for j = 1:height(ess_sub)
            essOnset = ess_sub{j, "onset"};

            while true
               emmOnset = emm_sub{n, "onset"};
               % if they match break
               if abs(essOnset - emmOnset) < 0.01
                   break
               % other wise keep trying 
               % since ess is a subset of emm you are 
               % guranteed a match
               else
                  n = n + 1; 
               end
            end
            gidx = ess_sub{j,"ID"};
            shared(gidx,:) = [num2cell(emm_sub{n,1:7}),ess_sub{j,{'keywords','utterances'}},num2cell(emm_sub{n,8:end})];
        end
    end    
    % concatenate header with shared instances 
    cShared = [emm_cell(4,1:7),'keywords','utterance', emm_cell(4,8:end); shared];
    shared_write = [header; cShared];
    
    % write out 
    writecell(shared_write, output_name)
    fprintf("wrote data to %s\n",output_name)
end
