function result = cont_min(data)
%cont_min   Return the minimum value of the cont data.
%   res = cont_min(cont_data)
%
result = nanmin(data(:,2:end));
return;