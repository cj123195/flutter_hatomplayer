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

import 'date_util.dart';

/// 录像回放界面
class PlaybackPage extends StatefulWidget {
  const PlaybackPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  /// 回放url
  static const String playUrl =
      'rtsp://10.66.165.106:655/EUrl/iB9RU3u/mark/c3RvcmFnZU9wdGltaXplPTEmbWVkaWFPcHRpbWl6ZT0x';

  /// 回放url输入框控制器
  final TextEditingController playUrlController =
      TextEditingController(text: playUrl);

  /// 播放控制器
  FlutterHatomplayer? player;

  /// 播放参数配置
  PlayConfig playConfig = PlayConfig(hardDecode: true, privateData: false);

  /// 视频尺寸
  Size? videoSize;

  /// 错误码
  String? errorCode;

  /// 进度条进度
  double progress = 0;

  /// 进度条进度刷新定时器
  Timer? timer;

  /// 是否在拖动进度条
  bool _isSeeking = false;

  @override
  Widget build(BuildContext context) {
    // 回放进度条
    Widget _progressWidget = Row(
      children: [
        Expanded(
            child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
              trackShape: const RectangularSliderTrackShape(),
              overlayColor: Colors.transparent,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 10,
              showValueIndicator: ShowValueIndicator.always,
              valueIndicatorColor: Colors.white,
              valueIndicatorTextStyle:
                  const TextStyle(color: Colors.black87, fontSize: 16)),
          child: Slider(
            value: progress,
            max: 1,
            label: sliderLabelText,
            onChanged: (value) {
              if (value < 0 || value > 1) {
                return;
              }
              progress = value;
              _isSeeking = true;
              setState(() {});
            },
            onChangeEnd: (value) async {
              if (value < 0 || value > 1) {
                return;
              }
              progress = value;
              await player?.seekPlayback(seekTime);
              _isSeeking = false;
            },
          ),
        ))
      ],
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
    // 回放控制
    Widget _playbackCtrlWidget = Row(
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
            child: const Text('开始回放'),
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
              timer?.cancel();
              videoSize = null;
              errorCode = null;
              setState(() {});
            },
            child: const Text('停止回放'),
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
              int? ret = await player?.pause();
              if (ret == -1) {
                EasyLoading.showToast('暂停失败');
              } else {
                EasyLoading.showToast('暂停成功');
              }
            },
            child: const Text('暂停'),
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
              int? ret = await player?.resume();
              if (ret == -1) {
                EasyLoading.showToast('恢复失败');
              } else {
                EasyLoading.showToast('恢复成功');
              }
            },
            child: const Text('恢复'),
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
                String savePath = appDocDir!.path + "/temp.mp4";
                debugPrint('录像保存路径是：$savePath');
                int? ret = await player?.startRecord(savePath);
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
    // 倍速
    Widget _speedWidget = Row(
      children: [
        Expanded(
          flex: 1,
          child: MaterialButton(
            padding: const EdgeInsets.only(left: 0),
            textTheme: ButtonTextTheme.primary,
            color: Colors.blue,
            onPressed: () async {
              int? ret = await player?.setPlaybackSpeed(1);
              if (ret == 0) {
                EasyLoading.showToast('倍速设置成功');
              } else {
                EasyLoading.showToast('倍速设置失败');
              }
            },
            child: const Text('1X'),
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
              int? ret = await player?.setPlaybackSpeed(2);
              if (ret == 0) {
                EasyLoading.showToast('倍速设置成功');
              } else {
                EasyLoading.showToast('倍速设置失败');
              }
            },
            child: const Text('2X'),
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
              int? ret = await player?.setPlaybackSpeed(4);
              if (ret == 0) {
                EasyLoading.showToast('倍速设置成功');
              } else {
                EasyLoading.showToast('倍速设置失败');
              }
            },
            child: const Text('4X'),
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
              int? ret = await player?.setPlaybackSpeed(8);
              if (ret == 0) {
                EasyLoading.showToast('倍速设置成功');
              } else {
                EasyLoading.showToast('倍速设置失败');
              }
            },
            child: const Text('8X'),
          ),
        ),
      ],
    );
    return PopScope(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('录像回放'),
          ),
          body: Stack(
            children: [
              Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Column(
                    children: [
                      // 播放widget
                      _buildVideoWidget(),
                      // 进度条
                      _progressWidget
                    ],
                  )),
              Positioned(
                  left: 12,
                  right: 12,
                  top: MediaQuery.of(context).size.width * 9 / 16 + 50,
                  height: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).size.width * 9 / 16 -
                      150,
                  child: ListView(
                    children: [
                      const Text(
                        '回放url',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: playUrlController,
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
                      const Text('录像回放',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      _playbackCtrlWidget,
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
                      const Text('倍速',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      _speedWidget,
                    ],
                  ))
            ],
          ),
        ),
        onPopInvoked: onWillPop);
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
    DateTime nowDate = DateTime.now();
    // 时间格式：2022-09-16T00:00:00.000+08:00
    DateTime startDate = DateTime(nowDate.year, nowDate.month, nowDate.day);
    DateTime endDate =
        DateTime(nowDate.year, nowDate.month, nowDate.day, 23, 59, 59);
    String startTime = '${startDate.toIso8601String()}+08:00';
    String endTime = '${endDate.toIso8601String()}+08:00';
    debugPrint('======startTime:$startTime, endTime:$endTime======');
    Map<String, dynamic> headers = {
      'token': '',
      'startTime': startTime,
      'endTime': endTime
    };
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
                // 获取当前播放的画面时间
                await _getOsdtime();
              });
              break;
            case EVENT_PLAY_ERROR:
              errorCode = event.body ?? '';
              EasyLoading.showToast('播放失败');
              await player?.stop();
              timer?.cancel();
              break;
            case EVENT_PLAY_FINISH:
              EasyLoading.showToast('播放结束');
              await player?.stop();
              timer?.cancel();
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

  Future _getOsdtime() async {
    if (_isSeeking) return;
    int osdTime = await player?.getOSDTime() ?? 0;
    if (osdTime > 0) {
      // 计算osdtime在进度条中的所占比例
      // 以今日零点的时间戳为基点
      DateTime now = DateTime.now();
      DateTime zeroDate = DateTime(now.year, now.month, now.day);
      double zeroTime = zeroDate.millisecondsSinceEpoch / 1000;
      int totalDayTime = 24 * 3600;
      var value = (osdTime - zeroTime) / totalDayTime;
      if (value < 0 || value > 1) {
        return;
      }
      progress = value;
      // debugPrint(
      //     '===========osdTime:$osdTime,zeroTime:$zeroTime,progress:$progress========');
      setState(() {});
    }
  }

  String get sliderLabelText {
    double time = progress * 24 * 3600 * 1000;
    // 以今日零点的时间戳为基点
    DateTime now = DateTime.now();
    DateTime zeroDate = DateTime(now.year, now.month, now.day);
    double curTimeMilliseconds = zeroDate.millisecondsSinceEpoch + time;
    DateTime curTime =
        DateTime.fromMillisecondsSinceEpoch(curTimeMilliseconds.toInt());
    return DateUtil.formatDate(curTime);
  }

  String get seekTime {
    double time = progress * 24 * 3600 * 1000;
    // 以今日零点的时间戳为基点
    DateTime now = DateTime.now();
    DateTime zeroDate = DateTime(now.year, now.month, now.day);
    double curTimeMilliseconds = zeroDate.millisecondsSinceEpoch + time;
    DateTime curTime =
        DateTime.fromMillisecondsSinceEpoch(curTimeMilliseconds.toInt());
    return '${curTime.toIso8601String()}+08:00';
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
                                Navigator.of(c).pop();
                                Navigator.of(c).pushNamed("/playfile");
                                // 关闭当前预览界面
                                await player?.stop();
                                timer?.cancel();
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
