package com.readaloudbuddy.readaloud_buddy

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Why the app's previous run ended (Android 11+), so the app can tell
        // whether the offline recognizer (Vosk) crashed it last time.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "readaloud/app_exit")
            .setMethodCallHandler { call, result ->
                if (call.method != "lastExit") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
                    result.success(null)
                    return@setMethodCallHandler
                }
                try {
                    val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    val last = am.getHistoricalProcessExitReasons(packageName, 0, 1).firstOrNull()
                    result.success(
                        last?.let {
                            mapOf(
                                "reason" to it.reason, // 4 = crash, 5 = native crash
                                "description" to (it.description ?: ""),
                                "timestamp" to it.timestamp,
                            )
                        }
                    )
                } catch (e: Exception) {
                    result.success(null)
                }
            }
    }
}
