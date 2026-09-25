function make_entropy_vars(subexpIDs)
    
    cstreams = {'cstream_eye_roi_child', 'cstream_eye_roi_parent', 'cstream_inhand-eye_child-child', 'cstream_inhand-eye_child-parent', ...
                'cstream_inhand-eye_parent-parent', 'cstream_inhand-eye_parent-child'};
    measureTypes = {'shannon', 'transition'};
    var_names = {'cont_eye_roi_entropy-shannon-30s_child', 'cont_eye_roi_entropy-transition-30s_child', 'cont_eye_roi_entropy-shannon-30s_parent', ...
                 'cont_eye_roi_entropy-transition-30s_parent', 'cont_inhand-eye_entropy-shannon-30s_child-child', 'cont_inhand-eye_entropy-transition-30s_child-child', ...
                 'cont_inhand-eye_entropy-shannon-30s_child-parent', 'cont_inhand-eye_entropy-transition-30s_child-parent', 'cont_inhand-eye_entropy-shannon-30s_parent-parent', ...
                 'cont_inhand-eye_entropy-transition-30s_parent-parent', 'cont_inhand-eye_entropy-shannon-30s_parent-child', 'cont_inhand-eye_entropy-transition-30s_parent-child'};
    fps = 30;
    windowSize = 30; % seconds
    windowSamples = round(windowSize * fps);
    stride = 1; % frames

    
    % %% ++++++++++++++++++++++++++++++++++++++++++++++++++++++ NEED TO CHANGE ALL 3
    % cstream = 'cstream_inhand-eye_parent-child';
    % measureType = "shannon";
    % var_name = 'cont_inhand-eye_entropy-shannon-30s_parent-child'; 
    % %% ++++++++++++++++++++++++++++++++++++++++++++++++++++++

    subexpIDs = subexpIDs(:);
    subs = [];

    for e = 1:numel(subexpIDs)
        currentSubs = cIDs(subexpIDs(e));
        subs = [subs; currentSubs(:)]; 
    end

    subs = unique(subs, 'stable');

    for s = 1:numel(subs)

        subID = subs(s);

        for cs = 1:numel(cstreams)

            cstream = cstreams{cs};

            try
                dataByTrial = get_variable_by_trial(subID, cstream);
            catch ME
                warning("Couldn't load for sub %d: %s", subID, ME.message)
                continue
            end

            if isempty(dataByTrial);warning("No data found for sub %d", subID);continue;end

            for mT = 1:numel(measureTypes)
                
                measureType = measureTypes{mT};

                varIdx = (cs - 1) * numel(measureTypes) + mT;

                var_name = var_names{varIdx};
                
                allTimes = [];
                allEntropy = [];
        
                for t = 1:numel(dataByTrial)
                    trialData = dataByTrial{t};
                    if isempty(trialData); continue; end
        
                    trialTimes = trialData(:, 1);
                    trialValues = trialData(:, 2);
        
                    numSamples = numel(trialValues);
                    
                    trialEntropy = nan(numSamples, 1);
            
                    if numSamples >= windowSamples
                        windowStarts = 1:stride:(numSamples - windowSamples + 1);
            
                        for i = 1:numel(windowStarts)
                            startIdx = windowStarts(i);
                            endIdx = startIdx + windowSamples - 1;
            
                            sequence = trialValues(startIdx:endIdx);
                            sequence = sequence(isfinite(sequence));
            
                            if isempty(sequence); continue; end
            
                            entropyValue = calculateDynamicMeasure(sequence, measureType);
            
                            centerIdx = startIdx + floor((windowSamples - 1)/2);
            
                            trialEntropy(centerIdx) = entropyValue;
                        end
                    end
        
                    if ~isempty(allTimes)
                        previousTrialEnd = allTimes(end);
                        currentTrialStart = trialTimes(1);
        
                        dt = 1 / fps;
        
                        gapStart = previousTrialEnd + dt;
                        gapEnd = currentTrialStart - dt;
        
                        if gapStart <= gapEnd
                            gapTimes = (gapStart:dt:gapEnd)';
        
                            allTimes = [allTimes; gapTimes];
                            allEntropy = [allEntropy; nan(numel(gapTimes), 1)];
                        end
                    end
        
            
                    allTimes = [allTimes; trialTimes];
                    allEntropy = [allEntropy; trialEntropy];
                end
                data = double([allTimes, allEntropy]);
        
                record_additional_variable(subID, var_name, data);
            end
        end
    end
end

%% HELPER -- Calculate Entropy Measure (calls function for entropy type)
function value = calculateDynamicMeasure(sequence, measureType)
    sequence = sequence(isfinite(sequence));
    if isempty(sequence); value = NaN; return; end
    
    switch measureType
        % Shannon Entropy
        case 'shannon'
            [values, ~, groupID] = unique(sequence);
            counts = accumarray(groupID, 1);
            probabilities = counts / sum(counts);
            value = -sum(probabilities .* log2(probabilities));
    
            % Transition Entropy
        case 'transition'
            value = transitionBasedEntropy(sequence);
    
        otherwise
            error('Unknown Dynamic Measure: %s', measureType);
    end

end


%% HELPER -- Transition Based Entropy (Conditional Entropy)
function transEn = transitionBasedEntropy(sequence)
    if length(sequence) < 2; transEn = NaN; return; end
    
    currentROI = sequence(1:end-1);
    nextROI = sequence(2:end);
    
    % H(X) : entropy of current states
    [~, ~, currentID] = unique(currentROI);
    currentCounts = accumarray(currentID, 1);
    currentProbabilities = currentCounts / sum(currentCounts);
    entropyCurrent = -sum(currentProbabilities .* log2(currentProbabilities));
    
    % H(X, Y): join entropy of transition pairs
    transitions = [currentROI(:) nextROI(:)];
    [~, ~, transitionID] = unique(transitions, 'rows');
    transitionCounts = accumarray(transitionID, 1);
    jointProbabilities = transitionCounts / sum(transitionCounts);
    jointEntropy = -sum(jointProbabilities .* log2(jointProbabilities));
    
    % H(Y|X) = H(X, Y) - H(X)
    transEn = jointEntropy - entropyCurrent;
end