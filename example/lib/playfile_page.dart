import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_hatomplayer/flutter_hatomplayer.dart';
import 'package:flutter_hatomplayer/hatom_player_event.dart';
import 'package:flutter_hatomplayer/play_config.dart';
import 'package:path_provider/path_provider.dart';

/// 本地录像文件播放
class PlayFilePage extends StatefulWidget {
  const PlayFilePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PlayFilePageState();
}

class _PlayFilePageState extends State<PlayFilePage> {
  /// 播放控制器
  FlutterHatomplayer? player;

  /// 播放参数配置
  PlayConfig playConfig = PlayConfig();

  /// 视频尺寸
  Size? videoSize;

  /// 错误码
  String? errorCode;

  /// 进度条定时器
  Timer? timer;

  /// 录像文件总时间
  int? totalTime;

  /// 进度条进度
  double progress = 0;

  /// 是否在拖动进度条
  bool isSeeking = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initPlayer();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('录像文件'),
          ),
          body: Column(
            children: [
              _buildVideoWidget(),
              Row(
                children: [
                  Expanded(
                      child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                        trackShape: const RectangularSliderTrackShape(),
                        overlayColor: Colors.transparent,
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 0),
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 10),
                        trackHeight: 10,
                        showValueIndicator: ShowValueIndicator.always,
                        valueIndicatorColor: Colors.white,
                        valueIndicatorTextStyle: const TextStyle(
                            color: Colors.black87, fontSize: 16)),
                    child: Slider(
                      value: progress,
                      max: 1,
                      onChanged: (value) async {
                        if (value < 0 || value > 1) {
                          return;
                        }
                        progress = value;
                        isSeeking = true;
                        setState(() {});
                      },
                      onChangeEnd: (value) async {
                        if (value < 0 || value > 1) {
                          return;
                        }
                        // 定位到拖动的时间点
                        await player?.setCurrentFrame(value);
                        isSeeking = false;
                      },
                    ),
                  ))
                ],
              )
            ],
          ),
        ),
        onWillPop: onWillPop);
  }

  /// 返回上一页
  Future<bool> onWillPop() async {
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
    playConfig.privateData = false;
    playConfig.hardDecode = false;
    player = FlutterHatomplayer(
        playConfig: playConfig,
        urlPath: "ddd",
        headers: headers,
        playEventCallBack: (event) async {
          debugPrint('===收到回调消息了:${event.event}');
          switch (event.event) {
            case EVENT_PLAY_SUCCESS:
              errorCode = null;
              videoSize = Size(667, 375);
              EasyLoading.showToast('播放成功');
              // 获取录像文件总时间
              totalTime = await player?.getTotalTime();
              timer = Timer.periodic(const Duration(seconds: 1), (t) async {
                if (isSeeking) return;
                // 获取当前播放的时间
                int? playedTime = await player?.getPlayedTime();
                if (playedTime != null && totalTime != null) {
                  var value = playedTime / totalTime!;
                  if (value < 0 || value > 1) {
                    return;
                  }
                  progress = value;
                  debugPrint(
                      '=======totalTime: $totalTime, playedTime: $playedTime, progress:$progress======');
                  setState(() {});
                }
              });
              break;
            case EVENT_PLAY_ERROR:
              errorCode = event.body ?? '';
              EasyLoading.showToast('播放失败');
              await player?.stop();
              // 取消定时器
              timer?.cancel();
              break;
            case EVENT_PLAY_FINISH:
              EasyLoading.showToast('播放结束');
              progress = 1;
              // 取消定时器
              timer?.cancel();
              errorCode = null;
              videoSize = null;
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
    var appDocDir;
    if (Platform.isAndroid) {
      appDocDir = await getExternalStorageDirectory();
    } else {
      appDocDir = await getTemporaryDirectory();
    }
    var recordFilePath = appDocDir.path + "/temp.mp4";
    await player?.playFile(recordFilePath);
  }
}
