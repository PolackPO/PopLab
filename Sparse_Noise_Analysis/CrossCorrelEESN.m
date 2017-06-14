%handles.Signals.sig(:,handles.CellNumber);

function [EvokedResponse, AverageMatrix] = CrossCorrelEESN(handles, BaseWindow, DurWindow, ShiftWindow)
Where2Put = 0;
ListofCoordinates = 11:160;
ListofCoordinates(rem(ListofCoordinates,10) == 0) = [];
ListofCoordinates(rem(ListofCoordinates,10) == 9) = [];

for k = 0:1
 
for j = 1: length(ListofCoordinates)
    
Address =    find (handles.StimMatrix(:,4)== ListofCoordinates(j) & handles.StimMatrix(:,5)== k);

if isempty(Address)
   
    Where2Put = Where2Put + 1;
    AverageMatrix(:,:,Where2Put) = AverageMatrix(:,:,Where2Put -1);
    
else

MatrixRow = 1;
Where2Put = Where2Put + 1;

   
 for i= 1:length(Address)

 
[c, IndexBaseline] = min(abs(handles.TimeStamp(:,1)-(handles.StimMatrix(Address(i),1)) + BaseWindow - ShiftWindow ));  % define the baseline as the 1.5 sec before
[c, IndexStart] = min(abs(handles.TimeStamp(:,1)-(handles.StimMatrix(Address(i),1)) - ShiftWindow )); % find begining of the traces
[c, IndexStop] = min(abs(handles.TimeStamp(:,1)-(handles.StimMatrix(Address(i),1))- DurWindow - ShiftWindow)); % find the end of the traces


    Baseline = (handles.Signals.sig(IndexBaseline - handles.WhereImgIs (1,3) + 1 : IndexStart - handles.WhereImgIs (1,3), :) + 1);
 %   X = (handles.Signals.sig(IndexStart - handles.WhereImgIs (1,3):IndexStop - handles.WhereImgIs (1,3), :));
    X = (handles.Signals.sig(IndexBaseline - handles.WhereImgIs (1,3) + 1  :   IndexStop - handles.WhereImgIs (1,3), :) + 1);

Intermediate(1:size (X,1),:,MatrixRow) = bsxfun(@minus,X,mean(Baseline,1));
MatrixRow = MatrixRow+1;

     %end
 

  end
 
 AverageMatrix(1:size (Intermediate,1),:,Where2Put) = mean(Intermediate,3);
  

 end
end
end

ListCheck = rem(ListofCoordinates,10);

AverageMatrix(AverageMatrix == 0) = NaN;

% Cell = 5;
% figure
% for k=1:120
%     
%     subplot(8,15,k)
%     plot(AverageMatrix(:,Cell,k))
% 
% end

BaselineMat = AverageMatrix(1:size(Baseline,1),:,:);
BaselineMat = permute(BaselineMat,[1 3 2]);
BaselineMat = reshape(BaselineMat,[],size(BaselineMat,3));


AverageMatrix = bsxfun(@minus,AverageMatrix,(mean(BaselineMat,1,'omitnan'))); %bsxfun(@minus,X,mean(Baseline,1));
AverageMatrix = bsxfun(@rdivide,AverageMatrix,(std(BaselineMat,0,1,'omitnan')));


for i =1:size(AverageMatrix,3)
if (handles.radiobutton2.Value == 1)
EvokedResponse(i,:) = median(AverageMatrix(size(Baseline,1):end,:,i),1,'omitnan');% - mean (AverageMatrix(1:size(Baseline,1),:,i),1,'omitnan');

elseif (handles.radiobutton1.Value == 1)
EvokedResponse(i,:) = mean(AverageMatrix(size(Baseline,1):end,:,i),1,'omitnan');%

elseif (handles.radiobutton3.Value == 1)
EvokedResponse(i,:) = max(AverageMatrix(size(Baseline,1):end,:,i),[],1,'omitnan');
end
end


%AverageMatrix(AverageMatrix<1) = NaN;

% % % % %figure
% % % % for j=1:size(AverageMatrix,2)
% % % % for k=1:120
% % % %     
% % % %     subplot(8,15,k)
% % % %     plot(AverageMatrix(:,j,k))
% % % % axis([-inf,inf,-1,10])
% % % % end
% % % % j
% % % % pause(0.1)
% % % % 
% % % % end


% This was a stupid way to do it.
%AverageMatrix = bsxfun(@rdivide,AverageMatrix,(max(max(AverageMatrix,[],1),[],3)));

% % %%%%CODE TO SEE THE TRACES
% % 
% % figure
% % 
% % for i=1:size (AverageMatrix,3)
% %     plot(AverageMatrix(:,:,i) )
% %     hold on
% %     plot(mean(AverageMatrix(:,:,i),2),'-k', 'LineWidth' , 2)
% %     axis([ -inf inf -1 1]);
% %     pause(0.5)
% %     hold off
% %     
% % end






% figure
% image(EvokedResponse,'CDataMapping','scaled')

%EvokedResponse(end+1:end+2,:) = NaN;
%[C,RelativePosition] = max (EvokedResponse,[],1);

% figure
% for i =1:size(EvokedResponse,2);
% ReceptiveField = reshape(EvokedResponse(:,i),16,10);
% ReceptiveField = imresize(ReceptiveField,10);
% ReceptiveField = imgaussfilt(ReceptiveField, 2);
% image(ReceptiveField,'CDataMapping','scaled');
% pause(0.5)


%end


% % % % CrossMatrix = NaN(numel(handles.dataMask.vert),numel(handles.dataMask.vert));
% % % % 
% % % % for i=1: numel(handles.dataMask.vert)
% % % %     for j = 1:  numel(handles.dataMask.vert)
% % % % 
% % % % cr = xcorr(handles.Signals.sig(:,i),handles.Signals.sig(:,j),0, 'coeff' );
% % % % 
% % % % CrossMatrix(i,j) = cr;
% % % %     end
% % % % end
% % % % 
% % % % 
% % % % %CrossMatrix = (CrossMatrix - min(min(CrossMatrix)))/max(max(CrossMatrix));
% % % % figure
% % % % image(CrossMatrix,'CDataMapping','scaled')
% % % % 
% % % % CenterofCell = NaN(numel(handles.dataMask.vert),2);
% % % % 
% % % % for i=1: numel(handles.dataMask.vert)
% % % %     
% % % %  r_i = handles.dataMask.vert{i,1};
% % % %  n = size(handles.dataMask.vert{i,1},1);
% % % % CenterofCell(i,:) = sum(r_i) / n;
% % % % 
% % % % 
% % % % 
% % % % end
% % % % 
% % % % 
% % % % CellDistance = pdist(CenterofCell,'euclidean');
% % % % CellDistance = squareform(CellDistance);
% % % % figure
% % % % image(CellDistance,'CDataMapping','scaled')