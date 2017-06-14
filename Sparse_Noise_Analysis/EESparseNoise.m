function varargout = EESparseNoise(varargin)
% EESPARSENOISE MATLAB code for EESparseNoise.fig
%      EESPARSENOISE, by itself, creates a new EESPARSENOISE or raises the existing
%      singleton*.
%
%      H = EESPARSENOISE returns the handle to a new EESPARSENOISE or the handle to
%      the existing singleton*.
%
%      EESPARSENOISE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EESPARSENOISE.M with the given input arguments.
%
%      EESPARSENOISE('Property','Value',...) creates a new EESPARSENOISE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before EESparseNoise_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to EESparseNoise_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EESparseNoise

% Last Modified by GUIDE v2.5 09-Mar-2017 15:52:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @EESparseNoise_OpeningFcn, ...
                   'gui_OutputFcn',  @EESparseNoise_OutputFcn, ...
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


% --- Executes just before EESparseNoise is made visible.
function EESparseNoise_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EESparseNoise (see VARARGIN)

% Choose default command line output for EESparseNoise
handles.output = hObject;

% Ask the user to inidcate what file has to be analyzed.

[handles.fileName,handles.PathName,FilterIndex] = uigetfile('*_signals.mat','Choose experiment');

% Upload the mask

handles.fileMask = strrep(handles.fileName, '_signals.mat', '.segment');
handles.fileAlign = strrep(handles.fileName, '_signals.mat', '.align');

handles.dataFile = load ([handles.PathName handles.fileName], '-mat');
handles.dataMask = load ([handles.PathName handles.fileMask], '-mat');
handles.dataAlign = load ([handles.PathName handles.fileAlign], '-mat');

% Show the image and the mask on the GUI

handles.Im1 = imshow(mat2gray(handles.dataAlign.m), 'parent',handles.axes_2Pimage);
hold on
handles.maskAx = cat(3,handles.dataMask.mask,handles.dataMask.mask*0,handles.dataMask.mask*0);
% handles.Im2 = imshow (handles.maskAx, 'parent',handles.axes_2Pimage);
% alpha(handles.Im2,0.3);
handles.CellmaskAx = handles.maskAx*0;
handles.Im3 = imshow (handles.CellmaskAx, 'parent',handles.axes_2Pimage);
alpha(handles.Im3,0.2);
hold off

% Create the list of cell that will be in the listbox

for k = 1 : numel(handles.dataMask.vert)
  handles.listbox1.String(k) = {strcat('Cell_',num2str(k))};
end

% Determine the behavior of the CellHighLight buttom

set(handles.Im3,'ButtonDownFcn',{@CellHighLight,handles});

% Upload the dF/F

[handles.time, handles.Diode, handles.StimMatrix, handles.Signals, handles.Vistim, handles.WhereImgIs, handles.TimeStamp, handles.VistimWave ]...
    = UpLoadforEE (handles.fileName,handles.PathName,1);

handles.CellNumber = handles.listbox1.Value;

a = linspace(handles.WhereImgIs(1,1),handles.WhereImgIs(1,2),length(handles.Signals.sig(:,handles.CellNumber)))';
b = handles.Signals.sig(:,handles.CellNumber);
c = (b - min(b)) / (max(b) - min (b));
c = c* 25  + 15;
handles.FullTrace = plot (handles.axes_FullTrace, a, c, handles.time,handles.VistimWave);
handles.axes_FullTrace.YLim = [-2,inf];

% Analyse Receptive Field

BaseWindow = str2double(handles.edit1.String);
DurWindow = str2double(handles.edit2.String);
ShiftWindow = str2double(handles.edit3.String);


[handles.EvokedResponse, handles.AverageMatrix] = CrossCorrelEESN(handles, BaseWindow, DurWindow, ShiftWindow);

handles.CloseCells = handles.dataMask.mask;

% % for i=1:numel(handles.dataMask.vert)
% %     
% %     handles.CloseCells(handles.CloseCells == i) = handles.RelativePosition(1,i);
% %  
% % end


SignificanceThreshold = str2double(handles.edit4.String);

BlackSquares = handles.EvokedResponse(1:120,:);
WhiteSquares = handles.EvokedResponse(121:end,:);

ReceptiveFieldB = reshape(BlackSquares(:,handles.CellNumber),8,[]) -SignificanceThreshold;
ReceptiveFieldW = reshape(WhiteSquares(:,handles.CellNumber),8,[]) -SignificanceThreshold;
ReceptiveFieldB(ReceptiveFieldB<0) = 0;
ReceptiveFieldW(ReceptiveFieldW<0) = 0;

%ReceptiveField = ReceptiveFieldW - ReceptiveFieldB;

axes(handles.axes_TraceByORI);
handles.suplot1 = subplot(1,3,1);
image(ReceptiveFieldW,'CDataMapping','scaled');
handles.suplot2 = subplot(1,3,2);
image(ReceptiveFieldB,'CDataMapping','scaled');

ReceptiveFieldB = imresize(ReceptiveFieldB,10);
ReceptiveFieldB = imgaussfilt(ReceptiveFieldB, 10);
ReceptiveFieldW = imresize(ReceptiveFieldW,10);
ReceptiveFieldW = imgaussfilt(ReceptiveFieldW, 10);

ReceptiveField = imfuse(ReceptiveFieldB,ReceptiveFieldW);

%ReceptiveField = reshape(mean(handles.EvokedResponse(:,:),2),8,[]);
%ReceptiveField = imresize(ReceptiveField,10);
%ReceptiveField = imgaussfilt(ReceptiveField, 2);
handles.suplot3 = subplot(1,3,3);

image(ReceptiveField);%,'CDataMapping','scaled');

InvGray = flipud(gray);
colormap (handles.suplot1, 'gray');
colormap (handles.suplot2, InvGray);
%colormap (handles.suplot3, 'parula');
handles.output = handles;

%axes(handles.axes7);
%figure

InfoLoc = handles.uipanel4;

l = 1:120;
l = reshape(l,8,[]);
l = reshape(l',1,[]);

k=121:240;
k = reshape(k,8,[]);
k = reshape(k',1,[]);

subplotPOP(8,15,'Gap',[0.01 0.01],'XTickL','Margin','YTickL','Margin','InfoLoc', InfoLoc);

for i=1:120
   
    subplotPOP(i)% h{i} = subplot(8,15,i) 
    plot(handles.AverageMatrix(:,handles.CellNumber,l(i)),'-b');
    plot(handles.AverageMatrix(:,handles.CellNumber,k(i)),'-m');
    axis([-inf,inf,-1,10]);
end






% Update handles structure
guidata(hObject, handles);

% UIWAIT makes EESparseNoise wait for user response (see UIRESUME)
% uiwait(handles.figure1);


function CellHighLight(hObject, eventdata, handles)

handles = guidata (hObject);

%cursor_info.Position
cursorPoint = get(handles.axes_2Pimage, 'CurrentPoint');
handles.CellNumber = handles.dataMask.mask(round(cursorPoint(1,2)),round(cursorPoint(1,1)));


if (handles.CellNumber>0)
handles.listbox1.Value = handles.CellNumber;
Location = handles.dataMask.vert{handles.CellNumber};
BW = poly2mask(Location(:,1),Location(:,2),...
    size(handles.dataMask.mask,1), size(handles.dataMask.mask,2));

handles.Im3.CData = cat(3,BW*0,BW,BW*0);
DisplayChosenCell(hObject, eventdata, handles)
%DisplayCrossCorrelation(hObject, eventdata, handles)
end


function DisplayChosenCell(hObject, eventdata, handles)
%handles = guidata (hObject);
a = linspace(handles.WhereImgIs(1,1),handles.WhereImgIs(1,2),length(handles.Signals.sig(:,handles.CellNumber)));
b = handles.Signals.sig(:,handles.CellNumber);
c = (b - min(b)) / (max(b) - min (b));
c = c* 25  + 15;
%handles.FullTrace = plot (handles.axes_FullTrace, a, c);

handles.FullTrace(1).XData = a';
handles.FullTrace(1).YData = c' ;

BaseWindow = str2double(handles.edit1.String);
DurWindow = str2double(handles.edit2.String);
ShiftWindow = str2double(handles.edit3.String);

[handles.EvokedResponse, handles.AverageMatrix] = CrossCorrelEESN(handles, BaseWindow, DurWindow, ShiftWindow);

BlackSquares = handles.EvokedResponse(1:120,:);
WhiteSquares = handles.EvokedResponse(121:end,:);

SignificanceThreshold = str2double(handles.edit4.String);

ReceptiveFieldB = reshape(BlackSquares(:,handles.CellNumber),8,[]) - SignificanceThreshold;
ReceptiveFieldW = reshape(WhiteSquares(:,handles.CellNumber),8,[]) - SignificanceThreshold;
ReceptiveFieldB(ReceptiveFieldB<0) = 0;
ReceptiveFieldW(ReceptiveFieldW<0) = 0;

% % % ReceptiveField = ReceptiveFieldW - ReceptiveFieldB;



%ReceptiveField = reshape(handles.EvokedResponse(:,handles.CellNumber),8,[]);
% % % ReceptiveField = imresize(ReceptiveField,10);
% % % ReceptiveField = imgaussfilt(ReceptiveField, 10);



%image(axes_TraceByORI, ReceptiveField,'CDataMapping','scaled');
handles.suplot1.Children.CData = ReceptiveFieldW;
handles.suplot1.Children.CDataMapping = 'scaled';
handles.suplot2.Children.CData = ReceptiveFieldB;
handles.suplot2.Children.CDataMapping = 'scaled';

 hFilter = fspecial('average', [2 2]);
% % % filter2(h, img);

ReceptiveFieldB = filter2(hFilter, ReceptiveFieldB);
ReceptiveFieldB = imresize(ReceptiveFieldB,10);
ReceptiveFieldB = imgaussfilt(ReceptiveFieldB, 10);
ReceptiveFieldW = filter2(hFilter, ReceptiveFieldW);
ReceptiveFieldW = imresize(ReceptiveFieldW,10);
ReceptiveFieldW = imgaussfilt(ReceptiveFieldW, 10);

ReceptiveField = imfuse(ReceptiveFieldB,ReceptiveFieldW, 'Scaling',  'joint');

handles.suplot3.Children.CData = ReceptiveField;
handles.suplot3.Children.CDataMapping = 'scaled';

%InfoLoc = handles.uipanel4;

l = 1:120;
l = reshape(l,8,[]);
l = reshape(l',1,[]);

k=121:240;
k = reshape(k,8,[]);
k = reshape(k',1,[]);


%subplotPOP(8,15,'Gap',[0.02 0.02],'XTickL','Margin','YTickL','Margin','InfoLoc', InfoLoc);

for i=1:120
   
    subplotPOP(i)% h{i} = subplot(8,15,i) 
    plot(handles.AverageMatrix(:,handles.CellNumber,l(i)),'-b');
    plot(handles.AverageMatrix(:,handles.CellNumber,k(i)),'-m');
    
    
    axis([-inf,inf,-1,10]);
end

guidata(hObject, handles);








% --- Outputs from this function are returned to the command line.
function varargout = EESparseNoise_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1

handles = guidata (hObject);
handles.CellNumber = handles.listbox1.Value;

Location = handles.dataMask.vert{handles.CellNumber};
BW = poly2mask(Location(:,1),Location(:,2),...
    size(handles.dataMask.mask,1), size(handles.dataMask.mask,2));

handles.Im3.CData = cat(3,BW*0,BW,BW*0);
DisplayChosenCell(hObject, eventdata, handles)



% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_Next.
function pushbutton_Next_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton_Prev.
function pushbutton_Prev_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Prev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.radiobutton1.Value = 1;
handles.radiobutton2.Value = 0;
handles.radiobutton3.Value = 0;

% Hint: get(hObject,'Value') returns toggle state of radiobutton1


% --- Executes on button press in radiobutton2.
function radiobutton2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.radiobutton1.Value = 0;
handles.radiobutton2.Value = 1;
handles.radiobutton3.Value = 0;

% Hint: get(hObject,'Value') returns toggle state of radiobutton2


% --- Executes on button press in radiobutton3.
function radiobutton3_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.radiobutton1.Value = 0;
handles.radiobutton2.Value = 0;
handles.radiobutton3.Value = 1;

% Hint: get(hObject,'Value') returns toggle state of radiobutton3
