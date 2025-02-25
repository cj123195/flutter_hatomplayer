//
//  HatomSDKPlayer.m
//  flutter_hatomplayer
//
//  Created by chenmengyi on 2022/2/24.
//

#import "HatomSDKPlayer.h"
#import "AsyncBlockOperation.h"
#import "NSOperationQueue+CompletionBlock.h"
#import <hatomplayer_core/Constrants.h>
#import <hatomplayer_core/HatomPlayer.h>
#import <hatomplayer_core/FlutterHatomPlayer.h>

@interface HatomSDKPlayer()
<HatomPlayerDelegate>

@property(nonatomic, strong) HatomPlayer *player;
@property (nonatomic, strong) NSMutableData *testdatas;
@property (nonatomic, strong) StreamClient *streamClient;
@property (nonatomic, strong) NSOperationQueue * playerQueue;



@end

@implementation HatomSDKPlayer

/// 播放器设置
/// @param playConfig 配置信息
/// @param path 播放url
/// @param headers 请求头信息
- (instancetype)initPlayerWithPlayConfig:(PlayConfig*)playConfig path:(NSString *)path headers:(NSDictionary *)headers {
    self = [super init];
    if (self) {
        // 默认是hpsclient取流
        _player = [[FlutterHatomPlayer alloc] init];
        // npclient取流
        if (playConfig.fetchStreamType == 2) {
            _streamClient = [[NSClassFromString(@"NPStreamClient") alloc] init:nil];
            if (_streamClient) {
                _player.streamClient = _streamClient;
                __weak __typeof(_player) weakPlayer = _player;
                _player.streamClient.delegate = weakPlayer;
            } else {
                NSLog(@"请先引入NPStreamClient！！！！！");
            }
        } else if (playConfig.fetchStreamType == 1) {
            // hcnet取流
            _streamClient = [[NSClassFromString(@"HCNetStreamClient") alloc] init:nil];
            if (_streamClient) {
                _player.streamClient = _streamClient;
                __weak __typeof(_player) weakPlayer = _player;
                _player.streamClient.delegate = weakPlayer;
            } else {
                NSLog(@"请先引入HCNetStreamClient！！！！！");
            }
        }
        _player.delegate = self;
        _playerQueue = [[NSOperationQueue alloc] init];
        _playerQueue.qualityOfService = NSQualityOfServiceUserInitiated;
        _playerQueue.maxConcurrentOperationCount = 1;
        __weak typeof (self) weakSelf = self;
        _playerQueue.completionBlock = ^{
            NSLog(@"【✅】%p one operation has been finished!✅✅✅", weakSelf.playerQueue);
        };
        
        [_playerQueue addOperationWithAsyncBlock:^(AsyncBlockOperation * _Nonnull op) {
            [weakSelf.player setPlayConfig:playConfig];
            [weakSelf.player setDataSource:path headers:headers];
            [op complete];
        }];
    }
    return self;
}

/// 设置播放参数
/// @param path 播放url
/// @param headers 请求参数
- (void)setDataSource:(nullable NSString *)path headers:(nullable NSDictionary *)headers {
    [self.player setDataSource:path headers:headers];
}

/// 配置播放参数
- (void)setPlayConfig:(PlayConfig *)playConfig {
    [self.player setPlayConfig:playConfig];
}

/// 开启播放
- (void)start {
    __weak typeof (self) weakSelf = self;
    [_playerQueue addOperationWithAsyncBlock:^(AsyncBlockOperation * _Nonnull op) {
        [weakSelf.player start];
        [op complete];
    }];
}

/// 停止播放
- (void)stop {
    __weak typeof (self) weakSelf = self;
    [_playerQueue addOperationWithAsyncBlock:^(AsyncBlockOperation * _Nonnull op) {
        [weakSelf.player stop];
        [op complete];
    }];
}

/// 声音操作
/// @param enable YES-开启  NO-关闭
- (int)enableAudio:(BOOL)enable {
    return [_player enableAudio:enable];
}

/// 抓图操作
- (nullable NSData *)screenshoot {
    return [_player screenshoot];
}

/// 切换码流
/// @param quality 码流质量
- (BOOL)changeStream:(int)quality {
    QualityType type = QualityTypeSD;
    if (quality == 0) {
        type = QualityTypeHD;
    }
    return [_player changeStream:type];
}

/// 定位播放
/// @param seekTime 定位时间,格式为 yyyy-MM-dd'T'HH:mm:ss.SSS
- (int)seekPlayback:(NSString *)seekTime {
    return [_player seekPlayback:seekTime];
}

/// 暂停播放
- (int)pause {
    return [_player pause];
}

/// 恢复播放
- (int)resume {
    return [_player resume];
}

/// 获取回放倍速值
- (int)getPlaybackSpeed {
    return [_player getPlaybackSpeed];
}

/// 设置回放倍速s
/// 倍速值-8/-4/-2/1/2/4/8，负数为慢放，正数为快放
- (int)setPlaybackSpeed:(float)speed {
    return [_player setPlaybackSpeed:speed];
}

/// 开始录像
/// @param mediaFilePath 录像文件路径
- (int)startRecord:(NSString *)mediaFilePath {
    return [_player startRecord:mediaFilePath];
}

///开始录像同时转码(转码是指转码为系统播放器可以识别的标准 mp4封装）
///@param mediaFilePath 录像文件路径
- (int)startRecordAndConvert:(NSString *)mediaFilePath {
    return [_player startRecordAndConvert:mediaFilePath];
}

/// 停止录像
- (int)stopRecord {
    return [_player stopRecord];
}

/// 获取消耗的流量
- (long)getTotalTraffic {
    return [_player getTotalTraffic];
}

/// 获取系统播放时间
- (long)getOSDTime {
    return [_player getOSDTime];
}

/// 播放本地的录像文件
/// @param path 文件路径
- (void)playFile:(NSString *)path {
    [_player playFile:path];
}

/// 获取文件总播放时长
- (int)getTotalTime {
    return [_player getTotalTime];
}

/// 获取当前视频播放时间
- (int)getPlayedTime {
    return [_player getPlayedTime];
}

/// 设置当前进度值
/// @param scale 当前播放进度和总进度比  取值范围 0-1.0
- (int)setCurrentFrame:(float)scale {
    return [_player setCurrentFrame:scale];
}

/// 设置对讲参数
/// @param path 对讲url
/// @param headers 请求参数
- (void)setVoiceDataSource:(nullable NSString *)path headers:(nullable NSDictionary *)headers {
    [_player setVoiceDataSource:path headers:headers];
}

/// 开启对讲
- (void)startVoiceTalk {
    [_player startVoiceTalk];
}

/// 关闭对讲
- (void)stopVoiceTalk {
    [_player stopVoiceTalk];
}

/// 设置多线程解码线程数（硬解不支持设置解码线程）
/// @param threadNum 线程数（1~8）
- (BOOL)setDecodeThreadNum:(int)threadNum {
    return [_player setDecodeThreadNum:threadNum];
}

/// 获取当前码流帧率
- (int)getFrameRate {
    return [_player getFrameRate];
}

/// 设置期望帧率（硬解不支持）
/// @param frameRate 帧率范围(1~码流最大帧率)，播放成功后可以通过getFrameRate获取当前码流最大帧率
- (BOOL)setExpectedFrameRate:(int)frameRate {
    return [_player setExpectedFrameRate:frameRate];
}

// 释放播放器和纹理
- (void)disposePlayer {
    self.glRender = nil;
    self.player = nil;
}

#pragma mark -HatomPlayerDelegate-

/// 语音对讲状态回调方法
/// @param status 播放状态
/// @param errorCode 错误码，只有在 status 状态为： FAILED 、EXCEPTION 才有值 ,其他 status 值为 -1
- (void)onTalkStatus:(PlayStatus)status errorCode:(NSString *)errorCode {
    NSMutableDictionary *eventData = [NSMutableDictionary new];
    if (status == FAILED || status == EXCEPTION) {
        [eventData setValue:@"onTalkError" forKey:@"event"];
        [eventData setValue:errorCode forKey:@"error"];
    } else if (status == SUCCESS) {
        [eventData setValue:@"onTalkSuccess" forKey:@"event"];
    }
    [self.delegate player:self eventData:eventData];
}

- (void)setupFlutter:(void *)pCVBuffer subPort:(int)port player:(HatomPlayer *)player {
    if (self.delegate && [self.delegate respondsToSelector:@selector(registerTexture:player:)]) {
        _glRender = [[GLRender alloc] initWidthCVBufferRef:(CVPixelBufferRef)pCVBuffer];
        [self.delegate registerTexture:_glRender player: self];
    }
}

- (void)textureFrameAvailable:(int)textureId player:(HatomPlayer *)player {
    if (self.delegate && [self.delegate respondsToSelector:@selector(frameUpdate:)]) {
        [self.delegate frameUpdate:self.textureId];
    }
}

- (void)onPlayerStatusEx:(nonnull NSString *)playUrl status:(PlayStatus)status errorCode:(nonnull NSString *)errorCode { 
    NSMutableDictionary *eventData = [NSMutableDictionary new];
    [eventData setValue:@(_textureId) forKey:@"textureId"];
    if (status == SUCCESS) {
        [eventData setValue:@"onPlaySuccess" forKey:@"event"];
    }
    else {
        if (status == FINISH) {
            [eventData setValue:@"onPlayFinish" forKey:@"event"];
        } else {
            [eventData setValue:@"onPlayError" forKey:@"event"];
            [eventData setValue:errorCode forKey:@"error"];
        }
    }
    [self.delegate player:self eventData:eventData];
}

- (void)onPlayerStatus:(PlayStatus)status errorCode:(nonnull NSString *)errorCode { 
    
}




@end
