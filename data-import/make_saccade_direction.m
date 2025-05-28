%function to get saccades direction from xy data 

%make_saccade_direction(351, 'cevent2_eye_fixation_xy_parent',agent, 'Z:\bryanna\eye_direction_gen\direction_351')

function make_saccade_direction(subexpID)
    
    agents = {'child','parent'};

    if ~exist('pathname', 'var')
        pathname = false;
    end
    sub_list = cIDs(subexpID);
   

    for i = 1:length(sub_list)
        subID = sub_list(i);
        for a = 1: length(agents)
            agent = agents{a};
            % get eye gaze variable data
            gaze_varname = sprintf('cevent2_eye_fixation_xy_%s',agent);
            gaze_data = get_variable_by_trial_cat(subID, gaze_varname);

        if ~isempty(gaze_data) 
          
            rad_90 = pi/2;
            rad_180 = pi;
            rad_270 = 1.5*pi;
        
            results = {}; 
        
            row_idx = 1;
        
            for j = 1:(height(gaze_data)-1)
                if ~any(isnan(gaze_data(j, 3:4))) && ~any(isnan(gaze_data(j+1, 3:4))) %make sure the current x1, y1 and x2, y2 have data 

                        results(row_idx,1) = num2cell(gaze_data(j,2));
                        results(row_idx,2) = num2cell(gaze_data(j+1,1));

                        %x1,y1 has valid data 
                        x1 = gaze_data(j,3);
                        y1 = gaze_data(j,4);
        
                        %x2 y2 has valid data 
                        x2 = gaze_data(j+1,3);
                        y2 = gaze_data(j+1,4);
        
                        if x1 < x2 
        
                            if y1 < y2
        
                                direction = rad_180 - atan((x2-x1)/(y2-y1));
        
                            elseif y1 > y2
        
                                direction = atan((x2-x1)/(y1-y2));
        
                            else
                                direction = rad_90;
                            end
        
                        elseif x1 == x2
                            if y1 < y2
                                direction = rad_180;
        
                            elseif y1 > y2
                                direction = 0;
        
                            else
                                direction = 0; %should this be Nan
                            end
        
                        else %x1 > x2
                            if y1 < y2
                                direction = rad_180 + atan((x1-x2)/(y2-y1));
        
                            elseif y1 > y2
        
                                direction = rad_270 + atan((y1-y2)/(x1-x2));
        
                            else
                                direction = rad_270;
                            end
                        end
        
                        direction = rad2deg(direction);
                        results{row_idx, 3} = direction;
        
                        row_idx = row_idx +1; 
                end
            end
                sdata = results;
                varname = sprintf('cevent1_eye_saccade_direction_%s',agent);
                record_additional_variable(subID,varname,sdata);
        else
            fprintf('%d %s gaze data is empty',subID,agent);
        end   
        end
    end

end




