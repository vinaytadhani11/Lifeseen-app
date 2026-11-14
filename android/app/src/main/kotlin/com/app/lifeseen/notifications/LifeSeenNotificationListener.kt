package com.app.lifeseen.notifications

import android.app.Notification
import android.app.Person
import android.content.ComponentName
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Reads notifications from the apps the user switched on in "Choose Apps to Save"
 * and stores them with [NotificationStore]. Needs "Notification access" in Android settings.
 */
class LifeSeenNotificationListener : NotificationListenerService() {

    companion object {
        /** Set by the Flutter plugin while the app is open (live updates). */
        @Volatile var eventSink: ((Map<String, Any?>) -> Unit)? = null
        @Volatile var connected: Boolean = false

        private val main = Handler(Looper.getMainLooper())
        private val labels = HashMap<String, String>()

        private val DELETED = listOf(
            "this message was deleted", "you deleted this message", "message deleted",
            "deleted this message", "this message was removed",
        )
        private val MEDIA = Regex(
            "^(📷|🎥|🎤|🎵|📎|🖼|🎞)?\\s*(photo|video|audio|voice message|sticker|gif|document|image|📷 photo|🎥 video)\\s*$",
            RegexOption.IGNORE_CASE
        )

        fun emit(map: Map<String, Any?>) {
            val sink = eventSink ?: return
            main.post { try { sink(map) } catch (_: Throwable) {} }
        }
    }

    override fun onListenerConnected() {
        connected = true
    }

    override fun onListenerDisconnected() {
        connected = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try { requestRebind(ComponentName(this, LifeSeenNotificationListener::class.java)) } catch (_: Throwable) {}
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        try { handle(sbn) } catch (_: Throwable) { /* never crash the listener */ }
    }

    private fun handle(sbn: StatusBarNotification) {
        val store = NotificationStore.get(this)
        if (store.paused) return
        val pkg = sbn.packageName ?: return
        if (pkg == packageName) return
        if (!store.enabledApps.contains(pkg)) return

        val n = sbn.notification ?: return
        if (n.flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        if (n.flags and Notification.FLAG_ONGOING_EVENT != 0) return
        if (n.flags and Notification.FLAG_FOREGROUND_SERVICE != 0) return
        val extras = n.extras ?: return

        val app = label(pkg)
        val conversation = extras.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE)?.toString()?.trim()
        val title = (conversation ?: extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: app).trim()
            .replace(Regex("\\s*\\(\\d+ messages?\\)$"), "") // "Family (3 messages)" → "Family"

        // Chat apps (WhatsApp, Telegram…) put every message in EXTRA_MESSAGES.
        @Suppress("DEPRECATION")
        val messages = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
        if (messages != null && messages.isNotEmpty()) {
            for (p in messages) {
                val b = p as? Bundle ?: continue
                val text = b.getCharSequence("text")?.toString()?.trim().orEmpty()
                if (text.isEmpty()) continue
                val time = b.getLong("time", sbn.postTime)
                val sender = b.getCharSequence("sender")?.toString() ?: personName(b)
                val body = if (conversation != null && !sender.isNullOrBlank() && sender != title) "$sender: $text" else text
                save(store, pkg, app, title, body, text, time, exactTime = true)
            }
            return
        }

        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT) ?: extras.getCharSequence(Notification.EXTRA_TEXT))
            ?.toString()?.trim().orEmpty()
        if (text.isEmpty()) return
        save(store, pkg, app, title, text, text, sbn.postTime, exactTime = false)
    }

    private fun save(store: NotificationStore, pkg: String, app: String, title: String, body: String, rawText: String, time: Long, exactTime: Boolean) {
        val lower = rawText.lowercase()
        if (DELETED.any { lower.contains(it) }) {
            store.markLatestRemoved(pkg, title)
            emit(mapOf("changed" to true))
            return
        }
        if (!store.saveMedia && MEDIA.matches(rawText)) return
        val row = store.insert(pkg, app, title, body, time, exactTime) ?: return
        emit(row)
    }

    private fun personName(b: Bundle): String? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            @Suppress("DEPRECATION")
            (b.getParcelable<Person>("sender_person"))?.name?.toString()
        } else null

    private fun label(pkg: String): String = labels.getOrPut(pkg) {
        try {
            val pm = packageManager
            pm.getApplicationLabel(pm.getApplicationInfo(pkg, PackageManager.GET_META_DATA)).toString()
        } catch (_: Throwable) {
            pkg
        }
    }
}
