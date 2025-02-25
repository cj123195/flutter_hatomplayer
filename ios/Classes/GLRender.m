//
//  GLRender.m
//  Runner
//
//  Created by jonasluo on 2019/12/12.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "GLRender.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreVideo/CoreVideo.h>
#import <UIKit/UIKit.h>

@implementation GLRender
{
    CVPixelBufferRef _target;
}

- (CVPixelBufferRef)copyPixelBuffer {
    CVBufferRetain(_target);
//    NSLog(@"gl-render copy pixel buffer ....");
    return _target;
}

- (instancetype)initWidthCVBufferRef:(CVPixelBufferRef)pixelbufferref
{
    if(self = [super init])
    {
        _target = pixelbufferref;
//        NSLog(@"gl-render init with pixel-buffer");
    }
    
    return self;
}

@end
