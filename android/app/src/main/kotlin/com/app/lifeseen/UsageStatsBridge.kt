package com.app.lifeseen

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Process
import android.provider.Settings
import java.io.ByteArrayOutputStream
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class UsageStatsBridge(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermission" -> result.success(hasPermission())
            "openSettings" -> {
                context.startActivity(
                    Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
                result.success(null)
            }
            "queryToday" -> result.success(queryToday())
            "queryHourlyToday" -> result.success(queryHourlyToday())
            "appIcon" -> result.success(
                iconBytes(
                    call.argument<String>("package"),
                    call.argument<String>("name")
                )
            )
            else -> result.notImplemented()
        }
    }

    private fun hasPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= 29) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        } else {
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun queryToday(): List<Map<String, Any>> {
        if (!hasPermission()) return emptyList()
        val targets = trackedPackages()
        val usage = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val start = startOfDay()
        val now = System.currentTimeMillis()
        val stats = usage.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, now) ?: emptyList()
        val totals = mutableMapOf<String, Long>()
        for (stat in stats) {
            if (!targets.containsKey(stat.packageName)) continue
            val time = foregroundMillis(stat)
            if (time > 0L) totals[stat.packageName] = time
        }
        for ((pkg, time) in foregroundByPackage(start, now, targets.keys)) {
            val current = totals[pkg] ?: 0L
            if (time > current) totals[pkg] = time
        }
        val rows = totals
            .filter { it.value >= 10_000L }
            .map { (pkg, millis) ->
                val seconds = millis / 1000
                val hours = (seconds / 3600).toInt()
                val minutes = ((seconds % 3600) / 60).toInt()
                val secs = (seconds % 60).toInt()
                mapOf(
                    "name" to (targets[pkg] ?: pkg),
                    "package" to pkg,
                    "hours" to hours,
                    "minutes" to minutes,
                    "seconds" to secs
                )
            }
            .sortedByDescending { row ->
                val h = row["hours"] as Int
                val m = row["minutes"] as Int
                val s = row["seconds"] as Int
                h * 3600 + m * 60 + s
            }
        return rows
    }

    private fun queryHourlyToday(): List<Double> {
        if (!hasPermission()) return List(24) { 0.0 }
        val packages = trackedPackages().keys
        val usage = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val start = startOfDay()
        val end = System.currentTimeMillis()
        val hourly = LongArray(24)
        val events = usage.queryEvents(start, end)
        val event = UsageEvents.Event()
        var activePackage: String? = null
        var sessionStart = 0L
        val resumed = if (Build.VERSION.SDK_INT >= 29) {
            UsageEvents.Event.ACTIVITY_RESUMED
        } else {
            UsageEvents.Event.MOVE_TO_FOREGROUND
        }
        val paused = if (Build.VERSION.SDK_INT >= 29) {
            UsageEvents.Event.ACTIVITY_PAUSED
        } else {
            UsageEvents.Event.MOVE_TO_BACKGROUND
        }
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val type = event.eventType
            val isResume = type == resumed || type == UsageEvents.Event.MOVE_TO_FOREGROUND
            val isPause = type == paused || type == UsageEvents.Event.MOVE_TO_BACKGROUND
            if (isResume) {
                activePackage = event.packageName
                sessionStart = event.timeStamp
            } else if (isPause) {
                val pkg = activePackage
                if (pkg != null && packages.contains(pkg) && sessionStart > 0L) {
                    addSlice(sessionStart, event.timeStamp, hourly)
                }
                activePackage = null
                sessionStart = 0L
            }
        }
        if (activePackage != null && packages.contains(activePackage) && sessionStart > 0L) {
            addSlice(sessionStart, end, hourly)
        }
        return hourly.map { it / 60_000.0 }
    }

    private fun addSlice(startMs: Long, endMs: Long, hourly: LongArray) {
        if (endMs <= startMs) return
        var cursor = startMs
        while (cursor < endMs) {
            val cal = Calendar.getInstance().apply { timeInMillis = cursor }
            val hour = cal.get(Calendar.HOUR_OF_DAY)
            cal.add(Calendar.HOUR_OF_DAY, 1)
            cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            val sliceEnd = minOf(endMs, cal.timeInMillis)
            if (hour in 0..23) hourly[hour] += sliceEnd - cursor
            cursor = sliceEnd
        }
    }

    private fun iconBytes(packageName: String?, appName: String?): ByteArray? {
        val pm = context.packageManager
        val pkg = when {
            !packageName.isNullOrBlank() && isInstalled(pm, packageName) -> packageName
            !appName.isNullOrBlank() -> findPackageByLabel(pm, appName)
            else -> null
        } ?: return null
        val drawable = try {
            pm.getApplicationIcon(pkg)
        } catch (_: PackageManager.NameNotFoundException) {
            return null
        }
        val bitmap = drawableToBitmap(drawable)
        return ByteArrayOutputStream().use { stream ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        }
    }

    private fun isInstalled(pm: PackageManager, packageName: String): Boolean {
        return try {
            pm.getApplicationInfo(packageName, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun findPackageByLabel(pm: PackageManager, appName: String): String? {
        return pm.getInstalledApplications(0).firstOrNull { info ->
            pm.getApplicationLabel(info).toString().equals(appName, ignoreCase = true)
        }?.packageName
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        val existing = (drawable as? BitmapDrawable)?.bitmap
        if (existing != null) return existing
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    private fun foregroundMillis(stat: android.app.usage.UsageStats): Long {
        val foreground = stat.totalTimeInForeground
        if (Build.VERSION.SDK_INT >= 29) {
            return maxOf(foreground, stat.totalTimeVisible)
        }
        return foreground
    }

    private fun foregroundByPackage(start: Long, end: Long, packages: Set<String>): Map<String, Long> {
        val usage = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val totals = mutableMapOf<String, Long>()
        val events = usage.queryEvents(start, end)
        val event = UsageEvents.Event()
        var activePackage: String? = null
        var sessionStart = 0L
        val resumed = if (Build.VERSION.SDK_INT >= 29) {
            UsageEvents.Event.ACTIVITY_RESUMED
        } else {
            UsageEvents.Event.MOVE_TO_FOREGROUND
        }
        val paused = if (Build.VERSION.SDK_INT >= 29) {
            UsageEvents.Event.ACTIVITY_PAUSED
        } else {
            UsageEvents.Event.MOVE_TO_BACKGROUND
        }
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val type = event.eventType
            val isResume = type == resumed || type == UsageEvents.Event.MOVE_TO_FOREGROUND
            val isPause = type == paused || type == UsageEvents.Event.MOVE_TO_BACKGROUND
            if (isResume) {
                activePackage = event.packageName
                sessionStart = event.timeStamp
            } else if (isPause) {
                val pkg = activePackage
                if (pkg != null && packages.contains(pkg) && sessionStart > 0L && event.timeStamp > sessionStart) {
                    totals[pkg] = (totals[pkg] ?: 0L) + (event.timeStamp - sessionStart)
                }
                activePackage = null
                sessionStart = 0L
            }
        }
        val pkg = activePackage
        if (pkg != null && packages.contains(pkg) && sessionStart > 0L && end > sessionStart) {
            totals[pkg] = (totals[pkg] ?: 0L) + (end - sessionStart)
        }
        return totals
    }

    private fun startOfDay(): Long {
        return Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }

    private fun trackedPackages(): Map<String, String> {
        val pm = context.packageManager
        val installed = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        val byPackage = installed.associateBy { it.packageName }
        val result = linkedMapOf<String, String>()
        for (pkg in knownApps) {
            val info = byPackage[pkg] ?: continue
            result[pkg] = pm.getApplicationLabel(info).toString()
        }
        for (info in installed) {
            val pkg = info.packageName
            val isSystem = info.flags and ApplicationInfo.FLAG_SYSTEM != 0
            if (pkg.startsWith("com.") && !isSystem && !result.containsKey(pkg)) {
                result[pkg] = pm.getApplicationLabel(info).toString()
            }
        }
        return result
    }

    companion object {
        private val knownApps = listOf(
            "com.facebook.katana",
            "com.google.android.youtube",
            "com.whatsapp",
            "com.facebook.orca",
            "com.instagram.android",
            "com.google.android.googlequicksearchbox",
            "com.tencent.mm",
            "com.zhiliaoapp.musically",
            "org.telegram.messenger",
            "com.snapchat.android",
            "com.kuaishou.nebula",
            "com.ss.android.ugc.aweme",
            "com.tencent.mobileqq",
            "com.sina.weibo",
            "com.qzone",
            "com.reddit.frontpage",
            "com.pinterest",
            "com.twitter.android",
            "com.linkedin.android",
            "com.viber.voip",
            "com.discord",
            "jp.naver.line.android",
            "tv.twitch.android.app",
            "org.thoughtcrime.securesms",
            "com.baidu.tieba",
            "com.microsoft.teams",
            "com.google.android.apps.dynamite",
            "com.skype.raider",
            "us.zoom.videomeetings",
            "com.clubhouse.app",
            "com.Slack"
        )
    }
}
