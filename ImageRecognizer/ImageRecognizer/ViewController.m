//
//  ViewController.m
//  25LightsML
//
//  Created by Brian Williams on 11/1/17.
//  Copyright © 2017 Rantlab. All rights reserved.
//

@import AVFoundation;

#import "ViewController.h"
#import "LEDView.h"
#import "LightsModelProcessor.h"

@interface ViewController () <AVCapturePhotoCaptureDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSesssion;
@property (nonatomic, strong) AVCapturePhotoOutput *cameraOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, weak) IBOutlet UIView *preview;
@property (nonatomic, weak) IBOutlet LEDView *ledView;
@property (nonatomic, strong) LightsModelProcessor *modelProcessor;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.modelProcessor = [[LightsModelProcessor alloc] init];
    self.captureSesssion = [[AVCaptureSession alloc] init];
    self.captureSesssion.sessionPreset = AVCaptureSessionPresetPhoto;
    self.cameraOutput = [[AVCapturePhotoOutput alloc] init];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device)
    {
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
        if (input)
        {
            if ([self.captureSesssion canAddInput:input])
            {
                [self.captureSesssion addInput:input];
                
                if ([self.captureSesssion canAddOutput:_cameraOutput])
                {
                    [self.captureSesssion addOutput:_cameraOutput];
                    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSesssion];
                    self.previewLayer.frame = self.preview.bounds;
                    [self.preview.layer addSublayer:self.previewLayer];
                    [self.captureSesssion startRunning];
                }
            }
        }
    }
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status != AVAuthorizationStatusAuthorized)
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted){
            [self shoot:nil];
        }];
    }
    else
    {
        [self shoot:nil];
    }
}

- (IBAction)shoot:(id)sender
{
    AVCapturePhotoSettings *settings = [[AVCapturePhotoSettings alloc] init];
    NSNumber *pixelType = settings.availablePreviewPhotoPixelFormatTypes.firstObject;

    NSDictionary *previewFormat = @{
                                    (NSString *)kCVPixelBufferPixelFormatTypeKey:pixelType,
                                    (NSString *)kCVPixelBufferWidthKey: @(128),
                                    (NSString *)kCVPixelBufferHeightKey: @( 128)
                                    };
                                    
    settings.previewPhotoFormat = previewFormat;
    [self.cameraOutput capturePhotoWithSettings:settings delegate:self];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error
{
    NSData *imageData = [photo fileDataRepresentation];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)imageData);
    CGImageRef cgImage = CGImageCreateWithJPEGDataProvider(provider, nil, true, kCGRenderingIntentDefault);
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];
        
    CGSize size = CGSizeMake(128, 128);
    CGRect rect = CGRectMake(0, 0, 128, 128);
    UIGraphicsBeginImageContextWithOptions(size, true, 1.0);
    [image drawInRect:rect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSArray *prediction = [self.modelProcessor predictionFromImage:image];
    [self.ledView drawArray:prediction];
    [self performSelector:@selector(shoot:) withObject:nil afterDelay:0.5];
}

@end
