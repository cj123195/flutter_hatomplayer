package com.hikvision.isms.flutter_hatomplayer_example

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
//import com.hikvision.netsdk.HCNetSDK

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        HCNetSDK.getInstance().NET_DVR_Init()
        GeneratedPluginRegistrant.registerWith(flutterEngine) // add this line
    }
}
