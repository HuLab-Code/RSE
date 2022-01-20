clear all;
close all;

F = 'E:\Liang Li Ca Data\1st jG7s Ca of RGC and analysis\!!! Figures for paper\Figure1 Method\!!!jG7s without UV\!!!Summary jG7s without UV';
Folder = dir(F);

minR = 5; %5
maxR = 25; %20 for GCamp,  16 for GFP

% the distance threshold to merge circles(cell size)
DistanceThresh1 = 12; % 12 for GCamp
DistanceThresh2 = 10; % 10 for GCamp

% sensitivity of the circle detection
% Sense = 0.87;
Sense = 0.85;

% sigma for the gaussian filter blur to extract background intensity
sigma= 20; % 20 for GCamp

% Threshold for subtracting intensity to generate BW images
Thresh =1.15; % 1.45 for GCamp, 1.35 for low fluorescent intensity image; 1.25 for the high fluorescent image 

FFC=[];
FFR=[];
FFMI=[];

for k = 3:size(Folder)
    k
    Filenames = Folder(k).name;
    Filenames= fullfile(F,Filenames);
    v = VideoReader(Filenames);
    frames = read(v,[1 Inf]);
    Img =squeeze(frames);
    Planes = size(Img,3);
    clear frames;
    clear v;
    
    %% Detect Neurons and Intensity measurement
    
    Correction = 1; % need intensity correction with blood vessel intensity changes
    
    [FinalC,FinalR,MIntens,MBInten] = DetectRGC(Img,Thresh,sigma,minR,maxR,Sense,DistanceThresh1,DistanceThresh2,Correction); % last parameter represents whether needs correction
    
    %MIntens: Mean Intensity of individual RGCs
    %MBIten: Mean Blood vessel Intensity;
    
    if isempty(MIntens)
        NMIntens = [];
    else
        NMIntens = MIntens./mean(MIntens(:,1:45),2);
        
        if Correction == 1 & isempty(MBInten) == 0
            NMBInten = MBInten./mean(MBInten(:,1:45),2);
            NMIntens = NMIntens./NMBInten;
        end
    end
    
    KeepFlag = input('Do you want to keep the data from this movie?(yes) or (no):  ','s');
    
    if KeepFlag(1) == 'y'
        FFC=[FFC;FinalC];
        FFR=[FFR;FinalR];
        FFMI=[FFMI;NMIntens];
    end
    
end


FNMIntens = FFMI;
figure, plot(FNMIntens');
title('Plot of subtracted Calcium waves');


% lowpass filtering
FilterFlag=input('Do you want to use lowpass filter to smooth the data?(yes) or (no) ','s');

if any(FilterFlag ==  'y')
    disp('Now processding the trace with Lowpass to remove noises... (May take some time ...)')
    for i=1:size(FNMIntens,1)
        FS=lowpass(FNMIntens(i,:),0.3);
        FS(1:3)=[];
        FS(end-3:end)=[];
        FilteredFNMItens(i,:) = FS;
    end
    
    FNMIntens=FilteredFNMItens;
end

%% Remove cells with variation less than 0.10
% cutoffs = input('Do you want to filter out the traces with less than 0.15 variation?  (yes) or (no):  ','s');
%
% if cutoffs(1) == 'y'
%     disp('Removing the cells with less than 10% variation')
%     varia=[abs(1-min(FNMIntens,[],2)),abs(1-max(FNMIntens,[],2))];
%     varia = max(varia,[],2);
%     FNMIntens(find(varia<0.10),:)=[];
% end


savedata = input('Save the data as excel file? input (yes) or (no) ','s');

if savedata(1) == 'y'
    filename = input('what would be the file name?:    ','s');
    %filename = append(filename,".csv");
    csvwrite(filename,FNMIntens);
    disp('Job done! Saved');
end

%% Code for clustering
%%% Hierachy Tree Plot
