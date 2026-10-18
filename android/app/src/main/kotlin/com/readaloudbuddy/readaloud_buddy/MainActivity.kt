package com.readaloudbuddy.readaloud_buddy

import android.Manifest
import android.app.ActivityManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Debug
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var micResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Asks for the microphone (Vosk listens through it). Answers true
        // when the app may record audio. Audio never leaves the phone.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "readaloud/mic")
            .setMethodCallHandler { call, result ->
                if (call.method != "request") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                    checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
                    PackageManager.PERMISSION_GRANTED
                ) {
                    result.success(true)
                    return@setMethodCallHandler
                }
                // One question at a time: an earlier one that never got an
                // answer is answered "no".
                micResult?.success(false)
                micResult = result
                requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), MIC_REQUEST)
            }
        // How much memory the phone has and this app uses, so the app can
        // tell whether the big Filipino speech model fits (and measure it).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "readaloud/device")
            .setMethodCallHandler { call, result ->
                if (call.method == "freeSpaceMb") {
                    // Free space where the app keeps its files (the model goes there).
                    result.success(StatFs(filesDir.path).availableBytes / (1024 * 1024))
                    return@setMethodCallHandler
                }
                if (call.method != "memory") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val info = ActivityManager.MemoryInfo()
                am.getMemoryInfo(info)
                result.success(
                    mapOf(
                        "totalMb" to info.totalMem / (1024 * 1024),
                        "availMb" to info.availMem / (1024 * 1024),
                        "lowMemory" to info.lowMemory,
                        "appPssMb" to Debug.getPss() / 1024, // KB -> MB
                        "largeHeap" to am.largeMemoryClass,
                    )
                )
            }
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

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != MIC_REQUEST) return
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        micResult?.success(granted)
        micResult = null
    }

    companion object {
        private const val MIC_REQUEST = 4201
    }
}
