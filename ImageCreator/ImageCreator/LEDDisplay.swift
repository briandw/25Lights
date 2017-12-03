//
//  LEDDisplay.swift
//  25LightsDisplay
//
//  Created by Brian Williams on 10/25/17.
//  Copyright © 2017 Rantlab. All rights reserved.
//

import AppKit
import Quartz
import Cocoa

class LEDView: NSView
{
    let randomize = false
    let CIRCLE_SIZE = CGFloat(200)
    let LED_WIDE = 5
    let LED_HIGH = 5
    let NUM_LEDS = 25
    let LED_RADIUS = 16
    let LED_SPACING = 9
    let X_OFFSET = 42
    let Y_OFFSET = 40
    let BACKGROUND_COLOR = CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    let LED_COLOR = CGColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
    
    let MAX_ROTATION = CGFloat(Float.pi/30.0)
    let MAX_OFFSET = CGFloat(100)
    let MIN_SCALE = CGFloat(0.90)
    let MAX_SCALE = CGFloat(1.25)
    
    var _bits : UInt32 = 0;
    func drawData(bits:UInt32)
    {
        _bits = bits
        self.display()
    }
    
    func randFloat()->CGFloat
    {
        return CGFloat(CGFloat(arc4random())/CGFloat(UINT32_MAX))
    }
    
    override func draw(_ dirtyRect: NSRect)
    {
        super.draw(dirtyRect)
        
        if let context = NSGraphicsContext.current?.cgContext
        {
            context.saveGState();

            var transform = CGAffineTransform(translationX:(self.bounds.size.width-CIRCLE_SIZE)/2.0,
                                              y:(self.bounds.size.height-CIRCLE_SIZE)/2.0)
            if (randomize)
            {
                let rot =  MAX_ROTATION - (randFloat() * MAX_ROTATION * 2)
                transform = transform.rotated(by: rot)
                
                let xOffset = MAX_OFFSET - (randFloat() * MAX_OFFSET * 2)
                let yOffset = MAX_OFFSET - (randFloat() * MAX_OFFSET * 2)
                transform = transform.translatedBy(x: xOffset, y: yOffset)
                
                var xScale = randFloat() * MAX_SCALE
                if (xScale < MIN_SCALE) {xScale = MIN_SCALE}
                var yScale = randFloat() * MAX_SCALE
                if (yScale < MIN_SCALE) {yScale = MIN_SCALE}
                transform = transform.scaledBy(x: xScale, y: yScale)
            }
            
            context.concatenate(transform)
            context.setFillColor(BACKGROUND_COLOR)
            context.fillEllipse(in: CGRect(x:0, y:0, width:CIRCLE_SIZE, height:CIRCLE_SIZE))
            
            for y in 0..<LED_HIGH
            {
                for x in 0..<LED_WIDE
                {
                    let bit = x * LED_WIDE + y
                    if (0x00000001 & (_bits >> bit) == 1)
                    {
                        context.setFillColor(LED_COLOR)
                        let rect =  CGRect(x:X_OFFSET + x * (LED_RADIUS+LED_SPACING),
                                           y:Y_OFFSET + y * (LED_RADIUS+LED_SPACING),
                                           width:LED_RADIUS,
                                           height:LED_RADIUS)
                        
                        context.fillEllipse(in: rect)
                    }
                }
            }
            
//            let x = CGFloat(X_OFFSET + 2 * (LED_RADIUS+LED_SPACING))
//            let y = CGFloat(20)
//            context.setFillColor(NSColor.white.cgColor)
//            context.fillEllipse(in: CGRect(x:x, y:y, width:10, height:10))
            
            context.restoreGState();
        }
    }
    
}



