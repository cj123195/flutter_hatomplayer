//
//  GLRender.h
//  Runner
//
//  Created by jonasluo on 2019/12/12.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLRender : NSObject <FlutterTexture>

- (instancetype)initWidthCVBufferRef:(CVPixelBufferRef)pixelbufferref;

@end

NS_ASSUME_NONNULL_END
