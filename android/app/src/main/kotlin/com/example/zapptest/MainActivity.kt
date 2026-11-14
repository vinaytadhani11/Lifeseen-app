package com.app.logsense

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.app.logsense/usage_stats")
            .setMethodCallHandler(UsageStatsBridge(this))
        flutterEngine.plugins.add(com.lifeseen.notifications.LifeSeenNotificationsPlugin())
    }
}
