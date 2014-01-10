//
//  Utility.m
//  JCOpenCVCameraImgMatchDemo
//
//  Created by jimple on 14-1-10.
//  Copyright (c) 2014年 Jimple Chen. All rights reserved.
//

#import "Utility.h"

#include "opencv2/legacy/compat.hpp"


@implementation Utility

void GenerateGaussModel(double model[]);

//将图像与特定函数分布histv[]匹配
void myHistMatch(IplImage *img,double histv[]);


// NOTE you SHOULD cvReleaseImage() for the return value when end of the code.
+ (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
	CGImageRef imageRef = image.CGImage;
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	IplImage *iplimage = cvCreateImage(cvSize(image.size.width, image.size.height), IPL_DEPTH_8U, 4);
	CGContextRef contextRef = CGBitmapContextCreate(iplimage->imageData, iplimage->width, iplimage->height,
													iplimage->depth, iplimage->widthStep,
													colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
	CGContextDrawImage(contextRef, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);
	CGContextRelease(contextRef);
	CGColorSpaceRelease(colorSpace);
    
	IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
	cvCvtColor(iplimage, ret, CV_RGBA2BGR);
	cvReleaseImage(&iplimage);
    //CGImageRelease(imageRef);
    
	return ret;
}

// NOTE You should convert color mode as RGB before passing to this function
+ (UIImage *)UIImageFromIplImage:(IplImage *)image grayImg:(BOOL)bIsGrayImg
{
	CGColorSpaceRef colorSpace = bIsGrayImg ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB();
	NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)CFBridgingRetain(data));
	CGImageRef imageRef = CGImageCreate(image->width, image->height,
										image->depth, image->depth * image->nChannels, image->widthStep,
										colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
										provider, NULL, false, kCGRenderingIntentDefault);
	UIImage *ret = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
    
	return ret;
}

+ (CvHistogram *)get4ChannelHist:(IplImage *)image
{
    
    IplImage* r_plane  = cvCreateImage( cvGetSize(image), 8, 1 );
    IplImage* g_plane  = cvCreateImage( cvGetSize(image), 8, 1 );
    IplImage* b_plane  = cvCreateImage( cvGetSize(image), 8, 1 );
    IplImage* planes[] = { r_plane, b_plane };
    
    //将HSV图像分离到不同的通道中
    cvCvtPixToPlane( image, b_plane, g_plane, r_plane, 0 );

    // 生成二维直方图数据结构
    int r_bins =256, b_bins = 256;//, g_bins = 256;
    CvHistogram* hist = NULL;
    {
        int    hist_size[] = { r_bins, b_bins };
        float  r_ranges[]  = { 0, 255 };          // hue is [0,180]
        float  b_ranges[]  = { 0, 255 };
        //float  g_ranges[]  = { 0, 255 };
        float* ranges[]    = { r_ranges,b_ranges };
        hist = cvCreateHist( 2, hist_size, CV_HIST_ARRAY, ranges, 1);
    }
    
    //计算一张或多张单通道图像image(s) 的直方图
    cvCalcHist( planes, hist, 0, 0 );
    
    return hist;
}

+ (CvHistogram *)getHSVHist:(IplImage *)image
{
    //    static double shistv[256] = {0};
    //    static BOOL sbIsGetHistvModel = NO;
    //    if (!sbIsGetHistvModel)
    //    {
    //        GenerateGaussModel(shistv);
    //        sbIsGetHistvModel = YES;
    //    }else{}
    //
    
    // 图像均衡化
    IplImage* eqlimage=cvCreateImage(cvGetSize(image),image->depth,3);
    //分别均衡化每个信道
    IplImage* redImage=cvCreateImage(cvGetSize(image),image->depth,1);
    IplImage* greenImage=cvCreateImage(cvGetSize(image),image->depth,1);
    IplImage* blueImage=cvCreateImage(cvGetSize(image),image->depth,1);
    cvSplit(image,blueImage,greenImage,redImage,NULL);
    
    cvEqualizeHist(redImage,redImage);
    cvEqualizeHist(greenImage,greenImage);
    cvEqualizeHist(blueImage,blueImage);
    
    //    myHistMatch(redImage, shistv);
    //    myHistMatch(greenImage, shistv);
    //    myHistMatch(blueImage, shistv);
    
    //均衡化后的图像
    cvMerge(blueImage,greenImage,redImage,NULL,eqlimage);
    
    
    IplImage* hsv = cvCreateImage( cvGetSize( eqlimage ), 8, 3 );
    cvCvtColor( eqlimage, hsv, CV_BGR2HSV );  //色彩空间的转换
    
    //计算直方图，并将其分解为单通道
    IplImage* h_plane = cvCreateImage( cvGetSize( eqlimage ), 8, 1 );
    IplImage* s_plane = cvCreateImage( cvGetSize( eqlimage ), 8, 1 );
    IplImage* v_plane = cvCreateImage( cvGetSize( eqlimage ), 8, 1 );
    IplImage* planes[] = { h_plane, s_plane };
    cvCvtPixToPlane( hsv, h_plane, s_plane, v_plane, 0 );  //分割多通道数组成几个单通道数组或者从数组中提取一个通道,可以看作cvSplit是他的宏
    
    //构建直方图，并计算直方图
    int h_bins = 30, s_bins = 20;
    CvHistogram* hist;
    {
        //单独的模块
        int hist_size[] = { h_bins, s_bins }; //直方图矩阵大小
        float h_ranges[] = { 0, 180 };
        float s_ranges[] = { 0, 255 };
        float* ranges[] = { h_ranges, s_ranges };//二维数组
        hist = cvCreateHist( 2, hist_size, CV_HIST_ARRAY, ranges, 1 ); //创建直方图，参数是维度，矩阵大小，直方图的表示格式（CV_HIST_ARRAY 意味着直方图数据表示为多维密集数组 ），图中方块范围的数组
    };
    cvCalcHist( planes, hist, 0, 0 );  //计算图像image(s) 的直方图，planes是IplImage**类型
    
    cvReleaseImage(&hsv);
    cvReleaseImage(&h_plane);
    cvReleaseImage(&s_plane);
    cvReleaseImage(&v_plane);
    
    cvReleaseImage(&eqlimage);
    cvReleaseImage(&redImage);
    cvReleaseImage(&greenImage);
    cvReleaseImage(&blueImage);
    
    return hist;
}

// 生成高斯分布
void GenerateGaussModel(double model[])
{
    double m1,m2,sigma1,sigma2,A1,A2,K;
    m1 = 0.15;
    m2 = 0.75;
    sigma1 = 0.05;
    sigma2 = 0.05;
    A1 = 1;
    A2 = 0.07;
    K = 0.002;
    
    double c1 = A1*(1.0/(sqrt(2*CV_PI))*sigma1);
    double k1 = 2*sigma1*sigma1;
    double c2 = A2*(1.0/(sqrt(2*CV_PI))*sigma2);
    double k2 = 2*sigma2*sigma2;
    double p = 0.0,val= 0.0,z = 0.0;
    for (int zt = 0;zt < 256;++zt)
    {
        val = K + c1*exp(-(z-m1)*(z-m1)/k1) + c2*exp(-(z-m2)*(z-m2)/k2);
        model[zt] = val;
        p = p +val;
        z = z + 1.0/256;
    }
    for (int i = 0;i<256; ++i)
    {
        model[i] = model[i]/p;
    }
}

//将图像与特定函数分布histv[]匹配
void myHistMatch(IplImage *img,double histv[])
{
    int bins = 256;
    int sizes[] = {bins};
    CvHistogram *hist = cvCreateHist(1,sizes,CV_HIST_ARRAY,NULL, 1);
    cvCalcHist(&img,hist,0,NULL);
    cvNormalizeHist(hist,1);
    double val_1 = 0.0;
    double val_2 = 0.0;
    uchar T[256] = {0};
    double S[256] = {0};
    double G[256] = {0};
    for (int index = 0; index<256; ++index)
    {
        val_1 += cvQueryHistValue_1D(hist,index);
        val_2 += histv[index];
        G[index] = val_2;
        S[index] = val_1;
    }
    
    double min_val = 0.0;
    int PG = 0;
    for ( int i = 0; i<256; ++i)
    {
        min_val = 1.0;
        for(int j = 0;j<256; ++j)
        {
            if( (G[j] - S[i]) < min_val && (G[j] - S[i]) >= 0)
            {
                min_val = (G[j] - S[i]);
                PG = j;
            }
            
        }
        T[i] = (uchar)PG;
    }
    
    uchar *p = NULL;
    for (int x = 0; x<img->height;++x)
    {
        p = (uchar*)(img->imageData + img->widthStep*x);
        for (int y = 0; y<img->width;++y)
        {
            p[y] = T[p[y]];
        }
    }  
}














@end
