package com.raidodevelopment.arlsza

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.os.StatFs
import android.provider.Settings
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
                // Whether Android is allowed to throttle us in the background.
                // A walk with the screen off stops being counted the moment
                // the system decides the app is idle, and the player has no
                // way to know that happened (§3.3).
                "isBatteryOptimised" -> {
                    val power = getSystemService(POWER_SERVICE) as PowerManager
                    result.success(
                        !power.isIgnoringBatteryOptimizations(packageName),
                    )
                }

                // The list, not the dialog. The direct request needs a
                // permission Google restricts to apps whose core function
                // genuinely cannot work without it, and a rejected listing is
                // a worse outcome than one extra tap.
                "openBatterySettings" -> {
                    startActivity(
                        Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
                    )
                    result.success(null)
                }

                "openAppSettings" -> {
                    startActivity(
                        Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.fromParts("package", packageName, null),
                        ),
                    )
                    result.success(null)
                }

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

                // §13.1: the reading the home-screen widget draws. Stored
                // rather than handed over, because the widget is redrawn by
                // the launcher long after this process is gone — see
                // StatusWidget.kt.
                //
                // ⚠️ Nothing is interpreted here. Percentages, a pulse and a
                // line of already-translated text go in exactly as Dart sent
                // them; deciding anything on this side would be a second copy
                // of rules that are tested on the other.
                "widget.push" -> {
                    val prefs = getSharedPreferences(
                        StatusWidget.PREFS,
                        Context.MODE_PRIVATE,
                    )
                    prefs.edit().apply {
                        putInt("water", call.argument<Int>("water") ?: 0)
                        putInt("kcal", call.argument<Int>("kcal") ?: 0)
                        putInt("sleep", call.argument<Int>("sleep") ?: 0)
                        putInt("bpm", call.argument<Int>("bpm") ?: 0)
                        putString("waterLabel", call.argument<String>("waterLabel"))
                        putString("kcalLabel", call.argument<String>("kcalLabel"))
                        putString("sleepLabel", call.argument<String>("sleepLabel"))
                        putString("ailments", call.argument<String>("ailments"))
                        putString("ok", call.argument<String>("ok"))
                        putLong("at", call.argument<Long>("at") ?: 0L)
                        apply()
                    }

                    StatusWidget.refresh(applicationContext)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}
