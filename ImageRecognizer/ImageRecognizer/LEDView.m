//
//  LEDView.m
//  25LightsML
//
//  Created by Brian Williams on 11/1/17.
//  Copyright © 2017 Rantlab. All rights reserved.
//

#import "LEDView.h"

@interface LEDView()
@property (nonatomic, strong) NSArray *bits;
@end

@implementation LEDView

- (void)drawArray:(NSArray *)bits
{
    _bits = bits;
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    int LED_WIDE = 5;
    int LED_HIGH = 5;
    int LED_RADIUS = 16;
    int LED_SPACING = 9;
    int X_OFFSET = 40;
    int Y_OFFSET = 38;
    
    [super drawRect:rect];
    
    CGSize size = self.bounds.size;
    if (size.width < size.height)
    {
        size.height = size.width;
    }
    else
    {
        size.width = size.height;
    }
    
    CGRect ellipse = CGRectMake(0, 0, size.width, size.height);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillEllipseInRect(context, ellipse);
    
    for (int y = 0; y < LED_HIGH; y++)
    {
        for (int x = 0; x < LED_WIDE; x++)
        {
            CGFloat alpha = [self.bits[y*LED_WIDE + x] floatValue];
            UIColor *color = [UIColor colorWithWhite:1.0 alpha:alpha];
            CGContextSetFillColorWithColor(context, color.CGColor);
            CGRect rect =  CGRectMake(X_OFFSET + x * (LED_RADIUS+LED_SPACING),
                                      Y_OFFSET + y * (LED_RADIUS+LED_SPACING),
                                      LED_RADIUS,
                                      LED_RADIUS);
            CGContextFillEllipseInRect(context, rect);
            
        }
    }
}

@end
