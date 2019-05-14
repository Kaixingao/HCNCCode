function testMultiIntevals_CHN
clc;

%%% dataset path
sImage	='D:\ShapeDatasets\MCD\';

f_structure = dir(sImage);
m = length(f_structure);
ifname = cell(1, m-2);
for i = 3 : m  % batch process
      ifname{i-2} = strcat(sImage, f_structure(i).name);
end
%%% sample points
n_contour  = 100;
%%% interval L=25 in our paper
times = 25;
resultdata = cell(1,m-2);

for num = 1:m-2
        im =  double(imread(ifname{num}));
        im = im(:,:,1); 
        %%% if backgroud is white !
        im = 255 - im;            
        im(im < 200) = 0;           
        im(im > 0) = 255;
        %%% end
        [len, wid] = size(im);
        im2 = zeros(len+2, wid+2);
        im2(2:len+1,2:wid+1) = im;  
%         im2 = im2'; % mirror image
        %%% extract edge
        edgedata = extract_longest_cont(im2, n_contour);
        edgedata = edgedata';
%         plot(edgedata(1,:),edgedata(2,:),'.');
        edgedata = repmat(edgedata,1,4);
        featureVec = zeros(times,n_contour);
        %%% compute each point
        for k = (n_contour+1) : 2*n_contour
            %%% ��ǰ����Ϊ p3
            p3 = edgedata(:,k);
            for  intervals=1:times    
                for round =1:2
                    if round==1
                        %%% p1,p2 on the left
                        p1 = edgedata(:,k-2*intervals);
                        p2 = edgedata(:,k-intervals);
                        %%% p4,p5 on the right
                        p4= edgedata(:,k+intervals);
                        p5 = edgedata(:,k+2*intervals);
                    else
                         %%% exchange p1 and p5
                        p5 = edgedata(:,k-2*intervals);
                        p2 = edgedata(:,k-intervals);
                        p4= edgedata(:,k+intervals);
                        p1 = edgedata(:,k+2*intervals);                   
                    end
                    %%% reference point Inner 
                    [A(1,:), A(2,:)] = linecrosspoint(p1,p4,p2,p5);
                    if isnan(A(1,1))
                           featureVec(times+1-intervals,k-n_contour) = 0;
                           continue;
                    end     
                    [Inner(1,:), Inner(2,:)] = linecrosspoint(p3,A,p1,p5);
                    if isnan(Inner(1,1))
                           featureVec(times+1-intervals,k-n_contour) = 0;
                           continue;
                    end     
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%              
                    crosspoints = [Inner,p2,p3,p4,p5];
                    p1 = Inner;
                    r=threePointsColinear(crosspoints(1,:),crosspoints(2,:));    
                    %%% if three point are collinear 
                    if r==1
                        featureVec(times+1-intervals,k-n_contour) = 0; 
                    else 
                        [P(1,:), P(2,:)] = linecrosspoint(p1,p2,p4,p5);
                        if isnan(P(1,1))
                           featureVec(times+1-intervals,k-n_contour) = 0;
                           continue;
                        end
                        [Q(1,:), Q(2,:)] = linecrosspoint(p1,p2,p3,p4);
                        if isnan(Q(1,1))
                           featureVec(times+1-intervals,k-n_contour) = 0;
                           continue;
                        end                    
                        [R(1,:), R(2,:)] = linecrosspoint(p2,p3,p4,p5);
                        if isnan(R(1,1))
                           featureVec(times+1-intervals,k-n_contour) = 0;
                           continue;
                        end                    
                        [K(1,:), K(2,:)] = linecrosspoint(p1,R,p5,Q);
                        if isnan(K(1,1))
                           featureVec(times+1-intervals,k-n_contour) = 0;
                           continue;
                        end                    
                        [M(1,:), M(2,:)] = linecrosspoint(P,K,p1,p5);
                         if isnan(M(1,1))
                           featureVec(times+1-intervals,k-n_contour) = 0;
                           continue;
                        end                   
                        [N(1,:), N(2,:)] = linecrosspoint(P,p3,p1,p5);
                        if isnan(N(1,1))
                           featureVec(times+1-intervals,k-n_contour) = 0;
                           continue;
                        end                    
                        charatio(round) = 1;
                        chra1 = characterRatio(P,p1,p2,Q);
                        chra2 = characterRatio(p1,p5,M,N);
                        chra3 = characterRatio(p5,P,p4,R);
                        charatio(round) = chra1 * chra2 * chra3;
                    end        
                end
                %%% the ratio process
                featureVec(times+1-intervals,k-n_contour) = charatio(1)/charatio(2);  
                if isinf(abs(featureVec(times+1-intervals,k-n_contour))) || isnan(abs(featureVec(times+1-intervals,k-n_contour))) 
                    featureVec(times+1-intervals,k-n_contour)=0;   
                    continue;
                elseif  abs(featureVec(times+1-intervals,k-n_contour))>1
                    featureVec(times+1-intervals,k-n_contour) = sign(featureVec(times+1-intervals,k-n_contour))*1;   
                end 
                end
        end
        resultdata{1,num} = featureVec;
        
     fprintf('%d\n',num);
end  
    
%%% save file
save('./HCNC for MCD.mat','resultdata');

end

function r=threePointsColinear(x,y)
ii=nchoosek(1:length(x),3);
xx=x(ii);
yy=y(ii);
cc=((yy(:,2)-yy(:,1)).*(xx(:,3)-xx(:,1))-(xx(:,2)-xx(:,1)).*(yy(:,3)-yy(:,1)));
r=any(cc==0);
end

%%% compute the intersection of line X1Y1 and line X2Y2
function [X Y]= linecrosspoint(X1,Y1,X2,Y2)
    if X1(1)==Y1(1)
        X=X1(1);
        k2=(Y2(2)-X2(2))/(Y2(1)-X2(1));
        b2=X2(2)-k2*X2(1); 
        Y=k2*X+b2;
    end
    if X2(1)==Y2(1)
        X=X2(1);
        k1=(Y1(2)-X1(2))/(Y1(1)-X1(1));
        b1=X1(2)-k1*X1(1);
        Y=k1*X+b1;
    end
    if X1(1)~=Y1(1) && X2(1)~=Y2(1)
        k1=(Y1(2)-X1(2))/(Y1(1)-X1(1));
        k2=(Y2(2)-X2(2))/(Y2(1)-X2(1));
        b1=X1(2)-k1*X1(1);
        b2=X2(2)-k2*X2(1);
        if k1==k2
           X=NaN;
           Y=NaN;
        else
        X=(b2-b1)/(k1-k2);
        Y=k1*X+b1;
        end
    end
end