function data = filter_cont_instance(data,min_length)
% this is a supproting function that filter the cont data, removing the
% short instance that is smaller than min length

    count = 0;
    for i = 1:size(data,1)
        if ~isnan(data(i,2))
            count = count + 1;
        else
            if count > 0 && count < min_length
                data((i-count:i-1),2) = NaN;
            end
    
            count = 0;
        end
    
    end
end