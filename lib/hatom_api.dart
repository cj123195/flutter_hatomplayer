import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

const String ARTEMIS_PATH = '/artemis';

///预览url地址
const String previewURLsV1 = '$ARTEMIS_PATH/api/video/v1/cameras/previewURLs';

///预览url地址,isc平台1.4以上版本
const String previewURLsV2 = '$ARTEMIS_PATH/api/video/v2/cameras/previewURLs';

///回放url地址
const String playbackURLsV1 = '$ARTEMIS_PATH/api/video/v1/cameras/playbackURLs';

///回放url地址,isc平台1.4以上版本
const String playbackURLsV2 = '$ARTEMIS_PATH/api/video/v2/cameras/playbackURLs';

///云台控制
const String controllingV1 = '$ARTEMIS_PATH/api/video/v1/ptzs/controlling';

///语音对讲url
const String talkURLsV1 = '$ARTEMIS_PATH/api/video/v1/cameras/talkURLs';

///语音对讲url地址,isc平台1.4以上版本
const String talkURLsV2 = '$ARTEMIS_PATH/api/video/v2/cameras/talkURLs';

/// 3D放大url地址
const String selZoomV1 = '$ARTEMIS_PATH/api/video/v1/ptzs/selZoom';

/// 云台控制行为
enum PtzAction {
  start, // 开始
  stop, // 结束
}

/// 云台控制命令
enum PtzCommand {
  LEFT, // 左转
  RIGHT, // 右转
  UP, // 上转
  DOWN, // 下转
  ZOOM_IN, // 焦距放大
  ZOOM_OUT, // 焦距缩小
  LEFT_UP, // 左上
  LEFT_DOWN, // 左下
  RIGHT_UP, // 左转
  RIGHT_DOWN, // 右转
  FOCUS_NEAR, // 焦点前移
  FOCUS_FAR, // 焦点后移
  IRIS_ENLARGE, // 光圈扩大
  IRIS_REDUCE, // 光圈缩小
  GOTO_PRESET, // 到预置点
}

///isc平台网络请求辅助类
class HatomApi {
  static String? host;
  static String? appKey;
  static String? appSecret;

  ///根据路径生成认证header
  ///
  ///海康isc平台采用AK/SK认证,需要生成生成必要的秘钥放到header中
  ///
  /// 'url' 接口请求地址 比如[getPreviewURL],[ptzControl]..等
  ///
  static Map<String, dynamic> createHeaders(String url) {
    assert(host != null);
    assert(appKey != null);
    assert(appSecret != null);

    const httpHeaders = 'POST\n*/*\napplication/json\n';
    final customHeaders = 'x-ca-key:$appKey\n';
    final msg = httpHeaders + customHeaders + url;
    final secretBytes = utf8.encode(appSecret!);
    final messageBytes = utf8.encode(msg);
    final digest = Hmac(sha256, secretBytes).convert(messageBytes);
    final signature = base64Encode(digest.bytes);

    final Map<String, dynamic> headers = {};
    headers['Accept'] = '*/*';
    headers['Content-Type'] = 'application/json';
    headers['X-Ca-Key'] = appKey;
    headers['X-Ca-Signature'] = signature;
    headers['X-Ca-Signature-Headers'] = 'x-ca-key';
    return headers;
  }

  ///获取预览地址
  ///
  /// 'cameraIndexCode' 监控点唯一标识
  ///
  /// 'streamType' 码流类型,0主码流,1子码流
  ///
  /// version 1表示isc1.3版本及以前,2表示isc1.4版本及以后
  ///
  /// transmode 协议类型( 0-udp，1-tcp),默认为tcp，在protocol设置为rtsp或者rtmp时有效
  ///
  /// isHttps 是否使用https请求,需要根据实际情况选择参数,
  ///
  /// protocol 取流协议（应用层协议），
  /// “hik”:HIK私有协议，使用视频SDK进行播放时，传入此类型；
  /// “rtsp”:RTSP协议；
  /// “rtmp”:RTMP协议；
  /// “hls”:HLS协议（HLS协议只支持海康SDK协议、EHOME协议、ONVIF协议接入的设备；只支持H264视频编码和AAC音频编码）。
  /// 参数不填，默认为HIK协议
  ///
  /// isHttps是否为https请求
  static Future<dynamic> getPreviewURL({
    required String cameraIndexCode,
    int streamType = 1,
    int transmode = 1,
    String protocol = '',
    int version = 2,
    bool isHttps = true,
  }) async {
    if (cameraIndexCode.isEmpty) {
      return;
    }
    //根据版本切换地址,isc1.4之后用v2版本
    var previewURLs = previewURLsV2;
    if (version == 1) {
      previewURLs = previewURLsV1;
    }
    final headers = createHeaders(previewURLs);

    ///根据实际服务器情况选用http或https
    String url = 'http://$host$previewURLs';
    if (isHttps) {
      url = 'https://$host$previewURLs';
    }

    final Map body = {};
    body['cameraIndexCode'] = cameraIndexCode;
    body['streamType'] = streamType;
    body['transmode'] = transmode;
    if (protocol.isNotEmpty) {
      body['protocol'] = protocol;
    }

    final Dio dio = Dio();
    //增加日志
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

    // // 忽略SSL认证
    // (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
    //     (client) {
    //   client.badCertificateCallback =
    //       (X509Certificate cert, String host, int port) {
    //     return true;
    //   };
    // };
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return true;
      };
      return client;
    };
    dio.options.headers.addAll(headers);
    final Response response = await dio.post(url, data: body);
    return response.data;
  }

  /// 获取回放地址url
  ///
  /// cameraIndexCode：摄像头标识
  ///
  /// beginTime：开始时间(ISO8601格式：yyyy-MM-dd’T’HH:mm:ss.SSSXXX，例如北京时间：
  /// 2017-06-14T00:00:00.000+08:00)
  ///
  /// endTime：结束时间(ISO8601格式：yyyy-MM-dd’T’HH:mm:ss.SSSXXX，例如北京时间：
  /// 2017-06-15T00:00:00.000+08:00)
  ///
  /// recordLocation: 存储类型 0,中心存储  1,设备存储
  ///
  /// version：1是海康SDK1.3版本，默认是2海康SDK1.4版本
  ///
  /// isHttps是否为https请求
  static Future<dynamic> getPlaybackUrl({
    String? cameraIndexCode,
    String? beginTime,
    String? endTime,
    int recordLocation = 0,
    int version = 2,
    bool isHttps = true,
  }) async {
    if (cameraIndexCode == null || cameraIndexCode.isEmpty) {
      return;
    }

    ///根据版本切换地址,isc1.4之后用v2版本
    var playbackURLs = playbackURLsV2;
    if (version == 1) {
      playbackURLs = playbackURLsV1;
    }
    final headers = createHeaders(playbackURLs);

    ///根据实际服务器情况选用http或https

    String url = 'http://$host$playbackURLs';
    if (isHttps) {
      url = 'https://$host$playbackURLs';
    }

    final Map body = {};
    body['cameraIndexCode'] = cameraIndexCode;
    body['beginTime'] = beginTime;
    body['endTime'] = endTime;
    body['recordLocation'] = recordLocation;

    final Dio dio = Dio();
    dio.interceptors.add(LogInterceptor(requestBody: true));

    // 忽略SSL认证
    // (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
    //     (client) {
    //   client.badCertificateCallback =
    //       (X509Certificate cert, String host, int port) {
    //     return true;
    //   };
    // };
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return true;
      };
      return client;
    };
    dio.options.headers.addAll(headers);
    final Response response = await dio.post(url, data: body);
    return response.data;
  }

  /// 云台控制
  ///
  /// 'cameraIndexCode' 监控点唯一标识
  ///
  /// 'action' 行为:0开始,1停止
  ///
  /// 'command' 命令:不区分大小写
  ///
  /// 说明：
  ///
  /// LEFT 左转
  ///
  /// RIGHT右转
  ///
  /// UP 上转
  ///
  /// DOWN 下转
  ///
  /// ZOOM_IN 焦距变大
  ///
  /// ZOOM_OUT 焦距变小
  ///
  /// LEFT_UP 左上
  ///
  /// LEFT_DOWN 左下
  ///
  /// RIGHT_UP 右上
  ///
  /// RIGHT_DOWN 右下
  ///
  /// FOCUS_NEAR 焦点前移
  ///
  /// FOCUS_FAR 焦点后移
  ///
  /// IRIS_ENLARGE 光圈扩大
  ///
  /// IRIS_REDUCE 光圈缩小
  ///
  /// 以下命令presetIndex不可为空
  ///
  /// GOTO_PRESET到预置点
  ///
  /// isHttps是否为https请求
  static Future<dynamic> ptzControl(
    String cameraIndexCode,
    PtzAction action,
    PtzCommand command, {
    int? speed,
    bool isHttps = true,
  }) async {
    if (cameraIndexCode.isEmpty) {
      return;
    }
    final headers = createHeaders(controllingV1);

    ///根据实际服务器情况选用http或https
    String url = 'http://$host$controllingV1';
    if (isHttps) {
      url = 'https://$host$controllingV1';
    }

    final Map body = {
      'cameraIndexCode': cameraIndexCode,
      'action': action.index,
      'command': command.name,
      'speed': speed ?? 50,
    };

    final Dio dio = Dio();
    dio.interceptors.add(LogInterceptor(requestBody: true));

    // 忽略SSL认证
    // (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
    //     (client) {
    //   client.badCertificateCallback =
    //       (X509Certificate cert, String host, int port) {
    //     return true;
    //   };
    // };
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return true;
      };
      return client;
    };
    dio.options.headers.addAll(headers);
    final Response response = await dio.post(url, data: body);
    return response.data;
  }

  ///语音对讲,一般直接使用预览url即可,无需单独请求
  /// 'cameraIndexCode' 监控点唯一标识
  ///
  /// version 1表示isc1.3版本及以前,2表示isc1.4版本及以后
  ///
  /// transmode 协议类型( 0-udp，1-tcp),默认为tcp，
  ///
  /// isHttps 是否使用https请求,需要根据实际情况选择参数,
  ///
  /// isHttps是否为https请求
  static Future<dynamic> getTalkUrl({
    required String cameraIndexCode,
    int transmode = 1,
    int version = 2,
    bool isHttps = true,
  }) async {
    if (cameraIndexCode.isEmpty) {
      return;
    }

    ///根据版本切换地址,isc1.4之后用v2版本
    var talkURLs = talkURLsV2;
    if (version == 1) {
      talkURLs = talkURLsV1;
    }
    final headers = createHeaders(talkURLs);

    ///根据实际服务器情况选用http或https
    String url = 'http://$host$talkURLs';
    if (isHttps) {
      url = 'https://$host$talkURLs';
    }

    final Map body = {};
    body['cameraIndexCode'] = cameraIndexCode;
    body['transmode'] = transmode;

    final Dio dio = Dio();
    dio.interceptors.add(LogInterceptor(requestBody: true));

    // 忽略SSL认证
    // (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
    //     (client) {
    //   client.badCertificateCallback =
    //       (X509Certificate cert, String host, int port) {
    //     return true;
    //   };
    // };
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return true;
      };
      return client;
    };
    dio.options.headers.addAll(headers);
    final Response response = await dio.post(url, data: body);
    return response.data;
  }

  /// 3D放大
  ///
  /// [cameraIndexCode] 监控点唯一标识
  /// [start] 开始位置
  /// [end] 结束位置
  static Future<dynamic> selZoom({
    required String cameraIndexCode,
    required Offset start,
    required Offset end,
    bool isHttps = true,
  }) async {
    if (cameraIndexCode.isEmpty) {
      return;
    }
    final headers = createHeaders(selZoomV1);

    ///根据实际服务器情况选用http或https
    final String url = 'https://$host$selZoomV1';

    final Map body = {
      'cameraIndexCode': cameraIndexCode,
      'startX': start.dx,
      'startY': start.dy,
      'endX': end.dx,
      'endY': end.dy,
    };

    final Dio dio = Dio();
    dio.interceptors.add(LogInterceptor(requestBody: true));

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return true;
      };
      return client;
    };
    dio.options.headers.addAll(headers);
    final Response response = await dio.post(url, data: body);
    return response.data;
  }
}
