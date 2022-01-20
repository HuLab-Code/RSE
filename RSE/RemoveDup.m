function [FinalC,FinalR] = RemoveDup(C,R, DistanceThresh,Round)
% merge duplicated circles that are close

CCopy=C;
RCopy=R;

FinalC=[];
FinalR=[];
if nargin<3
    DistanceThresh = 16;
end


while length(RCopy)>0
    i=1;
    Dist=sqrt((CCopy(:,1)-CCopy(1,1)).^2+(CCopy(1,2)-CCopy(:,2)).^2);
    
    List=find(Dist<DistanceThresh);
    ListR=find(Dist>=DistanceThresh);
    if Round == 1
        if length(List) > 1
            
            %         [MaxM,I] = max(MCopy(List));
            %         FinalC =[FinalC;CCopy(List(I),:)];
            %         FinalR =[FinalR;RCopy(List(I))];
            
            Center = mean(CCopy(List,:),1);
            Radius = mean(RCopy(List));
            FinalC =[FinalC;Center];
            FinalR =[FinalR;Radius];
        end
    else
        Center = mean(CCopy(List,:),1);
        Radius = mean(RCopy(List));
        FinalC =[FinalC;Center];
        FinalR =[FinalR;Radius];
    end
    CCopy= CCopy(ListR,:);
    RCopy= RCopy(ListR);
    %MCopy= MCopy(ListR);
end
