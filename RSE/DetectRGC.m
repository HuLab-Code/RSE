function [FinalC,FinalR,MIntens,MBInten] = DetectRGC(Img,Thresh,sigma,minR,maxR,Sense,DistanceThresh1,DistanceThresh2,NeedCorrect)
%% function for RGC Calcium imaging detection

C=[];
R=[];
MM=[];
FinalC=[];
FinalR=[];
MItens=[];
MIntens=[];
MBInten = [];

BloodThresh = 0.80; % original 0.7,   0.85 for low fluorescent video
M=squeeze(mean(mean(Img))); % mean intensity of each frame
ImgMax = max(Img, [], 3);
%ImIF = I- IF;
warning('off');
%% caculate the background intensity change (use blood vessel as reference)
if NeedCorrect == 1
    kernel = ones(100,100)/10000;
    IM = imfilter(ImgMax,kernel);
    BWBlood=ImgMax<mean(ImgMax(:)')*(BloodThresh+0.1) & ImgMax<IM*BloodThresh;
    
    BWBlood(find(ImgMax<10))=0;
    %imshow(BWBlood)
    BWB2 = imfill(BWBlood,'holes');
    BWB2 = bwareaopen(BWB2,100);
    AContinue = 'yes';
    %figure,imshow(BW2)MBInten
    % CC = bwconncomp(BW2);
    % L = labelmatrix(CC);
    %S = regionprops(BW2, 'Area');
    % CCBW2 = ismember(L, find([S.Area] < 2000));
    if size(find(BWB2==1))>0
        for j=1:size(Img,3)
            I=Img(:,:,j);
            MBInten(j)=mean(I(find(BWB2==1)));
        end
    else
        disp('Have not found the blood vessel, no normalization will be done');
    end
    %plot(MBInten)
    figure,imshow(BWB2);
    AContinue = input('Continue with the analysis?(yes or no)   ','s');
end

%% Detect Neurons


if any(AContinue == 'y')
    kernel = ones(30,30)/900;
    for i=[1:10:40,41:3:200 201:10:size(Img,3)]
        I= Img(:,:,i);
        %I(find(I==0)) = median(I(find(I>0)));
        I= imgaussfilt(I,1);
        IF = imgaussfilt(I,sigma);
        %
        %ImIF = I- IF;
        IM = imfilter(I,kernel);
        %BW = I>80;
        %BW = I>IF*Thresh & I>mean(I,'all')*1;
        
        BW = I>IF*Thresh & I>IM*1.1 & I>M(i)*1.35;  %  1.35 is times of M???mean intensity of each pixel, original is 1.1
        BW(1:10,:)=0;
        BW(:,1:10)=0;
        BW(end-10:end,:)=0;
        BW(:,end-10:end)=0;
        BW2 = bwareaopen(BW,40);
        %imshow(BW2);
        [centers, radii, metric] = imfindcircles(BW2,[minR maxR],'Sensitivity',Sense);
        
        BWH = I>IF*1.5 & I>M(i)*1.35;
        BWH2 = bwareaopen(BWH,30);
        [centers2, radii2, metric2] = imfindcircles(BWH2,[minR maxR],'Sensitivity',Sense);
        
        centers = [centers;centers2];
        radii = [radii; radii2];
        metric = [metric; metric2];
        
        X = metric > 0.1;
        C = [C;centers(X,:)];
        R = [R;radii(X)];
        MM = [MM;metric(X)];
    end
    
    
    %viscircles(C, R,'EdgeColor','b');
    
    % % first round of removing duplicated circles
    [FinalC1, FinalR1] = RemoveDup(C, R, DistanceThresh1,1);
    
    % % second round of removing duplicated circles
    [FinalC, FinalR] = RemoveDup(FinalC1, FinalR1, DistanceThresh2,2); % 10 for GCamp
    disp('Combination Done!')
    
    figure,imshow(ImgMax,[]);
    viscircles(FinalC, FinalR,'EdgeColor','g');
    
    
    %% measure intensity
    
    h = size(Img, 1);
    w = size(Img, 2);
    
    MIntens = zeros(length(FinalR),size(Img,3));
    hold on;
    
    for i=1:length(FinalR)
        
        x = FinalC(i,1);
        y=  FinalC(i,2);
        r=  FinalR(i);
        
        text(x,y,num2str(i),'Color','red');
        
        mask = ((1-y:h-y).' .^2 + (1-x:w-x) .^2) <= r^2;
        for j=1:size(Img,3)
            I=Img(:,:,j);
            MIntens(i,j) = mean(I(mask)); % if wants to normalize/M(j) /MBInten(j)
        end
    end
        hold off
        title('Neuron Detection');
    
    %% Removing Points
    
    remove = input('Any points to remove? input (yes) or (no)   ','s');
    
    if any(remove == 'y')
        prompt = 'Which ones to remove? (in the format of like [150,223,42,...])   ';
        remove_list = input(prompt);
        
        FinalC(remove_list,:)=[];
        FinalR(remove_list,:)=[];
        MIntens(remove_list,:)=[];
        figure, imshow(ImgMax,[]);
        viscircles(FinalC, FinalR,'EdgeColor','g');
        hold on;
        for i=1:length(FinalR)
            x = FinalC(i,1);
            y=  FinalC(i,2);
            text(x,y,num2str(i),'Color','red');
        end
        hold off;
        title('Updated Neuron Detection');
    end
    
end
