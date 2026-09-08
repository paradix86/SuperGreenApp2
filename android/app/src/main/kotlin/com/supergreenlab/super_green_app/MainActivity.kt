package com.supergreenlab.app2

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        // Dart only knows the zone abbreviation and offset; the IANA id is
        // needed to build the POSIX TZ string the controller expects.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "supergreenlab/timezone")
            .setMethodCallHandler { call, result ->
                if (call.method == "id") {
                    result.success(java.util.TimeZone.getDefault().id)
                } else {
                    result.notImplemented()
                }
            }
    }
}
