#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <AVCaptureDepthDataOutputDelegate>
@property (nonatomic, strong) UIImageView *cameraImageView;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureDepthDataOutput *depthOutput;
@end

@implementation ViewController

- (UIImageView *)cameraImageView{
    if (!_cameraImageView) {
        _cameraImageView = [[UIImageView alloc] initWithFrame:CGRectMake(50, 230, 200, 200)];
    }
    return _cameraImageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 采集按钮
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    btn.backgroundColor = [UIColor grayColor];
    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    // 拍照
    UIButton *btn1 = [[UIButton alloc] initWithFrame:CGRectMake(220, 100, 100, 100)];
    btn1.backgroundColor = [UIColor blackColor];
    [btn1 addTarget:self action:@selector(btnClick1:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn];
    [self.view addSubview:btn1];
    [self.view addSubview:self.cameraImageView];
}

// 按钮点击事件
- (void)btnClick:(id)sender{
    [self openCamera:AVCaptureDevicePositionBack];
}

// 拍照
- (void)btnClick1:(id)sender{
    AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [UIImage imageWithData:imageData];
        self.cameraImageView.image = image;
        [self.session stopRunning];
    }];
}

// 采集
- (void)openCamera:(AVCaptureDevicePosition)cameraPostion{
    BOOL hasCamera = [[AVCaptureDevice devices] count] >0;
    if (hasCamera) {
        _session = [[AVCaptureSession alloc] init];
        _session.sessionPreset = AVCaptureSessionPresetPhoto;
        
        AVCaptureDevice *device = [self getCamera:cameraPostion];
        NSError *error = nil;
        
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        [_session addInput:input];
#if 0
        
        _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        _stillImageOutput.outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
        
        [_session addOutput:_stillImageOutput];
#endif
#if 0
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        
        _videoOutput.videoSettings = [NSDictionary dictionaryWithObject:
         [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                                 forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [_session addOutput:_videoOutput];
#endif
        
#if 1
        _depthOutput = [AVCaptureDepthDataOutput new];
        [_depthOutput setDelegate:self callbackQueue:dispatch_get_main_queue()];
        [_session addOutput:_depthOutput];
#endif
        
        
        AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
        [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [captureVideoPreviewLayer setFrame:self.cameraImageView.bounds];
        [self.cameraImageView.layer addSublayer:captureVideoPreviewLayer];
        
        [_session startRunning];
        
    }
}

- (void)depthDataOutput:(AVCaptureDepthDataOutput *)output didOutputDepthData:(AVDepthData *)depthData timestamp:(CMTime)timestamp connection:(AVCaptureConnection *)connection;
{
    NSLog(@"hi");
}

- (void)depthDataOutput:(AVCaptureDepthDataOutput *)output
       didDropDepthData:(AVDepthData *)depthData
              timestamp:(CMTime)timestamp
             connection:(AVCaptureConnection *)connection
                 reason:(AVCaptureOutputDataDroppedReason)reason;
{
    NSLog(@"drop");
}



// 获取device
- (AVCaptureDevice *)getCamera:(AVCaptureDevicePosition)cameraPostion{
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in cameras) {
        if (device.position == cameraPostion) {
            return device;
        }
    }
    
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;
{
    UIImage *curImage = [self imageFromSampleBuffer:sampleBuffer];
    self.cameraImageView.image = curImage;
}


- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

@end
