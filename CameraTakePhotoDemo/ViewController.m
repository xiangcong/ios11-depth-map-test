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
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIImage *retImage;

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
    [self.captureButton setTitle:@"拍摄" forState:UIControlStateNormal];
    
    self.saveButton = [[UIButton alloc] initWithFrame:CGRectMake(self.screenWidth / 2 + 80, self.screenHeight - 60, 80, 40)];
    self.saveButton.backgroundColor = [UIColor colorWithRed:0 green:1.0 blue:0.0 alpha:0.5];
    self.saveButton.hidden = YES;
    self.saveButton.userInteractionEnabled = NO;
    [self.saveButton setTitle:@"保存" forState:UIControlStateNormal];
    [self.view addSubview:self.saveButton];
    [self.saveButton addTarget:self action:@selector(handleSave) forControlEvents:UIControlEventTouchUpInside];
    
    
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


- (void) handleSave
{
    if (self.retImage) {
        UIImageWriteToSavedPhotosAlbum(self.retImage,self,nil,nil);
    }
}

- (void) captureImage
{
    static BOOL status = NO;
    
    if (!status) {
//        NSDictionary *setDic = @{AVVideoCodecKey:AVVideoCodecJPEG};
//        AVCapturePhotoSettings *setting = [AVCapturePhotoSettings photoSettingsWithFormat:setDic];
        AVCapturePhotoSettings *setting = [AVCapturePhotoSettings new];
//        setting.embedsDepthDataInPhoto = YES;
        setting.depthDataDeliveryEnabled = YES;
        
        setting.highResolutionPhotoEnabled = YES;
        
        [self.output capturePhotoWithSettings:setting
                                     delegate:self];
    } else {
        self.retView.hidden = YES;
        self.saveButton.hidden = YES;
        self.saveButton.userInteractionEnabled = NO;
        [self.captureButton setTitle:@"拍摄" forState:UIControlStateNormal];
        self.captureButton.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.5];
    }

    status = !status;
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error;
{
    NSLog(@"capture a image");
    
    AVDepthData *depthDataOrigin = photo.depthData;

    AVDepthData *depthData = [depthDataOrigin depthDataByConvertingToDepthDataType:kCVPixelFormatType_DepthFloat32];

    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:depthData.depthDataMap];
    
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext
                             createCGImage:ciImage
                             fromRect:CGRectMake(0, 0,
                                                 CVPixelBufferGetWidth(depthData.depthDataMap),
                                                 CVPixelBufferGetHeight(depthData.depthDataMap))];
    
    UIImage *uiImage = [UIImage imageWithCGImage:videoImage];

    self.retImage = [self normalizeImage:uiImage];

    //旋转
    self.retImage = [[UIImage alloc] initWithCGImage: self.retImage.CGImage
                                                           scale: 1.0
                                                     orientation: UIImageOrientationRight];

    self.retView.image = self.retImage;




    self.retView.hidden = NO;
    self.captureButton.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.5];
    [self.captureButton setTitle:@"恢复" forState:UIControlStateNormal];
    self.saveButton.userInteractionEnabled = YES;
    self.saveButton.hidden = NO;

    CGImageRelease(videoImage);
    
}


- (UIImage *) normalizeImage:(UIImage *) image
{
    UInt8 minVal = 255;
    UInt8 maxVal = 0;
    CGImageRef imageRef = image.CGImage;
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    UInt8* data = CFDataGetBytePtr(pixelData);
    
    for(int x = 0; x < image.size.width; ++x){
        for(int y = 0; y < image.size.height; ++y) {
            int pixelInfo = ((image.size.width  * y) + x ) * 4;
            UInt8 red = data[pixelInfo];
            if (red > maxVal) {
                maxVal = red;
            }
            if (red < minVal) {
                minVal = red;
            }
            if (red != 255) {
            }
        }
    }
    NSLog(@"max val:%u, min val:%u", maxVal, minVal);
    
    //更改值
    for(int x = 0; x < image.size.width; ++x){
        for(int y = 0; y < image.size.height; ++y) {
            int pixelInfo = ((image.size.width  * y) + x ) * 4; // The image is png ??
            UInt8 red = data[pixelInfo];
            UInt8 green = data[pixelInfo + 1];
            UInt8 blue = data[pixelInfo + 2];
            
            data[pixelInfo] = (float)(red - minVal) / (maxVal - minVal) * 255;
            data[pixelInfo+1] = (float)(green - minVal) / (maxVal - minVal) * 255;
            data[pixelInfo+2] = (float)(blue - minVal) / (maxVal - minVal) * 255;
        }
    }
    
    size_t width                    = CGImageGetWidth(imageRef);
    size_t height                   = CGImageGetHeight(imageRef);
    size_t bitsPerComponent         = CGImageGetBitsPerComponent(imageRef);
    size_t bitsPerPixel             = CGImageGetBitsPerPixel(imageRef);
    size_t bytesPerRow              = CGImageGetBytesPerRow(imageRef);
    
    CGColorSpaceRef colorspace      = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo         = CGImageGetBitmapInfo(imageRef);
    CGDataProviderRef provider      = CGDataProviderCreateWithData(NULL, data, [(__bridge NSData *)pixelData length], NULL);
    
    CGImageRef newImageRef = CGImageCreate (
                                            width,
                                            height,
                                            bitsPerComponent,
                                            bitsPerPixel,
                                            bytesPerRow,
                                            colorspace,
                                            bitmapInfo,
                                            provider,
                                            NULL,
                                            false,
                                            kCGRenderingIntentDefault
                                            );
    // the modified image
    UIImage *newImage   = [UIImage imageWithCGImage:newImageRef];
    
    // cleanup
//    CFRelease(pixelData);
//    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorspace);
    CGDataProviderRelease(provider);
    CGImageRelease(newImageRef);
    
    return newImage;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
