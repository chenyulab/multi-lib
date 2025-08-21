% given a varargin parameter, a list of fields, and default values
% it checks if the field exists in the varagin, if it doesn't it make
% defaults values for it. 
%
% Author: Elton Martinez
% Modifier: 
% Last Modified: 8/21/2025

function args = set_optional_args(args, valid_fields, default_vals)  
    % define default arguments
    if isempty(args)
        args = {};
    else
        args = args{1};
    end
    
    % assign default arguments if not passed
    for i = 1:numel(fields)
        if ~isfield(args, valid_fields{i})
            args.(valid_fields{i}) = default_vals{i};
        end
    end
end