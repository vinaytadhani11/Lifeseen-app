package com.lifeseen.notifications

import android.app.Activity
import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import android.service.notification.NotificationListenerService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/**
 * Flutter bridge for Notification History + the two permissions.
 *
 * Register it once in MainActivity:
 *   override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
 *       super.configureFlutterEngine(flutterEngine)
 *       flutterEngine.plugins.add(com.lifeseen.notifications.LifeSeenNotificationsPlugin())
 *   }
 */
class LifeSeenNotificationsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler, ActivityAware {

    private lateinit var context: Context
    private var activity: Activity? = null
    private lateinit var channel: MethodChannel
    private lateinit var events: EventChannel
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    private val store get() = NotificationStore.get(context)
    private val listener get() = ComponentName(context, LifeSeenNotificationListener::class.java)

    private val socialPackages = setOf(
        "com.whatsapp", "com.whatsapp.w4b", "com.instagram.android", "org.telegram.messenger", "com.snapchat.android",
        "com.facebook.katana", "com.facebook.orca", "com.facebook.lite", "org.thoughtcrime.securesms", "com.discord",
        "com.twitter.android", "com.google.android.apps.messaging", "com.samsung.android.messaging", "com.linkedin.android",
        "com.viber.voip", "jp.naver.line.android", "com.skype.raider", "com.Slack", "com.microsoft.teams",
    )

    // ------------------------------------------------------------------ FlutterPlugin
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "lifeseen/notification_history")
        channel.setMethodCallHandler(this)
        events = EventChannel(binding.binaryMessenger, "lifeseen/notification_history/events")
        events.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        events.setStreamHandler(null)
        LifeSeenNotificationListener.eventSink = null
    }

    // ------------------------------------------------------------------ EventChannel
    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        LifeSeenNotificationListener.eventSink = { map -> sink.success(map) }
    }

    override fun onCancel(arguments: Any?) {
        LifeSeenNotificationListener.eventSink = null
    }

    // ------------------------------------------------------------------ ActivityAware
    override fun onAttachedToActivity(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivity() { activity = null }

    // ------------------------------------------------------------------ Methods
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isNotificationAccessGranted" -> result.success(notificationAccessGranted())
            "openNotificationAccessSettings" -> { openNotificationSettings(); result.success(null) }
            "isUsageAccessGranted" -> result.success(usageAccessGranted())
            "openUsageAccessSettings" -> { openUsageSettings(); result.success(null) }
            "shareText" -> { share(call.argument<String>("text").orEmpty()); result.success(null) }
            "setEnabledApps", "saveSettings" -> {
                // small writes – do them right away so the listener sees them immediately
                try { result.success(write(call)) } catch (e: Throwable) { result.error("NH_ERROR", e.message, null) }
            }
            "installedApps", "enabledApps", "appIcon", "getSettings", "stats", "items",
            "appDetail", "deleteThread", "clearAll", "storage" -> io.execute {
                try {
                    val r = read(call)
                    main.post { result.success(r) }
                } catch (e: Throwable) {
                    main.post { result.error("NH_ERROR", e.message, null) }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun write(call: MethodCall): Any? = when (call.method) {
        "setEnabledApps" -> {
            store.enabledApps = (call.argument<List<String>>("packages") ?: emptyList()).toSet()
            rebind()
            null
        }
        "saveSettings" -> {
            call.argument<Boolean>("paused")?.let { store.paused = it }
            call.argument<Boolean>("saveMedia")?.let { store.saveMedia = it }
            call.argument<Int>("retentionDays")?.let { if (it != store.retentionDays) store.retentionDays = it }
            null
        }
        else -> null
    }

    private fun read(call: MethodCall): Any? = when (call.method) {
        "installedApps" -> installedApps()
        "enabledApps" -> store.enabledApps.toList()
        "appIcon" -> call.argument<String>("package")?.let { iconFor(it) }
        "getSettings" -> mapOf("paused" to store.paused, "retentionDays" to store.retentionDays, "saveMedia" to store.saveMedia)
        "stats" -> store.stats()
        "items" -> store.query(
            call.argument<String>("package"),
            call.argument<String>("title"),
            call.argument<String>("search"),
            call.argument<Int>("limit") ?: 300,
        )
        "appDetail" -> store.appDetail(call.argument<String>("package").orEmpty())
        "deleteThread" -> {
            store.deleteThread(call.argument<String>("package").orEmpty(), call.argument<String>("title").orEmpty())
            LifeSeenNotificationListener.emit(mapOf("changed" to true)); null
        }
        "clearAll" -> { store.clearAll(); LifeSeenNotificationListener.emit(mapOf("changed" to true)); null }
        "storage" -> store.storage()
        else -> null
    }

    // ------------------------------------------------------------------ Permissions
    private fun notificationAccessGranted(): Boolean {
        val flat = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners") ?: return false
        val me = listener
        return flat.split(":").any { ComponentName.unflattenFromString(it) == me }
    }

    private fun usageAccessGranted(): Boolean {
        val ops = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ops.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        } else {
            @Suppress("DEPRECATION")
            ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun start(intent: Intent): Boolean = try {
        val a = activity
        if (a != null) a.startActivity(intent) else context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (_: Throwable) {
        false
    }

    private fun openNotificationSettings() {
        // Android 11+: open LifeSeen's own switch directly
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val direct = Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS)
                .putExtra(Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME, listener.flattenToString())
            if (start(direct)) return
        }
        start(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
    }

    private fun openUsageSettings() {
        val withPackage = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).setData(Uri.parse("package:${context.packageName}"))
        if (!start(withPackage)) start(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    }

    private fun rebind() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && notificationAccessGranted()) {
            try { NotificationListenerService.requestRebind(listener) } catch (_: Throwable) {}
        }
    }

    private fun share(text: String) {
        val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
        start(Intent.createChooser(send, "Share").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    // ------------------------------------------------------------------ Apps & icons
    private fun installedApps(): List<Map<String, Any?>> {
        val pm = context.packageManager
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        @Suppress("DEPRECATION")
        val infos = pm.queryIntentActivities(launcher, 0)
        val enabled = store.enabledApps
        val today = store.todayCounts()
        val seen = HashSet<String>()
        val out = ArrayList<Map<String, Any?>>()
        for (ri in infos) {
            val ai = ri.activityInfo?.applicationInfo ?: continue
            val pkg = ai.packageName
            if (pkg == context.packageName || !seen.add(pkg)) continue
            val social = pkg in socialPackages ||
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && ai.category == ApplicationInfo.CATEGORY_SOCIAL)
            out.add(
                mapOf(
                    "package" to pkg,
                    "name" to ri.loadLabel(pm).toString(),
                    "icon" to toPng(ri.loadIcon(pm)),
                    "enabled" to enabled.contains(pkg),
                    "social" to social,
                    "todayCount" to (today[pkg] ?: 0),
                )
            )
        }
        return out
    }

    private fun iconFor(pkg: String): ByteArray? = try {
        toPng(context.packageManager.getApplicationIcon(pkg))
    } catch (_: PackageManager.NameNotFoundException) {
        null
    }

    private fun toPng(d: Drawable?, size: Int = 96): ByteArray? {
        if (d == null) return null
        return try {
            val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val c = Canvas(bmp)
            d.setBounds(0, 0, size, size)
            d.draw(c)
            ByteArrayOutputStream().use { out ->
                bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
                bmp.recycle()
                out.toByteArray()
            }
        } catch (_: Throwable) {
            null
        }
    }
}
