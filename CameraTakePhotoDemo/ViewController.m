//
//  ViewController.m
//  CameraTakePhotoDemo
//
//  Created by jingjinzhou on 10/9/17.
//  Copyright © 2017年 jingjinzhou. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <AVCapturePhotoCaptureDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) UIImageView *previewView;
@property (nonatomic, strong) AVCapturePhotoOutput *output;
@property (nonatomic, strong) UIButton *captureButton;
@property (nonatomic, assign) float screenHeight;
@property (nonatomic, assign) float screenWidth;
@property (nonatomic, strong) UIImageView *retView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.previewView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.previewView];
    self.retView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.retView];
    self.retView.hidden = YES;
    self.retView.contentMode = UIViewContentModeScaleAspectFill;
    
    
    self.screenWidth = self.view.bounds.size.width;
    self.screenHeight = self.view.bounds.size.height;
    self.captureButton = [[UIButton alloc] initWithFrame:CGRectMake(self.screenWidth / 2 - 40, self.screenHeight - 60, 80, 40)];
    self.captureButton.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.5];
    [self.view addSubview:self.captureButton];
    [self.captureButton addTarget:self action:@selector(captureImage) forControlEvents:UIControlEventTouchUpInside];
    
    self.session = [AVCaptureSession new];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera
                                                                 mediaType:AVMediaTypeVideo
                                                                  position:AVCaptureDevicePositionBack];
    
    NSError *cameraInputError = nil;
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&cameraInputError];
    if (cameraInputError) {
        NSLog(@"创建deviceshibai");
    }
    [self.session addInput:input];
    
    self.output = [AVCapturePhotoOutput new];
    

    self.output.highResolutionCaptureEnabled = YES;
    
    
    [self.session addOutput:self.output];
    
    
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [captureVideoPreviewLayer setFrame:self.previewView.bounds];
    [self.previewView.layer addSublayer:captureVideoPreviewLayer];
    
    self.output.depthDataDeliveryEnabled = YES;
    
    if (self.output.depthDataDeliverySupported) {
        NSLog(@"support depth");
    } else {
        NSLog(@"not support depth");
    }
    
    [self.session startRunning];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void) captureImage
{
    static BOOL status = NO;
    
    if (!status) {
        NSDictionary *setDic = @{AVVideoCodecKey:AVVideoCodecJPEG};
        AVCapturePhotoSettings *setting = [AVCapturePhotoSettings photoSettingsWithFormat:setDic];
        setting.embedsDepthDataInPhoto = YES;
        setting.depthDataDeliveryEnabled = YES;
        
        setting.highResolutionPhotoEnabled = YES;
        
        [self.output capturePhotoWithSettings:setting
                                     delegate:self];
        self.captureButton.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.5];
    } else {
        self.retView.hidden = YES;
        self.captureButton.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.5];
    }

    status = !status;
}

//- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error {
//
//
//    NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
//    UIImage *image = [UIImage imageWithData:data];
//
//    self.retView.image = image;
//    self.retView.hidden = NO;
//}



//- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error;
//{
//    NSLog(@"capture a image");
//
//    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:photo.pixelBuffer];
//
//    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
//    CGImageRef videoImage = [temporaryContext
//                             createCGImage:ciImage
//                             fromRect:CGRectMake(0, 0,
//                                                 CVPixelBufferGetWidth(photo.pixelBuffer),
//                                                 CVPixelBufferGetHeight(photo.pixelBuffer))];
//
//    UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
//
////
////    self.depthImageView.image = [[UIImage alloc] initWithCGImage: uiImage.CGImage
////                                                           scale: 1.0
////                                                     orientation: UIImageOrientationRight];
//    CGImageRelease(videoImage);
//}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error;
{
        NSLog(@"capture a image");
        
        AVDepthData *depthData = photo.depthData;
        
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:depthData.depthDataMap];
        
        CIContext *temporaryContext = [CIContext contextWithOptions:nil];
        CGImageRef videoImage = [temporaryContext
                                 createCGImage:ciImage
                                 fromRect:CGRectMake(0, 0,
                                                     CVPixelBufferGetWidth(depthData.depthDataMap),
                                                     CVPixelBufferGetHeight(depthData.depthDataMap))];
        
        UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
        
        //旋转
        self.retView.image = [[UIImage alloc] initWithCGImage: uiImage.CGImage
                                                               scale: 1.0
                                                         orientation: UIImageOrientationRight];
//        self.retView.image = uiImage;
    
        self.retView.hidden = NO;
        CGImageRelease(videoImage);
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
