package com.raidodevelopment.arlsza

import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Free space, for the map pack download of §16.6.
 *
 * Twenty lines rather than a dependency: a map pack is 50 to 200 MB and the
 * game refuses to start a download it cannot finish, so all it needs is one
 * number. `StatFs` on the directory the file will actually be written to,
 * because internal storage, adopted storage and the SD card do not share a
 * budget.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.raidodevelopment.arlsza/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "freeBytes" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("no-path", "path is required", null)
                    } else {
                        try {
                            val stat = StatFs(path)
                            result.success(stat.availableBytes)
                        } catch (error: IllegalArgumentException) {
                            // A path that does not exist yet, or one on a
                            // volume that has been unmounted since the caller
                            // looked. Reporting the failure is better than
                            // guessing a number the download will be judged
                            // against.
                            result.error("unavailable", error.message, null)
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
