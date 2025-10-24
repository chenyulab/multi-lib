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
%   category for each event 
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
        
        sameCount = zeros(height(cevent),1);
        diffCount = zeros(height(cevent),1);
        %ceventTempType = strings(height(cevent),1);
        ceventTempType = zeros(height(cevent),6);
    
        for j = 1:height(cevent)
            currChunk = chunks{j};
            onBound = currChunk(:,1) >= expandCevent(j,1);
            offBound = currChunk(:,2) <= expandCevent(j,2);
            
            boundCurrChunk = currChunk(onBound & offBound,:);
            broadCastNaming = repmat(cevent(j,:),height(boundCurrChunk),1);
        
            mask = sum(broadCastNaming == boundCurrChunk,2);
        
            sameCountInst = sum(mask == 1);
            diffCountInst = sum(mask == 0);
        
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
        
            sameCount(j) = sameCountInst;
            diffCount(j) = diffCountInst;
            ceventTempType(j,:) = [expID sub cevent(j,:) tempType];
        end
        ceventTypewrite = [ceventTypewrite; ceventTempType];
        
        if isempty(plot_dir)
            continue
        end
        
        celldata = cell(1,5);
        labels = cell(1,5);
    
        for k = 1:numel(varNames)
            labels{k} = varNames{k};
            dataMask = ceventTempType(:,6) == k;
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

    headers = {'expID','subID','onset','offset','cat','temp-cat'};
    ceventTypeWrite = [headers; num2cell(ceventTypewrite)];
    writecell(ceventTypeWrite, output_name)
end
