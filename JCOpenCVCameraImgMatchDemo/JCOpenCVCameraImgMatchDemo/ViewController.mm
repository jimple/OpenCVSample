//
//  ViewController.m
//  JCOpenCVCameraImgMatchDemo
//
//  Created by jimple on 14-1-9.
//  Copyright (c) 2014年 Jimple Chen. All rights reserved.
//

#import "ViewController.h"
#import "CameraImageHelper.h"
#import "Utility.h"


// 自定义的颜色匹配的各种阀值设置
#define F_CORREL_THRESH_HARD                0.65f
#define F_CORREL_INTERSECT_HARD             0.55f
#define F_CORREL_CHISQR_HARD                15.0f
#define F_CORREL_BHATTACHARYYA_HARD         0.4f

#define F_CORREL_THRESH_NORMAL              0.55f
#define F_CORREL_INTERSECT_NORMAL           0.45f
#define F_CORREL_CHISQR_NORMAL              50.0f
#define F_CORREL_BHATTACHARYYA_NORMAL       0.45f

#define F_CORREL_THRESH_EASY                0.45f
#define F_CORREL_INTERSECT_EASY             0.40f
#define F_CORREL_CHISQR_EASY                90.0f
#define F_CORREL_BHATTACHARYYA_EASY         0.50f


@interface ViewController ()
<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *m_viewSrc;
@property (nonatomic, strong) IBOutlet UILabel *m_labelRet;
@property (nonatomic, strong) IBOutlet UILabel *m_labelData;
@property (nonatomic, strong) IBOutlet UILabel *m_labelRetHard;
@property (nonatomic, strong) IBOutlet UILabel *m_labelRetNormal;
@property (nonatomic, strong) IBOutlet UILabel *m_labelRetEasy;
@property (nonatomic, strong) IBOutlet UILabel *m_labelRetCanny;

@property (nonatomic, readonly) UIImagePickerController *m_picker;
@property (nonatomic, strong) UIImage *m_srcImg;
@property (nonatomic, readonly) UIView *m_viewCamera;
@property (nonatomic, readonly) NSTimer *m_timer;
@property (nonatomic, readonly) IplImage *m_iplImgSrc;
@property (nonatomic, readonly) CvHistogram *m_histSrc;

@end

@implementation ViewController
@synthesize m_picker = _picker;
@synthesize m_srcImg = _srcImg;
@synthesize m_viewCamera = _viewCamera;
@synthesize m_timer = _timer;
@synthesize m_iplImgSrc = _iplImgSrc;
@synthesize m_histSrc = _histSrc;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:1.0f];
    self.m_viewSrc.contentMode = UIViewContentModeScaleAspectFit;
    
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    _picker = [[UIImagePickerController alloc] init];
    _picker.delegate = self;
    _picker.allowsEditing = NO;
    _picker.sourceType = sourceType;
    
    [self performSelector:@selector(getPhoto) withObject:nil afterDelay:0.2f];
}

- (void)getPhoto
{
    [self presentViewController:_picker animated:YES completion:^(){}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    _timer = nil;
    [CameraImageHelper stopRunning];
    
    cvReleaseImage(&_iplImgSrc);
    _iplImgSrc = NULL;
    cvReleaseHist(&_histSrc);
    _histSrc = NULL;
    
    self.m_viewSrc = nil;
    self.m_labelData = nil;
    self.m_labelRet = nil;
    self.m_labelRetHard = nil;
    self.m_labelRetNormal = nil;
    self.m_labelRetEasy = nil;
    self.m_labelRetCanny = nil;
}

- (void)dealloc
{
    cvReleaseImage(&_iplImgSrc);
    cvReleaseHist(&_histSrc);
}

- (void)viewWillDisappear:(BOOL)animated
{
    if ([_timer isValid])
    {
        [_timer invalidate];
    }
    _timer = nil;
    [CameraImageHelper stopRunning];
}

- (void)startCamera
{
    [CameraImageHelper startRunning];
    _viewCamera = [CameraImageHelper previewWithBounds:CGRectMake(40.0f, 60.0f, 240.0f, 360.0f)];
    [self.view addSubview:_viewCamera];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.5f           // 每 0.5 秒取一张相片做匹配
                                              target:self
                                            selector:@selector(timerMethod:)
                                            userInfo:nil
                                             repeats:YES];
}

- (void)timerMethod:(NSTimer *)paramSender
{
    [self compareImgHist];
}

- (void)compareImgHist
{
    UIImage *img2 = [[CameraImageHelper image] copy];
    
    CGFloat objectWidth = img2.size.width;
    CGFloat objectHeight = img2.size.height;
    CGFloat scaledHeight = floorf(objectHeight / (objectWidth / 320.0f));
    CGSize newSize = CGSizeMake(320.0f, scaledHeight);
    UIGraphicsBeginImageContext(newSize);
    // Tell the old image to draw in this new context, with the desired
    // new size
    [img2 drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    // Get the new image from the context
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    // End the context
    UIGraphicsEndImageContext();
    
    IplImage * image2= [Utility CreateIplImageFromUIImage:newImage];
    
    CvHistogram *hist2 = [Utility getHSVHist:image2];
    
    // 归一化直方图
    cvNormalizeHist(hist2, 1);
    
    // 颜色匹配
    // 相关：CV_COMP_CORREL
    // 卡方：CV_COMP_CHISQR
    // 直方图相交：CV_COMP_INTERSECT
    // Bhattacharyya距离：CV_COMP_BHATTACHARYYA
    double  com1 = cvCompareHist(_histSrc,hist2, CV_COMP_CORREL);
    double  com2 = cvCompareHist(_histSrc,hist2, CV_COMP_INTERSECT);
    double  com3 = cvCompareHist(_histSrc,hist2, CV_COMP_CHISQR);
    double  com4 = cvCompareHist(_histSrc,hist2, CV_COMP_BHATTACHARYYA);
    
    BOOL bIsPassHard = NO;
    BOOL bIsPassNormal = NO;
    BOOL bIsPassEasy = NO;
    CGFloat fCorrelThreshold = F_CORREL_THRESH_HARD;
    CGFloat fIntersectThreshold = F_CORREL_INTERSECT_HARD;
    CGFloat fChisQRThreshold = F_CORREL_CHISQR_HARD;
    CGFloat fBhattacharyyaThreshold = F_CORREL_BHATTACHARYYA_HARD;

    fCorrelThreshold = F_CORREL_THRESH_HARD;
    fIntersectThreshold = F_CORREL_INTERSECT_HARD;
    fChisQRThreshold = F_CORREL_CHISQR_HARD;
    fBhattacharyyaThreshold = F_CORREL_BHATTACHARYYA_HARD;
    bIsPassHard = ((com1 > fCorrelThreshold) && (com2 > fIntersectThreshold) && (com3 < fChisQRThreshold) && (com4 < fBhattacharyyaThreshold));
    
    [self.m_labelRetHard setText:[NSString stringWithFormat:@"%@", bIsPassHard?@"YES":@"NO"]];
    [self.m_labelRetHard setTextColor:(bIsPassHard?[UIColor greenColor]:[UIColor redColor])];

    fCorrelThreshold = F_CORREL_THRESH_NORMAL;
    fIntersectThreshold = F_CORREL_INTERSECT_NORMAL;
    fChisQRThreshold = F_CORREL_CHISQR_NORMAL;
    fBhattacharyyaThreshold = F_CORREL_BHATTACHARYYA_NORMAL;
    bIsPassNormal = ((com1 > fCorrelThreshold) && (com2 > fIntersectThreshold) && (com3 < fChisQRThreshold) && (com4 < fBhattacharyyaThreshold));
    
    [self.m_labelRetNormal setText:[NSString stringWithFormat:@"%@", bIsPassNormal?@"YES":@"NO"]];
    [self.m_labelRetNormal setTextColor:(bIsPassNormal?[UIColor greenColor]:[UIColor redColor])];

    fCorrelThreshold = F_CORREL_THRESH_EASY;
    fIntersectThreshold = F_CORREL_INTERSECT_EASY;
    fChisQRThreshold = F_CORREL_CHISQR_EASY;
    fBhattacharyyaThreshold = F_CORREL_BHATTACHARYYA_EASY;
    bIsPassEasy = ((com1 > fCorrelThreshold) && (com2 > fIntersectThreshold) && (com3 < fChisQRThreshold) && (com4 < fBhattacharyyaThreshold));
    
    [self.m_labelRetEasy setText:[NSString stringWithFormat:@"%@", bIsPassEasy?@"YES":@"NO"]];
    [self.m_labelRetEasy setTextColor:(bIsPassEasy?[UIColor greenColor]:[UIColor redColor])];

    BOOL bIsPass = NO;//((com1 > fCorrelThreshold) && (com2 > fIntersectThreshold) && (com3 < fChisQRThreshold) && (com4 < fBhattacharyyaThreshold));
    NSString *strData = [NSString stringWithFormat:@"CORREL[     %f ]\nINTERSECT[    %f ]\nCHISQR[     %f ]\nBHATTACHARYYA[   %f ]\n", com1, com2, com3, com4];
    
    
//////////////////////////////////////////////////////////////////////////////////////////////
    
    // 边缘匹配 
    IplImage * mode= _iplImgSrc;
    IplImage * test= image2;
    
    IplImage* bw_mode = cvCreateImage(cvGetSize(mode),mode->depth,1);
    IplImage* bw_test = cvCreateImage(cvGetSize(test),mode->depth,1);
    IplImage* canny_mode = cvCreateImage(cvGetSize(mode),mode->depth,1);
    IplImage* canny_test = cvCreateImage(cvGetSize(test),mode->depth,1);
    
    cvCvtColor(mode,bw_mode,CV_RGB2GRAY);
    cvCvtColor(test,bw_test,CV_RGB2GRAY);
    
    //model contours
    cvCanny(bw_mode,canny_mode,50,60,3);
    
    //test contours
    cvCanny(bw_test,canny_test,50,60,3);
    
    double matching = cvMatchShapes( canny_test, canny_mode, CV_CONTOURS_MATCH_I3,0);
    
    if (bIsPassHard && (matching < 0.02/*0.055*/))
    {
        bIsPass = YES;
    }
    else if (bIsPassNormal && (matching < 0.02/*0.030*/))
    {
        bIsPass = YES;
    }
    else if (bIsPassEasy && (matching < 0.01/*0.015*/))
    {
        bIsPass = YES;
    }
    else if (matching < 0.006/*0.008*/)
    {
        bIsPass = YES;
    }
    else
    {
        bIsPass = NO;
    }
    
    strData = [strData stringByAppendingFormat:@"canny compare [%f]", matching];
    [self.m_labelRetCanny setText:[NSString stringWithFormat:@"%@", bIsPass?@"YES":@"NO"]];
    
    cvReleaseImage(&bw_mode);
    cvReleaseImage(&bw_test);
    cvReleaseImage(&canny_mode);
    cvReleaseImage(&canny_test);

    [self.m_labelRetCanny setTextColor:(bIsPass?[UIColor greenColor]:[UIColor redColor])];
    
    [self.m_labelData setText:strData];
    [self.m_labelRet setText:[NSString stringWithFormat:@"%@", bIsPass?@"YES":@"NO"]];
    [self.m_labelRet setTextColor:(bIsPass?[UIColor greenColor]:[UIColor redColor])];
    
    cvReleaseHist(&hist2);
    //cvReleaseImage(&image);
    cvReleaseImage(&image2);
    
    img2 = nil;
}

#pragma mark - picker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:^{}];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    [self performSelector:@selector(saveImage:)
               withObject:image
               afterDelay:0.0f];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{}];
}

- (void)saveImage:(UIImage *)image
{
    CGFloat fSmallImgWidth = 320.0f;
    
    BOOL bIsRotate = NO;
    switch (image.imageOrientation)
    {
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
        {
            bIsRotate = NO;
//            NSLog(@"UP [%d]", image.imageOrientation);
        }
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
        {
            bIsRotate = YES;
//            NSLog(@"LEFT [%d]", image.imageOrientation);
        }
            break;
        default:
            break;
    }
    
    CGRect rcSubRect;
    rcSubRect.origin.x = !bIsRotate ? image.size.width/8 : image.size.height/8;
    rcSubRect.origin.y = !bIsRotate ? image.size.height/8 : image.size.width/8;
    rcSubRect.size.width = !bIsRotate ? (image.size.width - image.size.width/4) : (image.size.height - image.size.height/4);
    rcSubRect.size.height = !bIsRotate ? (image.size.height - image.size.height/4) : (image.size.width - image.size.width/4);
    
    CGImageRef subImageRef = CGImageCreateWithImageInRect(image.CGImage, rcSubRect);
    CGRect smallBounds = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));
    
    UIGraphicsBeginImageContext(smallBounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, smallBounds, subImageRef);
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef scale:1.0f orientation:image.imageOrientation];
    UIGraphicsEndImageContext();
    
    CGFloat objectWidth = !bIsRotate ? smallBounds.size.width : smallBounds.size.height;
    CGFloat objectHeight = !bIsRotate ? smallBounds.size.height : smallBounds.size.width;
    CGFloat scaledHeight = floorf(objectHeight / (objectWidth / fSmallImgWidth));
    CGSize newSize = CGSizeMake(fSmallImgWidth, scaledHeight);
    UIGraphicsBeginImageContext(newSize);
    // Tell the old image to draw in this new context, with the desired
    // new size
    [smallImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    // Get the new image from the context
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    // End the context
    UIGraphicsEndImageContext();

    
//////////////////////////////////////////////////////////////////////////////////////////////

    // 显示原图
    self.m_srcImg = [newImage copy];
    self.m_viewSrc.image = self.m_srcImg;
    
    // 原图计算直方图
    _iplImgSrc = [Utility CreateIplImageFromUIImage:self.m_srcImg];
    _histSrc = [Utility getHSVHist:_iplImgSrc];
    cvNormalizeHist(_histSrc, 1);
    
    // 启动摄像头，开始与摄像头图像匹配
    [self performSelector:@selector(startCamera) withObject:nil afterDelay:0.5f];

//////////////////////////////////////////////////////////////////////////////////////////////
    
    
    CGImageRelease(subImageRef);
    
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error != NULL)
    {
        // 保存出错
        // ...
    }
    else  // No errors
    {
    }
}






















@end
