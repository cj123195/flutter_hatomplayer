//
//  AudioClient.h
//  hatom-player-core
//
//  Created by chenmengyi on 2020/11/4.
//

#import <hatomplayer_core/Constrants.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AudioClientDelegate <NSObject>

/// 对讲数据回调
/// @param data 对讲数据
/// @param length 数据长度
- (void)onRecordData:(void *)data length:(int)length;

/// 对讲中的异常
/// @param code 错误码
- (void)onError:(int)code;

/// 对讲中采集的声音能量值
/// @param dbValue 手机采集端的音量能量值
- (void)onRecordDB:(float)dbValue;

@end

@interface AudioClient : NSObject

@property(nonatomic, weak) id<AudioClientDelegate> delegate;
// 设置模式 1-只播放 2-只采集 3-对讲
@property(nonatomic, assign) int caeMode;

/// 开启对讲
/// @param encodeType 音频编码格式
- (void)open:(int)encodeType;

/// 关闭对讲
- (void)stop;

/// 对讲数据处理
/// @param data 对讲数据
/// @param length 数据长度
- (int)handleVoiceStreamData:(void *)data length:(int)length;

/// 对讲消息处理
/// @param msgCode msg回调
- (int)handleVoiceStreamMsg:(int)msgCode;


@end

NS_ASSUME_NONNULL_END
