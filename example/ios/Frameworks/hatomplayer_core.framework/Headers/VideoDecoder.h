//
//  VideoDecoder.h
//  hatom-player-core
//
//  Created by chenmengyi on 2020/11/3.
//

#import <UIKit/UIKit.h>
#import <hatomplayer_core/PlayConfig.h>
#import <hatomplayer_core/Constrants.h>
#import <Foundation/Foundation.h>

@class VideoDecoder;

NS_ASSUME_NONNULL_BEGIN

@protocol VideoDecoderDelegate <NSObject>

/// 播放状态回调方法
/// @param status 播放状态
/// @param errorCode 错误码，只有在 status 状态为： FAILED 、EXCEPTION 才有值 ,其他 status 值为 -1
- (void)onPlayerStatus:(PlayStatus)status errorCode:(NSString *)errorCode;

/**
 * 解码数据回调
 * @param width 图像宽
 * @param height 图像高
 * @param stamp 当前视频帧时间戳
 * @param type 当前帧类型
 * @param dataLen 数据长度
 * @param data 数据
 */
- (void)onDataCallback:(int)width height:(int)height stamp:(int)stamp type:(int)type dataLen:(int)dataLen data:(void *)data;

@optional
/// Flutter渲染回调
/// @param pCVBuffer pCVBuffer
/// @param port 端口号
/// @param decoder 解码器
- (void)setupFlutter:(void *)pCVBuffer subPort:(int)port decoder:(VideoDecoder *)decoder;

/// 纹理id回调
/// @param textureId 纹理id
/// @param decoder 解码器
- (void)textureFrameAvailable:(int)textureId decoder: (VideoDecoder *)decoder;

@end

@interface VideoDecoder : NSObject

@property(nonatomic, weak) id<VideoDecoderDelegate> delegate;

/// 端口号
@property(nonatomic, assign) int port;

- (void)setPlayConfig:(PlayConfig *)playConfig;

/// 处理流头
/// @param data 流头数据
/// @param length 长度
/// @param type 流类型
- (int)handleStreamHeader:(void *)data length:(int)length type:(FetchStreamType)type;

/// 处理流body
/// @param data body数据
/// @param length 长度
/// @param type 流类型
- (int)handleStreamData:(void *)data length:(int)length type:(FetchStreamType)type;

/// 对讲数据处理
/// @param data 对讲数据
/// @param length 数据长度
- (int)handleVoiceStreamData:(void *)data length:(int)length;

/// 消息回调
/// @param type 类型
/// @param errorCode 错误码
- (void)handleMessage:(FetchStreamType)type errCode:(int)errorCode;

/// 设置显示窗口
/// @param view 播放view
- (int)setVideoWindow:(UIView *)view;

/// 回放结束
- (void)playbackFinish;

/// 暂停
- (int)pause;

/// 继续播放
- (int)resume;

/// 停止
- (int)stop;

/// 声音操作
/// @param enable YES-开启  NO-关闭
- (int)enableAudio:(BOOL)enable;

/// 播放本地的录像文件
/// @param path 文件路径
- (int)playFile:(NSString *)path;

/**
 获取本地播放文件的总时间

 @return 总时间
 */
- (int)getTotalTime;

/**
获取当前视频播放时间

@return 当前播放时长
*/
- (int)getPlayedTime;

/**
 设置播放进度

 @param progress 播放进度（占总时间的百分比）
 */
- (int)setPlayProgress:(float)progress;

/// 设置多线程解码线程数（硬解不支持设置解码线程）
/// @param threadNum 线程数
- (BOOL)setDecodeThreadNum:(int)threadNum;

/// 获取当前码流帧率
- (int)getFrameRate;

/// 设置期望帧率
/// @param frameRate 帧率
- (BOOL)setExpectedFrameRate:(int)frameRate;

/// 开启录像
/// @param mediaFilePath 保存路径
- (int)startRecord:(NSString *)mediaFilePath;

/// 开始录像同时转码(转码是指转码为系统播放器可以识别的标准 mp4封装）
/// @param mediaFilePath 保存路径
- (int)startRecordAndConvert:(NSString *)mediaFilePath;

/// 停止紧急录像
- (int)stopRecord;

/// 抓图
- (nullable NSData *)screenshoot;

/// 抓图
/// @param path 大图路径
/// @param thumbnailPath 缩略图路径
- (int)screenshoot:(NSString *)path thumbnail:(NSString *)thumbnailPath;

/// 快进
- (int)fast;

/// 慢进
- (int)slow;

///重置解析缓存
- (int)resetSourceBuffer;

/// 刷新画面
- (void)refreshPlay;

/// 获取流量
- (long)getTotalTraffic;

/// 获取osdTime
- (long)getOSDTime;

/// 电子放大
/// @param original 原有的位置
/// @param current 当前位置
- (int)openDigitalZoom:(CGRect)original current:(CGRect)current;

/// 关闭电子放大
- (int)closeDigitalZoom;

/// 开启鱼眼，有关鱼眼功能的开启流程请查看鱼眼模块函数调用顺序
/// @param correctType 矫正方式
/// @param placeType 安装方式
- (int)openFishEyeMode:(FishEyeCorrectType)correctType placeType:(FishEyePlaceType)placeType;

/// 开启/关闭鱼眼
/// @param enable 开启-YES  关闭-NO
- (int)setFishEyeEnable:(BOOL)enable;

/// 处理鱼眼矫正
/// @param isZoom 是否缩放
/// @param zoom 缩放系数
/// @param originalPoint 原始点（或者上次操作的点）
/// @param currentPoint 当前点
/// @param translationPoint 拖动的距离
- (int)handleFishEyeCorrect:(BOOL)isZoom zoom:(float)zoom originalPoint:(CGPoint)originalPoint currentPoint:(CGPoint)currentPoint translationPoint:(CGPoint)translationPoint;

@end

NS_ASSUME_NONNULL_END
