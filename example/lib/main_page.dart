import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('海康视频SDK'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MaterialButton(
              textTheme: ButtonTextTheme.primary,
              color: Colors.blue,
              onPressed: () {
                Navigator.of(context).pushNamed("/realplay");
              },
              child: const Text('实时预览'),
            ),
            MaterialButton(
              textTheme: ButtonTextTheme.primary,
              color: Colors.blue,
              onPressed: () {
                Navigator.of(context).pushNamed("/playback");
              },
              child: const Text('录像回放'),
            )
          ],
        ),
      ),
    );
  }
}
