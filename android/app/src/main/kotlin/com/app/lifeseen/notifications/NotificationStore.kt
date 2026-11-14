package com.app.lifeseen.notifications

import android.content.ContentValues
import android.content.Context
import android.content.SharedPreferences
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import java.util.Calendar

/**
 * Local store for saved notifications (SQLite) + history settings (SharedPreferences).
 * Everything stays on the phone.
 */
class NotificationStore private constructor(context: Context) :
    SQLiteOpenHelper(context.applicationContext, DB_NAME, null, 1) {

    companion object {
        const val DB_NAME = "lifeseen_notifications.db"
        private const val PREFS = "lifeseen_notification_history"
        private const val DAY = 24L * 60 * 60 * 1000

        @Volatile private var instance: NotificationStore? = null

        fun get(context: Context): NotificationStore =
            instance ?: synchronized(this) { instance ?: NotificationStore(context).also { instance = it } }
    }

    private val appContext = context.applicationContext
    private val prefs: SharedPreferences = appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            "CREATE TABLE n (id INTEGER PRIMARY KEY AUTOINCREMENT, pkg TEXT NOT NULL, app TEXT, " +
                "title TEXT NOT NULL DEFAULT '', body TEXT NOT NULL DEFAULT '', time INTEGER NOT NULL, " +
                "removed INTEGER NOT NULL DEFAULT 0)"
        )
        db.execSQL("CREATE INDEX n_time ON n(time)")
        db.execSQL("CREATE INDEX n_pkg_title ON n(pkg, title, time)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {}

    // ------------------------------------------------------------------ settings
    var enabledApps: Set<String>
        get() = prefs.getStringSet("enabled", emptySet())?.toSet() ?: emptySet()
        set(value) = prefs.edit().putStringSet("enabled", HashSet(value)).apply()

    var paused: Boolean
        get() = prefs.getBoolean("paused", false)
        // commit() so the notification listener sees the flag immediately
        set(value) {
            prefs.edit().putBoolean("paused", value).commit()
        }

    /** 7, 30 or 0 (= keep forever). */
    var retentionDays: Int
        get() = prefs.getInt("retentionDays", 30)
        set(value) {
            prefs.edit().putInt("retentionDays", value).putLong("lastCleanup", 0).apply()
            cleanup(force = true)
        }

    var saveMedia: Boolean
        get() = prefs.getBoolean("saveMedia", true)
        set(value) = prefs.edit().putBoolean("saveMedia", value).apply()

    // ------------------------------------------------------------------ writes
    /**
     * Saves one notification. Returns the saved row, or null when it was a duplicate.
     * [exactTime] = the time came from a MessagingStyle message (dedupe on it exactly).
     */
    @Synchronized
    fun insert(pkg: String, app: String, title: String, body: String, time: Long, exactTime: Boolean): Map<String, Any?>? {
        val db = writableDatabase
        val dupSql = if (exactTime)
            "SELECT id FROM n WHERE pkg=? AND title=? AND body=? AND time=? LIMIT 1"
        else
            "SELECT id FROM n WHERE pkg=? AND title=? AND body=? AND time>? LIMIT 1"
        val dupArg = if (exactTime) time.toString() else (time - 10 * 60 * 1000).toString()
        db.rawQuery(dupSql, arrayOf(pkg, title, body, dupArg)).use { if (it.moveToFirst()) return null }

        val values = ContentValues().apply {
            put("pkg", pkg); put("app", app); put("title", title); put("body", body); put("time", time)
        }
        val id = db.insert("n", null, values)
        if (id < 0) return null
        cleanup(force = false)
        return mapOf("id" to id, "pkg" to pkg, "app" to app, "title" to title, "body" to body, "time" to time, "removed" to false)
    }

    /** "This message was deleted" → mark the newest saved message in that chat as removed. */
    @Synchronized
    fun markLatestRemoved(pkg: String, title: String): Boolean {
        val db = writableDatabase
        db.execSQL(
            "UPDATE n SET removed=1 WHERE id=(SELECT id FROM n WHERE pkg=? AND title=? AND removed=0 ORDER BY time DESC LIMIT 1)",
            arrayOf<Any>(pkg, title)
        )
        return true
    }

    private fun cleanup(force: Boolean) {
        val days = retentionDays
        if (days <= 0) return
        val now = System.currentTimeMillis()
        if (!force && now - prefs.getLong("lastCleanup", 0) < 60 * 60 * 1000) return
        writableDatabase.delete("n", "time<?", arrayOf((now - days * DAY).toString()))
        prefs.edit().putLong("lastCleanup", now).apply()
    }

    fun deleteThread(pkg: String, title: String) {
        writableDatabase.delete("n", "pkg=? AND title=?", arrayOf(pkg, title))
    }

    fun clearAll() {
        writableDatabase.delete("n", null, null)
        writableDatabase.execSQL("VACUUM")
    }

    // ------------------------------------------------------------------ reads
    private fun startOfDay(daysAgo: Int): Long = Calendar.getInstance().apply {
        add(Calendar.DAY_OF_YEAR, -daysAgo)
        set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
    }.timeInMillis

    private fun count(where: String, vararg args: String): Int =
        readableDatabase.rawQuery("SELECT COUNT(*) FROM n WHERE $where", args).use { if (it.moveToFirst()) it.getInt(0) else 0 }

    fun todayCounts(): Map<String, Int> {
        val out = HashMap<String, Int>()
        readableDatabase.rawQuery("SELECT pkg, COUNT(*) FROM n WHERE time>=? GROUP BY pkg", arrayOf(startOfDay(0).toString())).use {
            while (it.moveToNext()) out[it.getString(0)] = it.getInt(1)
        }
        return out
    }

    fun stats(): Map<String, Any?> {
        val today = startOfDay(0)
        val last7 = (6 downTo 0).map { d ->
            count("time>=? AND time<?", startOfDay(d).toString(), startOfDay(d - 1).toString())
        }
        val perApp = ArrayList<Map<String, Any?>>()
        readableDatabase.rawQuery(
            "SELECT pkg, MAX(app), COUNT(*) c FROM n WHERE time>=? GROUP BY pkg ORDER BY c DESC",
            arrayOf(today.toString())
        ).use { while (it.moveToNext()) perApp.add(mapOf("pkg" to it.getString(0), "app" to it.getString(1), "count" to it.getInt(2))) }
        return mapOf(
            "today" to count("time>=?", today.toString()),
            "week" to count("time>=?", startOfDay(6).toString()),
            "appsOn" to enabledApps.size,
            "last7" to last7,
            "perApp" to perApp,
        )
    }

    fun query(pkg: String?, title: String?, search: String?, limit: Int): List<Map<String, Any?>> {
        val where = ArrayList<String>()
        val args = ArrayList<String>()
        if (pkg != null) { where.add("pkg=?"); args.add(pkg) }
        if (title != null) { where.add("title=?"); args.add(title) }
        if (!search.isNullOrBlank()) {
            where.add("(title LIKE ? OR body LIKE ? OR app LIKE ?)")
            val q = "%${search.trim()}%"; args.add(q); args.add(q); args.add(q)
        }
        val sql = "SELECT id, pkg, app, title, body, time, removed FROM n" +
            (if (where.isEmpty()) "" else " WHERE " + where.joinToString(" AND ")) +
            " ORDER BY time DESC LIMIT $limit"
        val out = ArrayList<Map<String, Any?>>()
        readableDatabase.rawQuery(sql, args.toTypedArray()).use {
            while (it.moveToNext()) out.add(
                mapOf(
                    "id" to it.getLong(0), "pkg" to it.getString(1), "app" to it.getString(2), "title" to it.getString(3),
                    "body" to it.getString(4), "time" to it.getLong(5), "removed" to (it.getInt(6) == 1),
                )
            )
        }
        return out
    }

    fun appDetail(pkg: String): Map<String, Any?> {
        val today = startOfDay(0)
        val hourly = IntArray(24)
        readableDatabase.rawQuery(
            "SELECT CAST(strftime('%H', time/1000, 'unixepoch', 'localtime') AS INTEGER) h, COUNT(*) FROM n WHERE pkg=? AND time>=? GROUP BY h",
            arrayOf(pkg, today.toString())
        ).use { while (it.moveToNext()) { val h = it.getInt(0); if (h in 0..23) hourly[h] = it.getInt(1) } }

        val threads = ArrayList<Map<String, Any?>>()
        readableDatabase.rawQuery(
            "SELECT n.title, n.body, n.time, t.c, t.r FROM n JOIN " +
                "(SELECT title, MAX(time) mt, COUNT(*) c, SUM(removed) r FROM n WHERE pkg=? GROUP BY title) t " +
                "ON n.title=t.title AND n.time=t.mt WHERE n.pkg=? GROUP BY n.title ORDER BY n.time DESC",
            arrayOf(pkg, pkg)
        ).use {
            while (it.moveToNext()) threads.add(
                mapOf("title" to it.getString(0), "body" to it.getString(1), "time" to it.getLong(2), "count" to it.getInt(3), "removed" to it.getInt(4))
            )
        }
        return mapOf(
            "hourly" to hourly.toList(),
            "threads" to threads,
            "today" to count("pkg=? AND time>=?", pkg, today.toString()),
            "total" to count("pkg=?", pkg),
        )
    }

    fun storage(): Map<String, Any?> {
        val oldest = readableDatabase.rawQuery("SELECT MIN(time) FROM n", null).use {
            if (it.moveToFirst() && !it.isNull(0)) it.getLong(0) else null
        }
        return mapOf(
            "count" to count("1=1"),
            "bytes" to appContext.getDatabasePath(DB_NAME).length(),
            "oldest" to oldest,
        )
    }
}
