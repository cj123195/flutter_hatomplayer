//
//  StreamClient.h
//  hatom-player-core
//
//  Created by chenmengyi on 2020/11/3.
//

#import <hatomplayer_core/PlayConfig.h>
#import <hatomplayer_core/Constrants.h>
#import <hatomplayer_core/AudioClient.h>
#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@protocol StreamClientDelegate <NSObject>

///头数据
/// @param data 数据
/// @param length 数据长度
/// @param type 流类型
- (void)headData:(void *)data length:(int)length type:(FetchStreamType)type;

/// body数据
/// @param data 数据
/// @param length 数据长度
/// @param type 流类型
- (void)bodyData:(void *)data length:(int)length type:(FetchStreamType)type;

/// 错误消息回调
/// @param type 类型
/// @param errorCode 错误码
- (void)onError:(FetchStreamType)type
        errCode:(int)errorCode
        errData:(NSString  * _Nullable )errData;

/// 回放结束
- (void)onPlaybackFinish;

/// 音频编码格式
/// @param encodeType 编码格式
- (void)audioEncodeType:(int)encodeType;

@end

@interface StreamClient : NSObject

@property(nonatomic, weak) id<StreamClientDelegate> delegate;
@property(nonatomic, copy) NSString *playUrl;
@property(nonatomic, strong) NSDictionary *playHeaders;
@property(nonatomic, copy) NSString *voiceTalkUrl;
@property(nonatomic, strong) NSDictionary *voiceTalkHeaders;

- (instancetype)init:(AudioClient *)audioClient;

/// 设置播放信息
/// @param playConfig 播放信息
- (void)setPlayConfig:(PlayConfig *)playConfig;

/// 取流日志开启
/// @param enable YES-开启 NO-关闭
- (void)logEnable:(BOOL)enable;

/// 设置播放参数
/// @param path 播放url
/// @param headers 请求参数
- (void)setDataSource:(nullable NSString *)path headers:(nullable NSDictionary *)headers;

/// 预览/回放
- (int)start;

/// 修改码流
- (int)changeStream:(QualityType)quality;

/// 回放录像条拖动
- (int)seekTime;

/// 设置对讲参数
/// @param path 对讲url
/// @param headers 请求参数
- (void)setVoiceDataSource:(nullable NSString *)path headers:(nullable NSDictionary *)headers;

/// 开启对讲
- (int)talk;

/// 停止对讲
- (int)stopTalk;

/// 继续预览/回放
- (int)resume;

/// 暂停预览/回放
- (int)pause;

/// 结束预览/回放
- (int)stop;

/// 取流类型
- (FetchStreamType)fetchStreamType;

/// 改变回放速率
/// @param scale 回放速率
- (int)changeRate:(float)scale;

/// 云台控制操作（需先启动预览）
/// @param action 云台停止动作或开始动作： 0- 开始， 1- 停止
/// @param command 云台控制命令
/// @param speed 云台控制的速度，用户按不同解码器的速度控制值设置。取值范围[1,7]
- (int)ptzControl:(PTZActionType)action command:(PTZCommandType)command speed:(int)speed;

/// 云台预置点操作（需先启动预览）
/// @param presentCmd 云台预置点操作命令
/// @param presetIndex 预置点的序号（从 1 开始），最多支持 255 个预置点
- (int)ptzPreset:(PTZCommandType)presentCmd presetIndex:(int)presetIndex;

/// 云台巡航操作，需先启动预览
/// @param cruiseCmd 操作云台巡航命令
/// @param index 巡航序号
- (int)ptzCruise:(PTZCommandType)cruiseCmd index:(int)index;

///  * 注意：NET_DVR_POINT_FRAME结构体中的坐标值与当前预览显示框的大小有关，现假设预览显示框为352*288，
///     * 我们规定原点为预览显示框左上角的顶点，前四个参数计算方法如下：
///     * xTop = 手指当前所选区域的起始点坐标的值*255/352；
///     * xBottom = 手指当前所选区域的结束点坐标的值*255/352；
///     * yTop = 手指当前所选区域的起始点坐标的值*255/288；
///     * yBottom = 手指当前所选区域的结束点坐标的值*255/288；
///     * 缩小条件：xTop减去xBottom的值大于2。放大条件：xBottom大于xTop。坐标值的计算需要在上层view中实现
///     * 执行云台3D放大操作
/// @param rect 坐标值
- (int)ptzSelZoom:(CGRect)rect;

/// 销毁
- (int)destory;
/**
 开启广播
 */
- (int)brodcast;

/// 关闭广播
- (int)stopBroadcast;

/**
 发送编码后的录音

 @param audioData 编码后的语音数据
 @param dataLength 编码后的语音数据长度
 */
- (int)sendAudioData:(char *)audioData dataLength:(int)dataLength;

@end

NS_ASSUME_NONNULL_END
