import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_hatomplayer_example/main_page.dart';
import 'package:flutter_hatomplayer_example/playback_page.dart';
import 'package:flutter_hatomplayer_example/playfile_page.dart';
import 'package:flutter_hatomplayer_example/realplay_page.dart';

void main() {
  Future.delayed(
      const Duration(milliseconds: 500), () => runApp(const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: "/", // 默认加载的界面，这里为RootPage
      routes: {
        // 显式声明路由
        "/realplay": (context) => const RealplayPage(),
        "/playback": (context) => const PlaybackPage(),
        "/playfile": (context) => const PlayFilePage()
      },
      home: const MainPage(),
      builder: EasyLoading.init(builder: (context, widget) {
        return widget!;
      }),
    );
  }
}
