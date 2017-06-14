function [time, DiodeExp, StimMatrix, Signals, VistimExp, WhereImgIs, TimeStamp, VistimWave ] = UpLoadforEE (fileName,PathName,SN)

OldFile = 1;

% in case of trouble shooting
%[fileName,PathName,FilterIndex] = uigetfile('*_signals.mat','Choose experiment');
%SN = 1;

%

fileName = strrep(fileName, '_signals.mat', '[photodiode].ibw');

Diode = IBWread([PathName fileName]);

time=(0:Diode.Nsam - 2)' * Diode.dx + Diode.x0;
% DiodeTs = timeseries(Diode.y,time);
Threshold = 0.2;
EventCount = 1;
TimeStamp = zeros (10000,4);

if (OldFile == 1)

    TempFilter = 2.7;
else 
    
    TempFilter = 1.2;
end

for  i= 1:(Diode.Nsam -2)
    
    if ( ( Diode.y(i) >= Threshold ) && (Diode.y(i+ 1)  < Threshold ) )
                TimeStamp (EventCount,1)  = time(i);
        
    elseif  ( ( Diode.y(i)  < Threshold ) && (Diode.y(i+ 1)  >= Threshold ) )
        
        TimeStamp (EventCount,2)  = time(i);
        
        if ( (TimeStamp (EventCount,2) -  TimeStamp (EventCount,1) > TempFilter) && ((TimeStamp (EventCount,2) -  TimeStamp (EventCount,1) > 0.2) )) % remove weird changes of diode signal unrelated to stimuli
        
          TimeStamp (EventCount,3) = TimeStamp (EventCount,2) -  TimeStamp (EventCount,1);
            
        EventCount = EventCount +1;
        
        end
    end
end

TimeStamp(EventCount :end,:) = []; 



% To be removed in a next version when John change the Diode code so it
% match between behavior and Vistim

if (OldFile == 1)
EventCount = 1;
TimeStampOT = zeros (10000,4);
TempFilter = 3.1;
for  i= 1:(Diode.Nsam -2)
    
    if ( ( Diode.y(i)  < Threshold ) && (Diode.y(i+ 1)  >= Threshold ) )
        
                TimeStampOT (EventCount,1)  = time(i);
        
    elseif   ( ( Diode.y(i) >= Threshold ) && (Diode.y(i+ 1)  < Threshold ) )
        
        TimeStampOT (EventCount,2)  = time(i);
        
        if ( (TimeStampOT (EventCount,2) -  TimeStampOT (EventCount,1) < TempFilter)) && ((TimeStampOT (EventCount,2) -  TimeStampOT (EventCount,1) > 0.2)) % remove weird changes of diode signal unrelated to stimuli
        
          TimeStampOT (EventCount,3) = TimeStampOT (EventCount,2) -  TimeStampOT (EventCount,1);
            
        EventCount = EventCount +1;
        
        end
    end
end

 TimeStampOT(EventCount :end,:) = []; 
 StimMatrix = [TimeStamp; TimeStampOT];
 
end

clear TimeStampOT TimeStamp EventCount TempFilter Threshold DiodeTs

fileName = strrep(fileName, 'photodiode', 'movie Sine');
Vistim = IBWread([PathName fileName]);

if (SN == 1)
    
for  i= 1:length (StimMatrix (:,1)) 
if StimMatrix (i,3)<0.5
ts1 = Vistim.y(round( (StimMatrix(i,1) -0.2 - Vistim.x0)/Vistim.dx) : round( (StimMatrix(i,2)+.2 - Vistim.x0)/Vistim.dx));
Y = fft(ts1);
L = length (ts1);
P2 = abs(Y/L);
P1 = P2(1:floor(L/2+1));
f = Vistim.dx^-1*(0:(L/2))/L;
[C, I] = max (P1);
StimMatrix(i,4) = round(f(I)/2) ;

end

end


else
    
for  i= 1:length (StimMatrix (:,1)) -1

ts1 = Vistim.y(round( (StimMatrix(i,1)  - Vistim.x0)/Vistim.dx) : round( (StimMatrix(i,2)   - Vistim.x0)/Vistim.dx));
Y = fft(ts1);
L = length (ts1);
P2 = abs(Y/L);
P1 = P2(1:floor(L/2+1));
f = Vistim.dx^-1*(0:(L/2))/L;
[C, I] = max (P1);
StimMatrix(i,4) = round (f(I)-1) ;

end

end


clear Y L P2 P1 f C I

fileName = strrep(fileName, 'movie Sine', 'eyetracker');
EyeTracker = IBWread([PathName fileName]);

% Find the timeStamps of the calcium imaging

Threshold = 0.02;
TimeStamp = zeros (10000,4);
EventCount = 1;
WhereImgIs = zeros (10,3);
WhereImgIsIndex = 1;

ShiftET = mean(EyeTracker.y(1:100));

if (ShiftET > Threshold)
    

    EyeTracker.y = (EyeTracker.y - ShiftET) * -1;
 
end


for  i= 1:(EyeTracker.Nsam -2)
    
    if ( ( EyeTracker.y(i) <= Threshold ) && (EyeTracker.y(i+ 1)  > Threshold ) )
                TimeStamp (EventCount,1)  = time(i);
    if (EventCount == 1 )
        
      WhereImgIs (1,1)  =   time(i); WhereImgIs (WhereImgIsIndex,3) = EventCount;
        
    end
                
    if ((EventCount>=2) ) %&& ( TimeStamp (EventCount,1) -  TimeStamp (EventCount -1 ,2) > 0.5));
        
        
        TimeStamp (EventCount,4) = TimeStamp (EventCount,1) -  TimeStamp (EventCount -1 ,2);
        
        if  (TimeStamp (EventCount,4)> 0.5)
           WhereImgIs (WhereImgIsIndex+1,1) = time(i);  WhereImgIs (WhereImgIsIndex+1,3) = EventCount;
           WhereImgIs (WhereImgIsIndex,2) = TimeStamp (EventCount -1 ,2);
           WhereImgIsIndex = WhereImgIsIndex +1;
        end
        
    end
        
    elseif  ( ( EyeTracker.y(i)  > Threshold ) && (EyeTracker.y(i+ 1)  <= Threshold ) )
        
        TimeStamp (EventCount,2)  = time(i);
        
          
        TimeStamp (EventCount,3) = TimeStamp (EventCount,2) -  TimeStamp (EventCount,1);
            
        EventCount = EventCount +1;
        
       
        
    end
     
    
end

TimeStamp(EventCount :end,:) = [];
WhereImgIs (WhereImgIsIndex,2) = TimeStamp(end,2);

WhereImgIs(WhereImgIsIndex + 1 : end, :) = []; 


fileName = strrep(fileName, '[eyetracker].ibw' , '_signals.mat');

Signals = load([PathName fileName]);

DiodeExp = Diode.y;
VistimExp = Vistim.y;

VistimWave = zeros(size(Diode.y,1),1);
VistimWave = VistimWave -1;



for i = 1: size (StimMatrix,1)
    
    
    VistimWave (StimMatrix(i,1)/Diode.dx:StimMatrix(i,2)/Diode.dx) = StimMatrix(i,4)/30;
 
    
end

if (SN == 1)
fileName = strrep(fileName, '_signals.mat', '[Vm1].ibw');
WhiteSquare = IBWread([PathName fileName]);

for i=1: size (StimMatrix,1)
    
    ts = mean (WhiteSquare.y(round( (StimMatrix(i,1) - Vistim.x0)/Vistim.dx) :...
        round( (StimMatrix(i,2) - Vistim.x0)/Vistim.dx)));
    
    if ts <0.02
     StimMatrix(i,5) = 0;
     
    else
     StimMatrix(i,5) = 1;
    end
end
else
    
    
end