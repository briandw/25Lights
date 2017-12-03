//
//  LightsModelProcessor.m
//  ImageRecognizer
//
//  Created by Brian Williams on 12/6/17.
//  Copyright © 2017 Rantlab. All rights reserved.
//

#import "LightsModelProcessor.h"
#import "Lights.h"
@import CoreML;

@interface LightsModelProcessor()
@property (nonatomic, strong) Lights *model;
@end

@implementation LightsModelProcessor

//convert a 8 grayscale UIImage into an input for the model
+ (LightsInput *)inputFromImage:(UIImage *)image
{
    NSError *error;
    MLMultiArray *inputArray = [[MLMultiArray alloc] initWithShape:@[@(1), @(image.size.width), @(image.size.height)]
                                                          dataType:MLMultiArrayDataTypeFloat32
                                                             error:&error];
    CGImageRef imageRef = image.CGImage;
    
    // Create a bitmap context to draw the uiimage into
    CGContextRef context = [self newBitmapContextFromImage:imageRef];
    
    if (context)
    {
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        
        CGRect rect = CGRectMake(0, 0, width, height);
        
        // Draw image into the context to get the raw image data
        CGContextDrawImage(context, rect, imageRef);
        
        // Get a pointer to the data
        unsigned char *bitmapData = (unsigned char *)CGBitmapContextGetData(context);
        
        if (bitmapData)
        {
            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    // get the individual pixel intensities from the bitmap
                    uint8_t pixel = (uint8_t)bitmapData[y * width + x];
                    
                    // copy the values of the grayscale pixel intensities to the input tensor
                    //convert to a float value
                    inputArray[y*width + x] = @((float)pixel/255.0);
                }
            }
            
            free(bitmapData);
        }
        else
        {
            NSLog(@"Error getting bitmap pixel data\n");
        }
        
        CGContextRelease(context);
    }
    
    return [[LightsInput alloc] initWithInput1:inputArray];
}

+ (CGContextRef) newBitmapContextFromImage:(CGImageRef) image
{
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    uint32_t *bitmapData;
    
    size_t bitsPerPixel = 8;
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;
    
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    size_t bytesPerRow = width * bytesPerPixel;
    size_t bufferLength = bytesPerRow * height;
    
    colorSpace = CGColorSpaceCreateDeviceGray();
    
    if(!colorSpace)
    {
        NSLog(@"Error allocating color space RGB\n");
        return NULL;
    }
    
    // Allocate memory for image data
    bitmapData = (uint32_t *)malloc(bufferLength);
    
    if (!bitmapData)
    {
        NSLog(@"Error allocating memory for bitmap\n");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    
    //Create bitmap context
    
    context = CGBitmapContextCreate(bitmapData,
                                    width,
                                    height,
                                    bitsPerComponent,
                                    bytesPerRow,
                                    colorSpace,
                                    kCGImageAlphaNone);
    if (!context)
    {
        free(bitmapData);
        NSLog(@"Bitmap context not created");
    }
    
    CGColorSpaceRelease(colorSpace);
    
    return context;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _model = [[Lights alloc] init];
    }
    
    return self;
}

- (NSArray *)predictionFromImage:(UIImage *)image
{
    LightsInput *input = [LightsModelProcessor inputFromImage:image];
    LightsOutput *output = [self.model predictionFromFeatures:input
                                                        error:nil];
    MLMultiArray *outputArray = output.output1;
    
    int width = 5;
    int height = 5;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:25];
    for (int x = width-1; x >=0 ; x--)
    {
        for (int y = 0; y < height; y++)
        {
            float bit = [outputArray[y*width + x] floatValue];
            [array addObject:@(bit)];
        }
    }
    
    return array;
}

@end
