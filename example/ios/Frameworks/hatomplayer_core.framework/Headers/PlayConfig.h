//
//  PlayConfig.h
//  hatom-player-core
//
//  Created by chenmengyi on 2020/11/3.
//

#import <hatomplayer_core/Constrants.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// player需要的参数
@interface PlayConfig : NSObject

/// 取流方式 0-hpsclient 1-设备直连 2-npclient, 默认hpsclient取流
@property(nonatomic, assign) int fetchStreamType;

/// 是否开启硬解码 true-开启 false-关闭
@property(nonatomic, assign) BOOL hardDecode;

/// 是否显示智能信息 true-显示 false-不显示
@property(nonatomic, assign) BOOL privateData;

/// 取流超时时间，默认20s
@property(nonatomic, assign) int timeout;

/// 码流解密key，如果是萤石设备，就是验证码
@property(nonatomic, copy) NSString *secretKey;

/// 水印信息
@property(nonatomic, strong) NSArray<NSString*> *waterConfigs;

/// 流缓冲区大小，默认为5M   格式：5*1024*1024
@property(nonatomic, assign) int bufferLength;

/// 设备ip
@property (nonatomic, copy)   NSString *ip;

/// 设备端口号
@property (nonatomic, assign) int      port;

/// 设备用户名
@property (nonatomic, copy) NSString   *username;

/// 设备密码
@property (nonatomic, copy) NSString   *password;

/// 播放通道号
@property (nonatomic, assign) int  channelNum;

/// 清晰度 0-主码流 1-子码流
@property (nonatomic, assign) int qualityType;

/// 萤石设备序列号
@property(nonatomic, copy) NSString *deviceSerial;

/// 播放画面宽度
@property(nonatomic, assign) int width;

/// 播放画面高度
@property(nonatomic, assign) int height;


@end

NS_ASSUME_NONNULL_END
