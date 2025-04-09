%%%
% Author: Jingwen Pang
% Date: 2/14/2025
%
% this function read a csv file, map the cat values based on the
% mapped cat value list.
% 
% input parameters:
%   - input_csv
%           string, input csv name;
%   - cat_col
%           integer, cat value column number;
%   - orig_cat
%           num list, original cat value list;
%   - map_cat
%           num list, mapped cat value list 
%           (must be the same length as the orignal cat value list);
%   - output_csv
%           string, output csv name;
%   - start_row (optional)
%           integer, row number to skip (default is 0);
%
% output:
%   - a csv file with replaced cat values
%
%%%
function remap_cat_values(input_csv,cat_col,orig_cat,map_cat,output_csv,start_row)
    
    if ~exist("start_row","var")
        start_row = 0;
    end
    
    if length(orig_cat) ~= length(map_cat)
        error("The original category value list must be the same length as the new category value list.")
    end
    
    data = readtable(input_csv, 'NumHeaderLines', start_row);
    
    for i = 1:size(data,1)
        value = data{i,cat_col};
        idx = orig_cat(:) == value;
        data{i,cat_col} = map_cat(idx);
    end
    
    writetable(data,output_csv);

end