function varargout = INHAND_CR_GUI(varargin)
% INHAND_CR_GUI MATLAB code for INHAND_CR_GUI.fig
%      INHAND_CR_GUI, by itself, creates a new INHAND_CR_GUI or raises the existing
%      singleton*.
%
%      H = INHAND_CR_GUI returns the handle to a new INHAND_CR_GUI or the handle to
%      the existing singleton*.
%
%      INHAND_CR_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in INHAND_CR_GUI.M with the given input arguments.
%
%      INHAND_CR_GUI('Property','Value',...) creates a new INHAND_CR_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before INHAND_CR_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to INHAND_CR_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help INHAND_CR_GUI

% Last Modified by GUIDE v2.5 18-Nov-2015 11:35:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @INHAND_CR_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @INHAND_CR_GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before INHAND_CR_GUI is made visible.
function INHAND_CR_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to INHAND_CR_GUI (see VARARGIN)

% Choose default command line output for INHAND_CR_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes INHAND_CR_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

if length(varargin) > 0
	setappdata(handles.frame_1, 'CODER_NAME', varargin{1});
else
	setappdata(handles.frame_1, 'CODER_NAME', '');
end


% --- Outputs from this function are returned to the command line.
function varargout = INHAND_CR_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% SET GUI VARIABLES
setappdata(handles.frame_1, 'SAFE_MODE', 0);

% turn off ugly figure axis
set(handles.frame_1,'xcolor',get(gcf,'color'));
set(handles.frame_1,'ycolor',get(gcf,'color'));
set(handles.frame_1,'ytick',[]);
set(handles.frame_1,'xtick',[]);
set(handles.frame_2,'xcolor',get(gcf,'color'));
set(handles.frame_2,'ycolor',get(gcf,'color'));
set(handles.frame_2,'ytick',[]);
set(handles.frame_2,'xtick',[]);
set(handles.frame_3,'xcolor',get(gcf,'color'));
set(handles.frame_3,'ycolor',get(gcf,'color'));
set(handles.frame_3,'ytick',[]);
set(handles.frame_3,'xtick',[]);
set(handles.frame_2,'xcolor',get(gcf,'color'));
set(handles.frame_2,'ycolor',get(gcf,'color'));
set(handles.frame_2,'ytick',[]);
set(handles.frame_2,'xtick',[]);

set(handles.edit_frame_number, 'Enable', 'off');

% create toy thumbnail imags
thumbnails = cell(26, 1);
for i = 1:length(thumbnails)-2
    thumbnails{i} = imread(['toys/' num2str(i) '.jpg']);
end
thumbnails{25} = imread(['toys/none.jpg']);
thumbnails{26} = imread(['toys/face.jpg']);
thumbnails{27} = imread(['toys/other.jpg']);
imshow(thumbnails{1}, 'Parent', handles.img_1);
imshow(thumbnails{2}, 'Parent', handles.img_2);
imshow(thumbnails{3}, 'Parent', handles.img_3);
imshow(thumbnails{4}, 'Parent', handles.img_4);
imshow(thumbnails{5}, 'Parent', handles.img_5);
imshow(thumbnails{6}, 'Parent', handles.img_6);
imshow(thumbnails{7}, 'Parent', handles.img_7);
imshow(thumbnails{8}, 'Parent', handles.img_8);
imshow(thumbnails{9}, 'Parent', handles.img_9);
imshow(thumbnails{10}, 'Parent', handles.img_10);
imshow(thumbnails{11}, 'Parent', handles.img_11);
imshow(thumbnails{12}, 'Parent', handles.img_12);
imshow(thumbnails{13}, 'Parent', handles.img_13);
imshow(thumbnails{14}, 'Parent', handles.img_14);
imshow(thumbnails{15}, 'Parent', handles.img_15);
imshow(thumbnails{16}, 'Parent', handles.img_16);
imshow(thumbnails{17}, 'Parent', handles.img_17);
imshow(thumbnails{18}, 'Parent', handles.img_18);
imshow(thumbnails{19}, 'Parent', handles.img_19);
imshow(thumbnails{20}, 'Parent', handles.img_20);
imshow(thumbnails{21}, 'Parent', handles.img_21);
imshow(thumbnails{22}, 'Parent', handles.img_22);
imshow(thumbnails{23}, 'Parent', handles.img_23);
imshow(thumbnails{24}, 'Parent', handles.img_24);
imshow(thumbnails{25}, 'Parent', handles.img_none);
%imshow(thumbnails{26}, 'Parent', handles.img_face);
imshow(thumbnails{27}, 'Parent', handles.img_other);


% --- Executes on button press in pushbutton1.
function button_none_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_none, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 0);
update_INHAND_DATA(handles);

% --- Executes on button press in button_1.
function button_1_Callback(hObject, eventdata, handles)
% hObject    handle to button_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_1, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 1);
update_INHAND_DATA(handles);

% --- Executes on button press in button_2.
function button_2_Callback(hObject, eventdata, handles)
% hObject    handle to button_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_2, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 2);
update_INHAND_DATA(handles);

% --- Executes on button press in button_3.
function button_3_Callback(hObject, eventdata, handles)
% hObject    handle to button_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_3, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 3);
update_INHAND_DATA(handles);

% --- Executes on button press in button_4.
function button_4_Callback(hObject, eventdata, handles)
% hObject    handle to button_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_4, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 4);
update_INHAND_DATA(handles);

% --- Executes on button press in button_5.
function button_5_Callback(hObject, eventdata, handles)
% hObject    handle to button_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_5, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 5);
update_INHAND_DATA(handles);

% --- Executes on button press in button_6.
function button_6_Callback(hObject, eventdata, handles)
% hObject    handle to button_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_6, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 6);
update_INHAND_DATA(handles);

% --- Executes on button press in button_7.
function button_7_Callback(hObject, eventdata, handles)
% hObject    handle to button_7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_7, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 7);
update_INHAND_DATA(handles);

% --- Executes on button press in button_8.
function button_8_Callback(hObject, eventdata, handles)
% hObject    handle to button_8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_8, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 8);
update_INHAND_DATA(handles);

% --- Executes on button press in button_9.
function button_9_Callback(hObject, eventdata, handles)
% hObject    handle to button_9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_9, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 9);
update_INHAND_DATA(handles);

% --- Executes on button press in button_10.
function button_10_Callback(hObject, eventdata, handles)
% hObject    handle to button_10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_10, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 10);
update_INHAND_DATA(handles);

% --- Executes on button press in button_11.
function button_11_Callback(hObject, eventdata, handles)
% hObject    handle to button_11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_11, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 11);
update_INHAND_DATA(handles);

% --- Executes on button press in button_12.
function button_12_Callback(hObject, eventdata, handles)
% hObject    handle to button_12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_12, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 12);
update_INHAND_DATA(handles);

% % --- Executes on button press in button_face.
% function button_face_Callback(hObject, eventdata, handles)
% % hObject    handle to button_face (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% resetButtonColors(handles);
% set(handles.button_face, 'BackgroundColor','green');
% setappdata(handles.frame_1, 'INHAND', 25);
% update_INHAND_DATA(handles);

% --- Executes on button press in button_13.
function button_13_Callback(hObject, eventdata, handles)
% hObject    handle to button_13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_13, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 13);
update_INHAND_DATA(handles);

% --- Executes on button press in button_14.
function button_14_Callback(hObject, eventdata, handles)
% hObject    handle to button_14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_14, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 14);
update_INHAND_DATA(handles);


% --- Executes on button press in button_15.
function button_15_Callback(hObject, eventdata, handles)
% hObject    handle to button_15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_15, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 15);
update_INHAND_DATA(handles);

% --- Executes on button press in button_16.
function button_16_Callback(hObject, eventdata, handles)
% hObject    handle to button_16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_16, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 16);
update_INHAND_DATA(handles);

% --- Executes on button press in button_17.
function button_17_Callback(hObject, eventdata, handles)
% hObject    handle to button_17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_17, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 17);
update_INHAND_DATA(handles);

% --- Executes on button press in button_18.
function button_18_Callback(hObject, eventdata, handles)
% hObject    handle to button_18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_18, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 18);
update_INHAND_DATA(handles);

% --- Executes on button press in button_19.
function button_19_Callback(hObject, eventdata, handles)
% hObject    handle to button_19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_19, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 19);
update_INHAND_DATA(handles);

% --- Executes on button press in button_20.
function button_20_Callback(hObject, eventdata, handles)
% hObject    handle to button_20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_20, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 20);
update_INHAND_DATA(handles);

% --- Executes on button press in button_21.
function button_21_Callback(hObject, eventdata, handles)
% hObject    handle to button_21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_21, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 21);
update_INHAND_DATA(handles);

% --- Executes on button press in button_22.
function button_22_Callback(hObject, eventdata, handles)
% hObject    handle to button_22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_22, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 22);
update_INHAND_DATA(handles);

% --- Executes on button press in button_23.
function button_23_Callback(hObject, eventdata, handles)
% hObject    handle to button_23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_23, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 23);
update_INHAND_DATA(handles);

% --- Executes on button press in button_24.
function button_24_Callback(hObject, eventdata, handles)
% hObject    handle to button_24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_24, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 24);
update_INHAND_DATA(handles);

% --- Executes on button press in button_other.
function button_other_Callback(hObject, eventdata, handles)
% hObject    handle to button_other (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resetButtonColors(handles);
set(handles.button_other, 'BackgroundColor','green');
setappdata(handles.frame_1, 'INHAND', 26);
update_INHAND_DATA(handles);

% --- Executes on button press in button_load.
function button_load_Callback(hObject, eventdata, handles)
% hObject    handle to button_load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[subject_dir] = uigetdir('/raid/projects/multiwork/experiment_12/included', 'Select a Subject Directory');
[~, subject, ~] = fileparts(subject_dir);
frames = dir([subject_dir '/cam07_frames_p/*.jpg']);
num_frames = length(frames);
% DEBUG
%num_frames = min(num_frames, 6000);

% SET ALL IMPORTANT GUI VARIABLES
setappdata(handles.frame_1, 'NUM_FRAMES', num_frames);
setappdata(handles.frame_1, 'SUBJECT_DIR', subject_dir);
setappdata(handles.frame_1, 'SUBJECT', subject);

% CECK IF DATA EXISTS
coder_name = getappdata(handles.frame_1, 'CODER_NAME');
if isempty(coder_name)
	existing_data = [subject_dir '/extra_p/' subject '_CR_INHAND.mat'];
else
	existing_data = [subject_dir '/extra_p/' subject '_CR_INHAND_' coder_name '.mat'];
end
if exist(existing_data) == 2
	load(existing_data); % INHAND_DATA
	setappdata(handles.frame_1, 'INHAND_DATA', INHAND_DATA);
	last_coded = get_last_frame_coded(handles);
	setappdata(handles.frame_1, 'CURRENT_FRAME', last_coded);
	setappdata(handles.frame_1, 'INHAND', INHAND_DATA(last_coded).INHAND);
	highlightButton(handles, INHAND_DATA(last_coded).INHAND);
else
	% SET UP DATA VARIABLE
	INHAND_DATA = struct();
	for f = 1:num_frames
	  INHAND_DATA(f).frame_name = ['img_' num2str(f) '.jpg'];
	  INHAND_DATA(f).INHAND = 0;
	  INHAND_DATA(f).is_coded = 0;
	end
	setappdata(handles.frame_1, 'INHAND_DATA', INHAND_DATA);
	setappdata(handles.frame_1, 'CURRENT_FRAME', 1);
	setappdata(handles.frame_1, 'INHAND', 0);
end
assignin('base', 'INHAND_DATA', INHAND_DATA);

initialize_image_objects(handles);

update_GUI_controlls(handles);
update_GUI_views(handles);

% --- Executes on button press in button_next.
function button_next_Callback(hObject, eventdata, handles)
% hObject    handle to button_next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
current_frame = getappdata(handles.frame_1, 'CURRENT_FRAME');
num_frames = getappdata(handles.frame_1, 'NUM_FRAMES');
if current_frame < num_frames
	setappdata(handles.frame_1, 'CURRENT_FRAME', current_frame+1);
	update_INHAND_DATA(handles, current_frame:current_frame+1);

	update_GUI_controlls(handles);
	update_GUI_views(handles);
end


% --- Executes on button press in button_next_3.
function button_next_3_Callback(hObject, eventdata, handles)
% hObject    handle to button_next_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
current_frame = getappdata(handles.frame_1, 'CURRENT_FRAME');
num_frames = getappdata(handles.frame_1, 'NUM_FRAMES');
if current_frame + 10 <= num_frames
  setappdata(handles.frame_1, 'CURRENT_FRAME', current_frame+10);
  update_INHAND_DATA(handles, current_frame:current_frame+10);
else
  setappdata(handles.frame_1, 'CURRENT_FRAME', num_frames);
  update_INHAND_DATA(handles, current_frame:num_frames);
end
update_GUI_controlls(handles);
update_GUI_views(handles);

% --- Executes on button press in button_prev.
function button_prev_Callback(hObject, eventdata, handles)
% hObject    handle to button_prev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
current_frame = getappdata(handles.frame_1, 'CURRENT_FRAME');
if current_frame > 1
	setappdata(handles.frame_1, 'CURRENT_FRAME', current_frame-1);
	current_frame = getappdata(handles.frame_1, 'CURRENT_FRAME');
	INHAND_DATA = getappdata(handles.frame_1, 'INHAND_DATA');
	roi = INHAND_DATA(current_frame).INHAND;
	setappdata(handles.frame_1, 'INHAND', roi);
	update_GUI_controlls(handles);
	update_GUI_views(handles);
end

% --- Executes on button press in button_prev_3.
function button_prev_3_Callback(hObject, eventdata, handles)
% hObject    handle to button_prev_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
current_frame = getappdata(handles.frame_1, 'CURRENT_FRAME');
if current_frame - 10 >= 1
  setappdata(handles.frame_1, 'CURRENT_FRAME', current_frame-10);
else
  setappdata(handles.frame_1, 'CURRENT_FRAME', 1);
end
current_frame = getappdata(handles.frame_1, 'CURRENT_FRAME');
INHAND_DATA = getappdata(handles.frame_1, 'INHAND_DATA');
roi = INHAND_DATA(current_frame).INHAND;
setappdata(handles.frame_1, 'INHAND', roi);
update_GUI_controlls(handles);
update_GUI_views(handles);


function [] = update_GUI_controlls(handles)
% update subject info
subject = getappdata(handles.frame_1, 'SUBJECT');
s = sprintf('Loaded: %s', subject);
set(handles.text_loaded, 'String', s);
% update frame info
current_frame = getappdata(handles.frame_1, 'CURRENT_FRAME');
num_frames = getappdata(handles.frame_1, 'NUM_FRAMES');
s = sprintf('Frame %d/%d (%d%%)', current_frame, num_frames, round(100*current_frame/num_frames));
set(handles.text_frame_info, 'String', s);
set(handles.edit_frame_number, 'String', num2str(current_frame));
% show laste coded frame
s = sprintf('Coded until frame: %d', get_last_frame_coded(handles));
set(handles.text_last_coded, 'String', s);
% highlight ROI button
INHAND_DATA = getappdata(handles.frame_1, 'INHAND_DATA');
roi = INHAND_DATA(current_frame).INHAND;
highlightButton(handles, roi);
% if I'm in safe mode and beyond the last coded frame, disable buttons
save_mode = getappdata(handles.frame_1, 'SAFE_MODE');
if save_mode && current_frame > get_last_frame_coded(handles)
	toggleButtons(handles, 'off');
else
	toggleButtons(handles, 'on');
end

function [] = update_GUI_views(handles)
subject_dir = getappdata(handles.frame_1, 'SUBJECT_DIR');
current_frame = getappdata(handles.frame_1, 'CURRENT_FRAME');
img_child = imread([subject_dir '/cam07_frames_p/img_' num2str(current_frame) '.jpg']);
img_third = imread([subject_dir '/cam03_frames_p/img_' num2str(current_frame) '.jpg']);
img_third = img_third(60:420, :, :); % crop black bars
img_parent = imread([subject_dir '/cam08_frames_p/img_' num2str(current_frame) '.jpg']);

s = getappdata(handles.frame_1, 's');
v = getappdata(handles.frame_1, 'v');
e = getappdata(handles.frame_1, 'e');

set(s,'CData', img_child);
set(v,'CData', img_parent);
set(e,'CData', img_third);


function [] = resetButtonColors(handles)
grey = [0.941 0.941 0.941];
set(handles.button_1, 'BackgroundColor', grey); %240 240 240
set(handles.button_2, 'BackgroundColor', grey);
set(handles.button_3, 'BackgroundColor', grey);
set(handles.button_4, 'BackgroundColor', grey);
set(handles.button_5, 'BackgroundColor', grey);
set(handles.button_6, 'BackgroundColor', grey);
set(handles.button_7, 'BackgroundColor', grey);
set(handles.button_8, 'BackgroundColor', grey);
set(handles.button_9, 'BackgroundColor', grey);
set(handles.button_10, 'BackgroundColor', grey);
set(handles.button_11, 'BackgroundColor', grey);
set(handles.button_12, 'BackgroundColor', grey);
set(handles.button_13, 'BackgroundColor', grey);
set(handles.button_14, 'BackgroundColor', grey);
set(handles.button_15, 'BackgroundColor', grey);
set(handles.button_16, 'BackgroundColor', grey);
set(handles.button_17, 'BackgroundColor', grey);
set(handles.button_18, 'BackgroundColor', grey);
set(handles.button_19, 'BackgroundColor', grey);
set(handles.button_20, 'BackgroundColor', grey);
set(handles.button_21, 'BackgroundColor', grey);
set(handles.button_22, 'BackgroundColor', grey);
set(handles.button_23, 'BackgroundColor', grey);
set(handles.button_24, 'BackgroundColor', grey);
set(handles.button_none, 'BackgroundColor', grey);
%set(handles.button_face, 'BackgroundColor', grey);
set(handles.button_other, 'BackgroundColor', grey);

function [] = update_INHAND_DATA(handles, frames);
safe_mode = getappdata(handles.frame_1, 'SAFE_MODE');
% safe mode only allows changing current frame, i.e. calls where frames argument is empty
if nargin < 2
	f = getappdata(handles.frame_1, 'CURRENT_FRAME');
	INHAND_DATA = getappdata(handles.frame_1, 'INHAND_DATA');
	ROI = getappdata(handles.frame_1, 'INHAND');
	INHAND_DATA(f).INHAND = ROI;
else
	INHAND_DATA = getappdata(handles.frame_1, 'INHAND_DATA');
	if ~safe_mode
		ROI = getappdata(handles.frame_1, 'INHAND');
		num_frames = getappdata(handles.frame_1, 'NUM_FRAMES');
		for f = frames
			INHAND_DATA(f).INHAND = ROI;
			INHAND_DATA(f).is_coded = 1;
		end
		% reset future frames in normal mode
		for f = frames(end)+1:num_frames
			INHAND_DATA(f).INHAND = 0;
			INHAND_DATA(f).is_coded = 0;
		end
	end
end
% update data internally
assignin('base', 'INHAND_DATA', INHAND_DATA);
setappdata(handles.frame_1, 'INHAND_DATA', INHAND_DATA);
% ... and save file
coder_name = getappdata(handles.frame_1, 'CODER_NAME');
subject_name = getappdata(handles.frame_1, 'SUBJECT');
subject_dir = getappdata(handles.frame_1, 'SUBJECT_DIR');
cstream_inhand = data_to_cstream(INHAND_DATA);
if isempty(coder_name)
	save([subject_dir '/extra_p/' subject_name '_CR_INHAND.mat'], 'INHAND_DATA');
  % save([subject_dir '/derived/cstream_inhand_child_right.mat'], 'cstream_inhand');
  record_variable(get_subject_id_from_folder(handles), 'cstream_inhand_child_right', cstream_inhand);
else
	save([subject_dir '/extra_p/' subject_name '_CR_INHAND_' coder_name '.mat'], 'INHAND_DATA');
  % save([subject_dir '/extra_p/cstream_inhand_child_right_' coder_name '.mat'], 'cstream_inhand');
  record_variable_into_specified_directory(get_subject_id_from_folder(handles), 'extra_p', ['cstream_inhand_child_right_' coder_name], cstream_inhand);
end

% DEBUG 
% roi = [INHAND_DATA(:).INHAND];
% coded = logical([INHAND_DATA(:).is_coded]);
% roi = roi(coded);
% [1:length(roi); roi]

function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
switch eventdata.Key
  case 'rightarrow'
    button_next_3_Callback(hObject, eventdata, handles);
  case 'leftarrow'
    button_prev_3_Callback(hObject, eventdata, handles);
  case 'uparrow'
    button_prev_Callback(hObject, eventdata, handles);
  case 'downarrow'
    button_next_Callback(hObject, eventdata, handles);
end



function edit_frame_number_Callback(hObject, eventdata, handles)
% hObject    handle to edit_frame_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_frame_number as text
%        str2double(get(hObject,'String')) returns contents of edit_frame_number as a double
jump_to = str2double(get(hObject,'String'));
num_frames = getappdata(handles.frame_1, 'NUM_FRAMES');

if isnumeric(jump_to) && ~isempty(num_frames) && jump_to >= 1 && jump_to <= num_frames
  setappdata(handles.frame_1, 'CURRENT_FRAME', jump_to);
  update_GUI_controlls(handles);
  update_GUI_views(handles);
end

% --- Executes during object creation, after setting all properties.
function edit_frame_number_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_frame_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in safe_mode_box.
function safe_mode_box_Callback(hObject, eventdata, handles)
% hObject    handle to safe_mode_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of safe_mode_box
safe_mode = get(hObject,'Value');

if safe_mode
	%toggleButtons(handles, 'off');
	setappdata(handles.frame_1, 'SAFE_MODE', 1);
	set(handles.edit_frame_number, 'Enable', 'on');
else
	set(handles.edit_frame_number, 'Enable', 'off');
	%toggleButtons(handles, 'on');
	setappdata(handles.frame_1, 'SAFE_MODE', 0);

	% if current frame > last coded frame, go to last coded frame automatically
	%once save mode is turned 'off'
	last_coded = get_last_frame_coded(handles);
	current_frame = getappdata(handles.frame_1, 'CURRENT_FRAME');
	if current_frame > last_coded
		setappdata(handles.frame_1, 'CURRENT_FRAME', last_coded);
		INHAND_DATA = getappdata(handles.frame_1, 'INHAND_DATA');
		setappdata(handles.frame_1, 'INHAND', INHAND_DATA(last_coded).INHAND);
		update_GUI_views(handles);
		update_GUI_controlls(handles);
	end
end

function [] = toggleButtons(handles, state)
set(handles.button_1, 'Enable', state); 
set(handles.button_2, 'Enable', state); 
set(handles.button_3, 'Enable', state); 
set(handles.button_4, 'Enable', state); 
set(handles.button_5, 'Enable', state); 
set(handles.button_6, 'Enable', state); 
set(handles.button_7, 'Enable', state); 
set(handles.button_8, 'Enable', state); 
set(handles.button_9, 'Enable', state);
set(handles.button_10, 'Enable', state);
set(handles.button_11, 'Enable', state); 
set(handles.button_12, 'Enable', state); 
set(handles.button_13, 'Enable', state); 
set(handles.button_14, 'Enable', state); 
set(handles.button_15, 'Enable', state); 
set(handles.button_16, 'Enable', state); 
set(handles.button_17, 'Enable', state); 
set(handles.button_18, 'Enable', state); 
set(handles.button_19, 'Enable', state); 
set(handles.button_20, 'Enable', state); 
set(handles.button_21, 'Enable', state); 
set(handles.button_22, 'Enable', state); 
set(handles.button_23, 'Enable', state); 
set(handles.button_24, 'Enable', state); 
set(handles.button_none, 'Enable', state); 
%set(handles.button_face, 'Enable', state); 
set(handles.button_other, 'Enable', state);

function [] = highlightButton(handles, toy_id)
resetButtonColors(handles);
switch toy_id
	case 0
		set(handles.button_none, 'BackgroundColor','green');
	case 1
		set(handles.button_1, 'BackgroundColor','green');
	case 2
		set(handles.button_2, 'BackgroundColor','green');
	case 3
		set(handles.button_3, 'BackgroundColor','green');
	case 4
		set(handles.button_4, 'BackgroundColor','green');
	case 5
		set(handles.button_5, 'BackgroundColor','green');
	case 6
		set(handles.button_6, 'BackgroundColor','green');
	case 7
		set(handles.button_7, 'BackgroundColor','green');
	case 8
		set(handles.button_8, 'BackgroundColor','green');
	case 9
		set(handles.button_9, 'BackgroundColor','green');
	case 10
		set(handles.button_10, 'BackgroundColor','green');
	case 11
		set(handles.button_11, 'BackgroundColor','green');
	case 12
		set(handles.button_12, 'BackgroundColor','green');
	case 13
		set(handles.button_13, 'BackgroundColor','green');
	case 14
		set(handles.button_14, 'BackgroundColor','green');
	case 15
		set(handles.button_15, 'BackgroundColor','green');
	case 16
		set(handles.button_16, 'BackgroundColor','green');
	case 17
		set(handles.button_17, 'BackgroundColor','green');
	case 18
		set(handles.button_18, 'BackgroundColor','green');
	case 19
		set(handles.button_19, 'BackgroundColor','green');
	case 20
		set(handles.button_20, 'BackgroundColor','green');
	case 21
		set(handles.button_21, 'BackgroundColor','green');
	case 22
		set(handles.button_22, 'BackgroundColor','green');
	case 23
		set(handles.button_23, 'BackgroundColor','green');
	case 24
		set(handles.button_24, 'BackgroundColor','green');
	% case 25
	% 	set(handles.button_face, 'BackgroundColor','green');
	otherwise
		set(handles.button_other, 'BackgroundColor','green');
end

function last_coded = get_last_frame_coded(handles)
INHAND_DATA = getappdata(handles.frame_1, 'INHAND_DATA');
% HACK WHILE PEOPE ARE TESTING PROGRAM (!)
% last_coded = length(find([INHAND_DATA(:).is_coded] == 1));
last_coded = max(find([INHAND_DATA(:).is_coded] == 1));
if last_coded == 0
	last_coded = 1;
end

function [] = initialize_image_objects(handles)
subject_dir = getappdata(handles.frame_1, 'SUBJECT_DIR');
current_frame = getappdata(handles.frame_1, 'CURRENT_FRAME');
img_child = imread([subject_dir '/cam07_frames_p/img_' num2str(current_frame) '.jpg']);
img_third = imread([subject_dir '/cam03_frames_p/img_' num2str(current_frame) '.jpg']);
img_third = img_third(60:420, :, :); % crop black bars
img_parent = imread([subject_dir '/cam08_frames_p/img_' num2str(current_frame) '.jpg']);

s = imshow(img_child, 'Parent', handles.frame_1);
v = imshow(img_parent, 'Parent', handles.frame_2);
e = imshow(img_third, 'Parent', handles.frame_3);
% set(s,'EraseMode','none');
% set(e,'EraseMode','none');
% set(n,'EraseMode','none');
setappdata(handles.frame_1, 's', s);
setappdata(handles.frame_1, 'v', v);
setappdata(handles.frame_1, 'e', e);

function [cstream_inhand] = data_to_cstream(INHAND_DATA)
is_coded = [INHAND_DATA(:).is_coded] == 1;
index = 1:length(find(is_coded));
time = (index-1) * 1/30 + 30;
inhand = [INHAND_DATA(is_coded).INHAND];
cstream_inhand = [time' inhand'];

function subject_id = get_subject_id_from_folder(handles)
folder = getappdata(handles.frame_1, 'SUBJECT');
tempy = strsplit(folder, '_');
s_date = str2num(tempy{2});
s_id = str2num(tempy{3});
table = read_subject_table();
s_r = find(table(:,3) == s_date & table(:,4) == s_id);
if isempty(s_r)
  error('Cannot find subject id in subject table');
else
  subject_id = table(s_r, 1)
end