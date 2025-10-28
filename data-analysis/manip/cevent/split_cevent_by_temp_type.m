% Splits a cevent by classifying each event based on 
% the frequency of the category of the surrounding events.  
% If checks surrounding events by creating a window around the event
% based on whence and interval.
% 
%   If there are not events within the window the temporal category is
%   isolated (1)
%   If there are more events with the same category as the current event then
%   its same (2)
%   If there are more events with a different category than the current
%   event then its different (3)
%   If there are the same number of events with same and different category
%   then its mixed (4)
%
% 
%  Inputs:
%   output_name: name of the output csv file containing the temporal
%   category for each event, if empty variables will be created instead
%   
%   plot_dir: where to save the plots, if empty not plots will be saved
%   
%   subexpIDs: list of subjects or experiments
%   
%   cevent_name: name of the cevent
%   
%   interval: the size of window, positive to go forwards, negative to go
%   backwards 
%   whence: where to start the window from: start, end, startend
%           if whence == start, 
%               window onset = event onset + interval(1) 
%               window offset = event onset + inverval(2)
%           if whence == end,
%               window onset = event offset + interval(1)
%               window offset = event offset + interval(2)
%           if whence == startend
%               window onset = event onset + interval(1)
%               window offset = event offset + interval(2)
%   Outputs:
%    csv file: a file with columns on expID, subID, onset, offset, category, temporal
%    category
%    pngs: one plot for each subject 
%
%  Example call
%   output_name = 'data/naming_351_end-55.csv';
%   plot_dir = 'data/plots/naming_351_end-55';
%   subexpIDs = 351;
%   cevent_name = 'cevent_speech_naming_local-id';
%   whence = 'end';
%   interval = [-5 5];
%   split_cevent_by_temp_type(output_name,plot_dir, subexpIDs, cevent_name, whence, interval)

function split_cevent_by_temp_type(output_name,plot_dir, subexpIDs, cevent_name, whence, interval)
    %varNames = {'isolated','same > diff','same < diff','same == diff'};
    varNames = {'isolated','same','diff','mixed'};
    subs = cIDs(subexpIDs);
    
    ceventTypewrite = [];
    
    for i = 1:numel(subs)
        sub = subs(i);
        expID = sub2exp(sub);
    
        if has_variable(sub, cevent_name)
            cevent = get_variable(sub, cevent_name);
            cevent = cevent(cevent(:,1) > 0,:);
        else
            fprintf('%d missing %s\n',sub, cevent_name)
            continue
        end

        if strcmp(whence, 'start')
            newOnset = cevent(:,1) + interval(1);
            newOffset = cevent(:,1) + interval(2);
        elseif strcmp(whence, 'end')
            newOnset = cevent(:,2) + interval(1);
            newOffset = cevent(:,2) + interval(2);
        elseif strcmp(whence, 'startend')
            newOnset = cevent(:,1) + interval(1);
            newOffset = cevent(:,2) + interval(2);
        end
        expandCevent = [newOnset newOffset cevent(:,3)];
        
        chunks = event_extract_ranges(cevent, expandCevent);
        
        ceventInfo = cell(height(cevent),6);
        ceventTempType = zeros(height(cevent),1);

        for j = 1:height(cevent)
            currChunk = chunks{j};
            if height(currChunk) > 1
                chunkMask = ones(height(currChunk),1);
                currEventInChunk = find(sum(currChunk == cevent(j,:),2) == 3);
                if numel(currEventInChunk) > 1
                    currEventInChunk = currEventInChunk(1);
                end
                chunkMask(currEventInChunk) = 0;
    
                for q = 1:height(currChunk)
                    inst = currChunk(q,:);
                    % well ... 
                    % check if its out of bounds
                    if inst(1) - expandCevent(j,1) == 0 || inst(2) - expandCevent(j,2) == 0
                       row = sum(cevent(:,1) == inst(1) & cevent(:,2) == inst(2) & cevent(:,3) == inst(3));
                       if row == 0
                           chunkMask(q) = 0;
                       end

                    end
                end
                
                chunkMask = logical(chunkMask);
                boundCurrChunk = currChunk(chunkMask,:);
                
                catMask = boundCurrChunk(:,3) == cevent(j,3);
                sameCountInst = sum(catMask);
                diffCountInst = sum(~catMask);
            else
                sameCountInst = 0;
                diffCountInst = 0;
            end
            
        
            tempType = NaN;
        
            if sameCountInst == 0 && diffCountInst == 0
                %tempType = varNames{1};
                tempType = 1;
            elseif sameCountInst > diffCountInst
                %tempType = varNames{2};
                tempType = 2;
            elseif diffCountInst > sameCountInst
                %tempType = varNames{3};
                tempType = 3;
            else
                %tempType = varNames{4};
                tempType = 4;
            end
        
            if isempty(tempType)
                disp(cevent(j,:))
            end
            
            ceventTempType(j) = tempType;
            ceventInfo(j,:) = [expID sub cevent(j,1) cevent(j,2)  cevent(j,3) varNames(tempType)];
        end

        ceventTypewrite = [ceventTypewrite; ceventInfo];

        
        if isempty(output_name)
            for k = 1:numel(varNames)
                variable_name = ['cevent_speech_naming_' varNames{k}];
                data = cevent(ceventTempType == k,:);
            
                record_additional_variable(sub, variable_name, data)
            end
            continue
        end

        
        if isempty(plot_dir)
            continue
        end
        
        celldata = cell(1,5);
        labels = cell(1,5);
    
        for k = 1:numel(varNames)
            labels{k} = varNames{k};
            dataMask = ceventInfo(:,6) == k;
            celldata{k} = cevent(dataMask,:);
        end
        
        labels{5} = 'original';
        celldata{5} = cevent;
    
        
        time_window = get_chunks_for_vis(cevent(1,1)-5,cevent(end,2)+5);
        h = vis_streams_data(celldata, time_window, labels);
    
        substring = int2str(sub);
        saveas(h, sprintf('%s/%s.png',plot_dir, substring));
        close(h);
    end

    headers = {'expID','subID','onset','offset','cat','tempType'};
    ceventTypeWrite = [headers; ceventTypewrite];
    writecell(ceventTypeWrite, output_name)
end
