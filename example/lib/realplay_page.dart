import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_hatomplayer/flutter_hatomplayer.dart';
import 'package:flutter_hatomplayer/hatom_player_event.dart';
import 'package:flutter_hatomplayer/play_config.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// 实时预览界面
class RealplayPage extends StatefulWidget {
  const RealplayPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RealplayPageState();
}

class _RealplayPageState extends State<RealplayPage> {
  /// 预览url
  static const String playUrl =
      'rtsp://10.19.223.40:655/EUrl/vsig8IVfXVe3c47ae29f896426b8d9a7';

  // static const String playUrl =
  //     'rtsp://admin:Hik12345@10.196.75.182:21454/ch1/sub/av_stream';
  // static const String playUrl = 'ddd';

  /// 对讲url
  static const String voiceTalkUrl = 'rtsp://10.66.165.235:655/EUrl/IR570qY';

  /// 播放控制器
  FlutterHatomplayer? player;

  /// 播放参数配置
  PlayConfig playConfig = PlayConfig(hardDecode: true, privateData: false);

  /// 视频尺寸
  Size? videoSize;

  /// 错误码
  String? errorCode;

  /// 当前流速
  String? currentTraffic;

  /// 总流量
  int totalTraffic = 0;

  /// 流量定时器
  Timer? timer;

  /// 录像存储的位置
  String? recordFilePath;

  /// 预览url输入框控制器
  final TextEditingController playUrlController =
      TextEditingController(text: playUrl);

  /// 对讲url输入框控制器
  final TextEditingController voiceTalkController =
      TextEditingController(text: voiceTalkUrl);

  /// 码流帧率输入框控制器
  final TextEditingController frameRateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // 流量显示widget
    Widget _trafficWidget = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [Text(currentTraffic ?? '')],
    );
    // 播放前设置
    Widget _beforePlaySetWidget = Row(
      children: [
        Expanded(
          flex: 1,
          child: MaterialButton(
            padding: const EdgeInsets.only(left: 0),
            textTheme: ButtonTextTheme.primary,
            color: Colors.blue,
            onPressed: () {
              playConfig.hardDecode = true;
              EasyLoading.showToast('设置成功');
            },
            child: const Text('硬解码开'),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          flex: 1,
          child: MaterialButton(
            padding: const EdgeInsets.only(left: 0),
            textTheme: ButtonTextTheme.primary,
            color: Colors.blue,
            onPressed: () {
              playConfig.hardDecode = false;
              EasyLoading.showToast('设置成功');
            },
            child: const Text('硬解码关'),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          flex: 1,
          child: MaterialButton(
            padding: const EdgeInsets.only(left: 0),
            textTheme: ButtonTextTheme.primary,
            color: Colors.blue,
            onPressed: () {
              playConfig.privateData = true;
              EasyLoading.showToast('设置成功');
            },
            child: const Text('智能信息开'),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          flex: 1,
          child: MaterialButton(
            padding: const EdgeInsets.only(left: 0),
            textTheme: ButtonTextTheme.primary,
            color: Colors.blue,
            onPressed: () {
              playConfig.privateData = false;
              EasyLoading.showToast('设置成功');
            },
            child: const Text('智能信息关'),
          ),
        ),
      ],
    );
    // 预览/对讲
    Widget _previewAndTalkWidget = Row(
      children: [
        Expanded(
          flex: 1,
          child: MaterialButton(
            padding: const EdgeInsets.only(left: 0),
            textTheme: ButtonTextTheme.primary,
            color: Colors.blue,
            onPressed: () async {
              await initPlayer();
              await player?.start();
            },
            child: const Text('开始预览'),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          flex: 1,
          child: MaterialButton(
            padding: const EdgeInsets.only(left: 0),
            textTheme: ButtonTextTheme.primary,
            color: Colors.blue,
            onPressed: () async {
              await player?.stop();
              EasyLoading.showToast('停止成功');
              // 取消流量定时器
              timer?.cancel();
              videoSize = null;
              errorCode = null;
              setState(() {});
            },
            child: const Text('停止预览'),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          flex: 1,
          child: MaterialButton(
            padding: const EdgeInsets.only(left: 0),
            textTheme: ButtonTextTheme.primary,
            color: Colors.blue,
            onPressed: () async {
              if (await Permission.microphone.request().isGranted) {
                Map<String, dynamic>? headers = {'token': ''};
                if (player != null) {
                  await player?.setVoiceDataSource(voiceTalkController.text,
                      headers: headers);
                  await player?.startVoiceTalk();
                } else {
                  await initPlayer();
                  await player?.setVoiceDataSource(voiceTalkController.text,
                      headers: headers);
                  await player?.startVoiceTalk();
                }
              } else {
                EasyLoading.showToast('开启对讲失败，无录音或麦克风权限，请前往设置中开启');
              }
            },
            child: const Text('开启对讲'),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          flex: 1,
          child: MaterialButton(
            padding: const EdgeInsets.only(left: 0),
            textTheme: ButtonTextTheme.primary,
            color: Colors.blue,
            onPressed: () async {
              await player?.stopVoiceTalk();
              EasyLoading.showToast('对讲关闭成功');
            },
            child: const Text('关闭对讲'),
          ),
        ),
      ],
    );
    // 声音操作
    Widget _soundWidget = Row(
      children: [
        Expanded(
          flex: 1,
          child: MaterialButton(
            padding: const EdgeInsets.only(left: 0),
            textTheme: ButtonTextTheme.primary,
            color: Colors.blue,
            onPressed: () async {
              int? res = await player?.enableAudio(true);
              if (res == -1) {
                EasyLoading.showToast('声音开启失败');
              } else {
                EasyLoading.showToast('声音开启成功');
              }
            },
            child: const Text('声音开'),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          flex: 1,
          child: MaterialButton(
            padding: const EdgeInsets.only(left: 0),
            textTheme: ButtonTextTheme.primary,
            color: Colors.blue,
            onPressed: () async {
              int? res = await player?.enableAudio(false);
              if (res == -1) {
                EasyLoading.showToast('声音关闭失败');
              } else {
                EasyLoading.showToast('声音关闭成功');
              }
            },
            child: const Text('声音关'),
          ),
        ),
      ],
    );
    // 抓图/录像
    Widget _captureAndRecordWidget = Row(
      children: [
        Expanded(
          flex: 1,
          child: MaterialButton(
            padding: const EdgeInsets.only(left: 0),
            textTheme: ButtonTextTheme.primary,
            color: Colors.blue,
            onPressed: () async {
              Uint8List? imageBytes = await player?.screenshoot();
              // 抓图保存到本地相册
              if (imageBytes != null) {
                EasyLoading.showToast('抓图成功');
                await ImageGallerySaver.saveImage(imageBytes, quality: 100);
              }
            },
            child: const Text('抓图'),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          flex: 1,
          child: MaterialButton(
            padding: const EdgeInsets.only(left: 0),
            textTheme: ButtonTextTheme.primary,
            color: Colors.blue,
            onPressed: () async {
              if (await Permission.storage.request().isGranted) {
                Directory? appDocDir;
                if (Platform.isAndroid) {
                  appDocDir = await getExternalStorageDirectory();
                } else {
                  appDocDir = await getTemporaryDirectory();
                }
                recordFilePath = appDocDir!.path + "/temp.mp4";
                debugPrint('录像保存路径是：$recordFilePath');
                int? ret = await player?.startRecord(recordFilePath!);
                if (ret == 0) {
                  EasyLoading.showToast('开启录像成功');
                } else {
                  EasyLoading.showToast('开启录像失败');
                }
              } else {
                EasyLoading.showToast('开启录像失败，无存储权限，请前往设置中开启');
              }
            },
            child: const Text('开始录像'),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          flex: 1,
          child: MaterialButton(
            padding: const EdgeInsets.only(left: 0),
            textTheme: ButtonTextTheme.primary,
            color: Colors.blue,
            onPressed: () async {
              int? ret = await player?.stopRecord();
              if (ret == 0) {
                EasyLoading.showToast('关闭录像成功');
                await _showPlayFileDialog();
              } else {
                EasyLoading.showToast('关闭录像失败');
              }
            },
            child: const Text('关闭录像'),
          ),
        ),
      ],
    );
    return PopScope(
      onPopInvoked: onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('实时预览'),
        ),
        body: Stack(
          children: [
            Positioned(left: 0, right: 0, top: 0, child: _buildVideoWidget()),
            Positioned(
                left: 12,
                right: 12,
                top: MediaQuery.of(context).size.width * 9 / 16,
                height: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).size.width * 9 / 16 -
                    100,
                child: ListView(
                  children: [
                    // 播放流量
                    _trafficWidget,
                    const Text(
                      '预览url',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: playUrlController,
                      enableInteractiveSelection: false,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    const Text('对讲url',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: voiceTalkController,
                      enableInteractiveSelection: false,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Platform.isAndroid
                        ? const Text('播放前设置',
                            style: TextStyle(fontWeight: FontWeight.bold))
                        : const SizedBox(),
                    Platform.isAndroid
                        ? _beforePlaySetWidget
                        : const SizedBox(),
                    const SizedBox(
                      height: 8,
                    ),
                    const Text('预览/对讲',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    _previewAndTalkWidget,
                    const SizedBox(
                      height: 8,
                    ),
                    const Text('声音',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    _soundWidget,
                    const SizedBox(
                      height: 8,
                    ),
                    const Text('抓图/录像',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    _captureAndRecordWidget,
                    const SizedBox(
                      height: 8,
                    ),
                  ],
                ))
          ],
        ),
      ),
    );
  }

  /// 返回上一页
  Future<bool> onWillPop(bool pop) async {
    if (Navigator.canPop(context)) {
      // 停止播放
      await player?.stop();
      timer?.cancel();
      Navigator.pop(context);
    }
    return Future.value(false);
  }

  /// 视频播放widget
  Widget _buildVideoWidget() {
    if (errorCode != null) {
      return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width * 9 / 16,
        color: Colors.black87,
        child: Center(
          child: Text(
            '播放失败，$errorCode',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    /// 必须要等到视频尺寸回调才能去显示Texture
    if (videoSize != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: videoSize?.aspectRatio ?? 0,
          child: Texture(textureId: player?.textureId ?? -1),
        ),
      );
    }
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width * 9 / 16,
      color: Colors.black87,
    );
  }

  Future initPlayer() async {
    Map<String, dynamic> headers = {'token': ''};
    player = FlutterHatomplayer(
        playConfig: playConfig,
        urlPath: playUrlController.text,
        headers: headers,
        playEventCallBack: (event) async {
          debugPrint('===收到回调消息了:${event.event}');
          switch (event.event) {
            case EVENT_PLAY_SUCCESS:
              errorCode = null;
              videoSize = const Size(667, 375);
              EasyLoading.showToast('播放成功');
              timer = Timer.periodic(const Duration(seconds: 1), (t) async {
                await calculateTraffic();
              });
              break;
            case EVENT_PLAY_ERROR:
              errorCode = event.body ?? '';
              EasyLoading.showToast('播放失败');
              await player?.stop();
              // 取消定时器
              timer?.cancel();
              break;
            case EVENT_TALK_ERROR:
              EasyLoading.showToast('对讲失败，错误码：${event.body}');
              break;
            case EVENT_TALK_SUCCESS:
              EasyLoading.showToast('操作成功');
              break;
          }
          debugPrint('=========我在渲染了=======');
          setState(() {});
        });
    var result = await player?.initialize() ?? false;
    if (result) {
      debugPrint('=========初始化成功=======');
    } else {
      debugPrint('=========初始化失败=======');
    }
  }

  /// 计算当前流速/总流量
  Future calculateTraffic() async {
    int? nowLength = await player?.getTotalTraffic();
    if (nowLength != null) {
      int traffic = nowLength - totalTraffic;
      if (traffic >= 1024 * 1000) {
        // MB
        if (nowLength >= 1024 * 1024 * 1000) {
          // GB
          currentTraffic =
              '${(traffic / 1024 / 1024).toStringAsFixed(2)}MB/s ${(nowLength / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
        } else {
          currentTraffic =
              '${(traffic / 1024 / 1024).toStringAsFixed(2)}MB/s ${(nowLength / 1024 / 1024).toStringAsFixed(2)}MB';
        }
      } else {
        // KB
        if (nowLength >= 1024 * 1024 * 1000) {
          // GB
          currentTraffic =
              '${(traffic / 1024).toStringAsFixed(2)}KB/s ${(nowLength / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
        } else {
          currentTraffic =
              '${(traffic / 1024).toStringAsFixed(2)}KB/s ${(nowLength / 1024 / 1024).toStringAsFixed(2)}MB';
        }
      }
      totalTraffic = nowLength;
      setState(() {});
    }
  }

  /// 是否播放录像文件弹窗
  Future _showPlayFileDialog() async {
    await showDialog(
        context: context,
        builder: (c) => Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      color: Colors.white),
                  width: 300,
                  height: 150,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 18,
                      ),
                      const Text(
                        '是否前往播放录像文件？',
                        style: TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                              onPressed: () {
                                Navigator.of(c).pop();
                              },
                              child: const Text(
                                '取消',
                                style: TextStyle(color: Colors.red),
                              )),
                          const SizedBox(
                            width: 8,
                          ),
                          TextButton(
                              onPressed: () async {
                                // 关闭当前预览界面
                                await player?.stop();
                                timer?.cancel();
                                Navigator.of(c).pop();
                                Navigator.of(c).pushNamed("/playfile");
                              },
                              child: const Text(
                                '确定',
                                style: TextStyle(color: Colors.black87),
                              )),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ));
  }
}
