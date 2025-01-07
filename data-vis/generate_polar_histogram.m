%%%
% Author: Bryanna
% 
% This function generates a polar histogram showing the direction of
% saccades for a subject
% 
% generate_polar_histogram generates a polar histogram indicating frequency of saccade direction for each participant
% - i.e. the direction of eye movement 
% - also generates histogram of saccade
% 
% Input:
%     subexpID: list of subjects or experiments to generate polar histograms for 
%     pathname: the path you want the histograms saved to 
% Optional Input:
%     args.direction_bins: specifies number of bins for the polar histogram
%         - list of angles in radians
%         - if not specified, sorts directions into equally spaced bins
%     args.saccade_bins: specifies number of bins for the saccade histogram
% Output:
%     polar histogram and saccade histogram written to file
%
% Filename for saccades direction is in the format: "polar_histogram_<subID>_<parent/child>_<age_at_experiment>.png"
%     Ex. "polar_histogram_35112_parent_14.1.png"
% 
% Filename for saccades histogram is in the format: "saccades_histogram_<subID>_<parent/child>_<age_at_experiment>.png"
%     Ex. "saccades_histogram_35112_parent_14.1.png"
%
% example call: generate_polar_histogram(35123, 'Z:\bryanna\polar_hist_saccades\results')
%%%
function generate_polar_histogram(subexpID, pathname, args)
    if ~exist('args', 'var')|| isempty(args)
        args = struct([]);
    end
    sub_list = cIDs(subexpID);

    for i = 1:length(sub_list)
        agents = {'child','parent'};

        age = get_age_at_exp(sub_list(i)); %add to file name and histogram name
      

        for a = 1:length(agents)
            direction_varname = sprintf('cevent1_eye_saccade_direction_%s',agents{a});
            saccades_varname = sprintf('cevent1_eye_saccade_direction_%s',agents{a});

            if has_variable(sub_list(i), direction_varname)

                direction_data = get_variable(sub_list(i),direction_varname); 
            else
                direction_data = [];
            end

            if has_variable(sub_list(i), saccades_varname)

                saccades_data = get_variable(sub_list(i), saccades_varname);
            else
                saccades_data = [];
            end

           

            if ~isempty(direction_data)
    
                directions = deg2rad(cell2mat(direction_data(:,3)));
                
                %create polar histogram
                f1 = figure;
                hps = polaraxes;
                if ~isfield(args,'direction_bins')
                    polarhistogram(directions);
                else
                    polarhistogram(directions,args.direction_bins);
                end
                hps.ThetaZeroLocation = 'top';                                  
                hps.ThetaDir = 'clockwise';
        
                title_name = sprintf('Polar Histogram of Eye Direction for %d %s age %.1f', sub_list(i), agents{a}, age);
        
                title(title_name)
                %save polar histogram to file
                file = sprintf("polar_histogram_%d_%s_%.1f.png",  sub_list(i), agents{a}, age);
                filename = fullfile(pathname, file);
                saveas(gcf, filename);
            else
                fprintf('no xy data for subject %d %s!!!\n', sub_list(i), agents{a})
            end
            if ~isempty(saccades_data)
                saccades = cell2mat(saccades_data(:,3));
                %create saccades histogram
                f2 = figure;
                if ~isfield(args,'saccade_bins')
                    histogram(saccades)
                else
                    histogram(saccades,args.saccade_bins)
                end
                
                title_name = sprintf('Histogram of Saccades for %d %s age %.1f', sub_list(i), agents{a}, age);
                title(title_name)
                
                %save saccades histogram to file
                file = sprintf("saccades_histogram_%d_%s_%.1f.png",  sub_list(i), agents{a}, age);
                filename = fullfile(pathname, file);
                saveas(gcf, filename);
    
            else
                fprintf('no saccades data for subject %d %s!!!\n', sub_list(i), agents{a})
            end
        end

    end


end




