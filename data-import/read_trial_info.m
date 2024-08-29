function [] = read_trial_info(sub_id)
% read a trial info file and put it into .mat form
% [] = read_trial_info(sub_id)
%
% Input:    
%       fname - an info_file name
% Returns:
%    A data structure trialInfo is created with the following fields
%       camTime (1x1):    the synch time for camera
%       speechTime (1x1): the synch time for Speech
%       motionTime (1x1): the synch time for motion 
%       camRate (1x1):    the recording rate of camera
%       speechRate (1x1): the recording rate of speech 
%       trials (2xn):     onset and offset frame numbers of n trials  
%
% Description : 
%       This function reads the trial_info file and creates a new data structure and savse it in xxx_info.mat in each 
%       subject folder. 
%
%
if numel(sub_id) > 1
    for s = 1:numel(sub_id)
        read_trial_info(sub_id(s));
    end
    return
end


if isnumeric(sub_id)
	sub_dir = get_subject_dir(sub_id)
	names = dir(sprintf('%s/*_info.txt',sub_dir));
	fname = names(1).name
else
	fname = sub_id
	sub_dir = fileparts(fname);
	if isempty(sub_dir)
		sub_dir = '.';
	end
	sub_dir
end

% open the trial_info text file 
fin = fopen(sprintf('%s/%s',sub_dir,fname),'r');
if fin < 0
   error(['Could not open ',fname,' for input']);
end

% skip the header 
for i = 1 : 6
    tline = fgetl(fin);  
end;
    
% get the trial info
for i = 1 : 20 % not more than 20 trial
    tline = fgetl(fin);
    if (size(tline,2) > 2) % not empty line
        list = strread(tline, '%d','delimiter',',');
        % trials(list(1),:) = [list(2) list(3)];  
        trials(i,:) = [list(2) list(3)]; 
    else
        break;
    end;
    
end;
trialInfo.trials = trials;

% get sensor timestamp
for i = 1 : 3
    tline = fgetl(fin);  
end;
tline = fgetl(fin);
list = strread(tline, '%d','delimiter',',');
sensorHour = list(1);
sensorMin = list(2);
sensorSec = list(3);
sensorMS = list(4);
motionTime = sensorHour * 3600 + sensorMin * 60 + sensorSec + sensorMS/1000;

% get speech timestamp
for i = 1 : 4
    tline = fgetl(fin);  
end;
tline = fgetl(fin);
list = strread(tline, '%d','delimiter',',');
speechHour = list(1);
speechMin = list(2);
speechSec = list(3);
speechMS = list(4);
speechTime = speechHour * 3600 + speechMin * 60 + speechSec + speechMS/1000;
trialInfo.speechRate = list(5);

% get camera timestamp
for i = 1 : 3
    tline = fgetl(fin);  
end;
tline = fgetl(fin);
list = strread(tline, '%f','delimiter',',');
camHour = list(1);
camMin = list(2);
camSec = list(3);
camMS = list(4); 
camTime = camHour * 3600 + camMin * 60 + camSec + camMS/1000;
trialInfo.camRate = list(5);

% close input file after reading
fclose(fin);


% calculate the overall offsets
offset = 30; % 30 sec 
trialInfo.camTime = offset;
trialInfo.speechTime = (speechTime - camTime) + offset;
trialInfo.motionTime = (motionTime - camTime) + offset;
if trials(1) == 0
    trialInfo.camCountsFromZero = 1;
end


% save the file
fout = strrep(fname,'txt','mat');
save(sprintf('%s/%s',sub_dir,fout), 'trialInfo');

fout = sprintf('%s/derived/timing.mat',sub_dir);
save(fout,'trialInfo');




