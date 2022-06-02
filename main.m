%整体思路就是1.把原图转成Ycbcr格式，通过Y的值和平均的Y值判断是否处在阴影区，拿到阴影区mask；
%2.拿到mask后，算出亮区的RGB平均值和阴影区RGB平均值，算出他们之间的差和比值；
%3.把阴影区的RGB+差，或者*比值 去除阴影区

clc;
clear all;
PR=imread('2.jpg');
subplot(141),imshow(PR),title('原图');

I=PR;
R=I(:,:,1);G=I(:,:,2);B=I(:,:,3);%拿到原图的R,G,B矩阵

Rme=mean(R,'all');
Gme=mean(G,'all');
Bme=mean(B,'all');

YCBCR=rgb2ycbcr(I);%把图像转换为Ycbcr格式

Y=YCBCR(:,:,1);Cb=YCBCR(:,:,2);Cr=YCBCR(:,:,3);%拿到Y,Cb，Cr矩阵；Y的值是用来找阴影区的
Y1=YCBCR(:,:,1);
Y2=YCBCR(:,:,1);

Mid=median(Y,'all');%求Y矩阵元素的中位数
Midcr=median(Cr,'all');

Yme=mean(Y,'all');%求Y矩阵元素的平均数
Cbme=mean(Cb,'all');%求Cb矩阵元素的平均数
Crme=mean(Cr,'all');%求Cr矩阵元素的平均数

if (Yme-Mid>20) %判断图片是否整体偏亮或偏暗 
    Yme1=Mid+75;
    Crme=Crme+5;
else
    Yme1=Yme;
end


[width,height]=size(Y);
for i=1:width
    for j=1:height
        if(Cr(i,j)<Crme+1.04&&Y1(i,j)<Yme1*0.8)%判断是否处于阴影区域 这里主要靠Yme1的值来判断 为啥还要用Cr 因为不用Cr第一张图和第四张图的mask会出问题
         Y1(i,j)=1;
       
        else
         Y1(i,j)=0;
         
        end
    end
end

% Yme1=mean(Y1,'all');

subplot(142),imshow(255*Y1),title('rough-mask');
MaskY1 = uint8(bwareaopen(Y1,2500,8));%这个就是最后拿到的阴影区的mask。上面拿到的阴影区的mask会有很多小的碎片，这里把连通域小的都去除掉，就是认为只有大块的阴影才算阴影区
subplot(143),imshow(255*MaskY1),title('mask');
% Y3=MaskY1;

[width,height]=size(MaskY1);%这步是拿亮区的mask 相当于对阴影区mask取反
for i=1:width
    for j=1:height
        if (MaskY1(i,j)==1)
         Y2(i,j)=0;
        else
         Y2(i,j)=1;
        end
    end
end

MaskY2=Y2;%亮区mask

YCBCR1(:,:,1)=MaskY1;YCBCR1(:,:,2)=MaskY1;YCBCR1(:,:,3)=MaskY1;
YCBCR2(:,:,1)=MaskY2;YCBCR2(:,:,2)=MaskY2;YCBCR2(:,:,3)=MaskY2;

IY=PR.*(YCBCR1);%拿原图的阴影区
IX=PR.*(YCBCR2);%拿原图的亮区

IXR=IX(:,:,1);%分别拿亮区和阴影区的R，G，B的矩阵
IXG=IX(:,:,2);
IXB=IX(:,:,3);

IYR=IY(:,:,1);
IYG=IY(:,:,2);
IYB=IY(:,:,3);

%下面这些操作是用来计算亮区和阴影区的RGB的平均值
CXR=sum(sum(IXR~=0));%统计亮区R,G,B矩阵中非零元素个数
SXR=sum(IXR,'all');%分别求亮区R,G,B的元素值的和
CXG=sum(sum(IXG~=0));
SXG=sum(IXG,'all');
CXB=sum(sum(IXB~=0));
SXB=sum(IXB,'all');

CYR=sum(sum(IYR~=0));%统计阴影区R,G,B矩阵中非零元素个数
SYR=sum(IYR,'all');
CYG=sum(sum(IYG~=0));
SYG=sum(IYG,'all');
CYB=sum(sum(IYB~=0));
SYB=sum(IYB,'all');

MIXR=SXR/CXR;%亮区RGB平均值
MIXG=SXG/CXG;
MIXB=SXB/CXB;

MIYR=SYR/CYR;%阴影区平均值
MIYG=SYG/CYG;
MIYB=SYB/CYB;

DISR=MIXR-MIYR;%亮区和阴影区RGB值的差
DISG=MIXG-MIYG;
DISB=MIXB-MIYB;

BILIR=MIXR/MIYR;%亮区和阴影区RGB值的比值
BILIG=MIXG/MIYG;
BILIB=MIXB/MIYB;

YCBCR(:,:,1)=MaskY1*DISR;YCBCR(:,:,2)=MaskY1*DISG;YCBCR(:,:,3)=MaskY1*DISB;
IY(:,:,1)=IY(:,:,1)*BILIR;IY(:,:,2)=IY(:,:,2)*BILIG;IY(:,:,3)=IY(:,:,3)*BILIB;

if (98<DISR<120&DISG>99&98<DISB<130) %如果差在这些范围内，将阴影区的RGB值加上算出来的差
     IX1=YCBCR;
    if(DISB<40)
    I=I+IX1;
    else
        I=I+IX1*0.9;
    end    
subplot(144),imshow(I),title('removal-beta');


else  %不在上面的范围里 就阴影区RGB值乘上面算出来的比值 为啥用乘 因为效果好:D
 I2=IY+IX;
subplot(144),imshow(I2),title('removal-beta2');

end

%下面是一些其他尝试 但是效果都不是很好:D
% HSV=rgb2hsv(I);
% H=HSV(:,:,1);
% S=HSV(:,:,2);
% V=HSV(:,:,3);
% 
% 
% IP=rgb2ycbcr(I);
% Yp=IP(:,:,1);
% [width,height]=size(MaskY1);
% for i=1:width
%     for j=1:height
%         if (MaskY1(i,j)==1)
%          Yp(i,j)=Yp(i,j);
%         end
%     end
% end
% IP(:,:,1)=Yp;
% I=ycbcr2rgb(IP);


% subplot(163),imshow(I),title('removal-beta');
% subplot(164),imshow(I2),title('removal-beta2');

% % IX=HSV.*double(YCBCR2);
% % Y2=double(Y2);
% % IXR=IX(:,:,1);
% % IXG=IX(:,:,2);
% % IXB=IX(:,:,3);
% % [width,height]=size(IXR);
% % for i=1:width
% %     for j=1:height
% %         if (IX(i,j)~=0)
% %          Y2(i,j)=abs(IXR(i,j)-IXG(i,j))+abs(IXR(i,j)-IXB(i,j))+abs(IXB(i,j)-IXG(i,j));
% %          
% %         end
% %     end
% % end
% % 
% % IY=HSV.*double(YCBCR1);
% % IYR=IY(:,:,1);
% % IYG=IY(:,:,2);
% % IYB=IY(:,:,3);
% % Y3=double(Y3);
% % [width,height]=size(IYR);
% % for i=1:width
% %     for j=1:height
% %         if (IY(i,j)~=0)
% %          Y3(i,j)=abs(IYR(i,j)-IYG(i,j))+abs(IYR(i,j)-IYB(i,j))+abs(IYB(i,j)-IYG(i,j));
% %         end
% %     end
% % end
% 
% IX=PR.*(YCBCR2);
% 
% IXR=IX(:,:,1);
% IXG=IX(:,:,2);
% IXB=IX(:,:,3);
% % [width,height]=size(IXR);
% % for i=1:width
% %     for j=1:height
% %         if (IX(i,j)~=0)
% %          Y2(i,j)=abs(IXR(i,j)-IXG(i,j))+abs(IXR(i,j)-IXB(i,j))+abs(IXB(i,j)-IXG(i,j));
% %          
% %         end
% %     end
% % end
% % 
% IY=PR.*(YCBCR1);
% IYR=IY(:,:,1);
% IYG=IY(:,:,2);
% IYB=IY(:,:,3);
% % 
% % [width,height]=size(IYR);
% % for i=1:width
% %     for j=1:height
% %         if (IY(i,j)~=0)
% %          Y3(i,j)=abs(IYR(i,j)-IYG(i,j))+abs(IYR(i,j)-IYB(i,j))+abs(IYB(i,j)-IYG(i,j));
% %         end
% %     end
% % end
% 
% % IX=PR.*YCBCR2;
% % IX=rgb2gray(PR).*Y2;
% % HM2=H.*double(MaskY2);
% % SM2=S.*double(MaskY2);
% % VM2=V.*double(MaskY2);
% 
% 
% % [width,height]=size(IX);
% % for i=2:width-1
% %     for j=2:height-1
% %         if (IX(i,j)~=0)
% %          Y2(i,j)=abs(IX(i,j)-IX(i-1,j-1))+abs(IX(i,j)-IX(i-1,j))+abs(IX(i,j)-IX(i-1,j+1))...
% %                 +abs(IX(i,j)-IX(i,j-1))+abs(IX(i,j)-IX(i,j))+abs(IX(i,j)-IX(i,j+1))...
% %                 +abs(IX(i,j)-IX(i+1,j-1))+abs(IX(i,j)-IX(i+1,j))+abs(IX(i,j)-IX(i+1,j+1));
% %         
% %         end
% %     end
% % end
% 
% % IY=PR.*YCBCR1;
% % IY=rgb2gray(PR).*Y3;
% % HM1=H.*double(MaskY1);
% % SM1=S.*double(MaskY1);
% % VM1=V.*double(MaskY1);
% 
% % [width,height]=size(HM1);
% % for i=1:width
% %     for j=1:height
% %         if (YCBCR1(i,j)~=0)
% %          DISH=abs(HM2-HM1(i,j));
% %         [x,y]=find(DISH==min(min(DISH)),1,'first');
% %         H(i,j)=HM2(x,y);
% %          
% % %          R(i,j)=R(x,y);
% % %          G(i,j)=G(x,y);
% % %          B(i,j)=B(x,y);
% %         end
% %     end
% % end
% % 
% % [width,height]=size(SM1);
% % for i=1:width
% %     for j=1:height
% %         if (YCBCR1(i,j)~=0)
% %          DISS=abs(SM2-SM1(i,j));
% %         [x,y]=find(DISS==min(min(DISS)),1,'first');
% %         S(i,j)=SM2(x,y);
% %          
% % %          R(i,j)=R(x,y);
% % %          G(i,j)=G(x,y);
% % %          B(i,j)=B(x,y);
% %         end
% %     end
% % end
% % 
% % [width,height]=size(VM1);
% % for i=1:width
% %     for j=1:height
% %         if (YCBCR1(i,j)~=0)
% %          DISV=abs(VM2-VM1(i,j));
% %         [x,y]=find(DISV==min(min(DISV)),1,'first');
% %         V(i,j)=VM2(x,y);
% %          
% % %          R(i,j)=R(x,y);
% % %          G(i,j)=G(x,y);
% % %          B(i,j)=B(x,y);
% %         end
% %     end
% % end
% 
% [width,height]=size(MaskY1);
% for i=1:width
%     for j=1:height
%         if (MaskY1(i,j)~=0)
%          DISR=abs(int8(IXR)-int8(IYR(i,j)));
%         [x,y]=find(DISR>30,1,'first');
% %         H(i,j)=H(x,y);
% %          S(i,j)=S(x,y);
% %          V(i,j)=V(x,y);
%          R(i,j)=R(x,y);
%         
%         end
%     end
% end
% 
% [width,height]=size(MaskY1);
% for i=1:width
%     for j=1:height
%         if (MaskY1(i,j)~=0)
%          DISG=abs(int8(IXG)-int8(IYG(i,j)));
%         [x,y]=find(DISG>30,1,'first');
% %         H(i,j)=H(x,y);
% %          S(i,j)=S(x,y);
% %          V(i,j)=V(x,y);
%          G(i,j)=G(x,y);
%         
%         end
%     end
% end
% 
% [width,height]=size(MaskY1);
% for i=1:width
%     for j=1:height
%         if (MaskY1(i,j)~=0)
%          DISB=abs(int8(IXB)-int8(IYB(i,j)));
%         [x,y]=find(DISB>30,1,'first');
% %         H(i,j)=H(x,y);
% %          S(i,j)=S(x,y);
% %          V(i,j)=V(x,y);
%          B(i,j)=B(x,y);
%         
%         end
%     end
% end
% 
% PR(:,:,1)=R;PR(:,:,2)=G;PR(:,:,3)=B;
% 
% % HSV(:,:,1)=H;HSV(:,:,2)=S;HSV(:,:,3)=V;
% 
% % imwrite(IX+IY*1.96,'myGray.png')
% 
% % [width,height]=size(IY);
% % for i=1:width
% %     for j=1:height
% %         if (IY(i,j)~=0)
% %          Y3(i,j)=abs(IYR(i,j)-IYG(i,j))+abs(IYR(i,j)-IYB(i,j))+abs(IYB(i,j)-IYG(i,j));
% %         end
% %     end
% % end
% %   IZ=gray2rgb('myGray.png','4.jpg');
% 
% subplot(164),imshow(PR),title('Y2');
%  subplot(165),imshow(IX),title('Y3');
% subplot(166),imshow(IX+IY*1.96),title('Y4');


