%%
% Gives which objects are present in page x for experiment y
%
% Author: Elton Martinez
% Modifier: 
% Last modified: 9/12/2025
%
% Parameters:
% - expID: which experiment to return the page2obj table 
%
%%

function objsInPage = get_objsInPage(expID)
    pageDict_path = fullfile(get_multidir_root(), 'obj_nr_and_identity_by_page.csv');
    
    if ~isfile(pageDict_path)
        error("Page to object dictionary not found.\n")
    end
    
    pageDict = readtable(pageDict_path, 'ReadVariableNames',true);
    objsInPage = pageDict(pageDict{:,1} == expID,:);

    if isempty(objsInPage)
        error('experiment %d is not a book reading experiment\n', expID);
    end
end