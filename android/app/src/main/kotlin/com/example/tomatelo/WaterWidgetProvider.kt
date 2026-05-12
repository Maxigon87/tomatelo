package com.example.tomatelo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetPlugin

class WaterWidgetProvider : AppWidgetProvider() {

    private fun getCurrentDateString(): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        return sdf.format(Date())
    }

    private fun getSafeInt(prefs: SharedPreferences, key: String, default: Int): Int {
        return when (val value = prefs.all[key]) {
            is Int -> value
            is Long -> value.toInt()
            is Float -> value.toInt()
            is Double -> value.toInt()
            is String -> value.toIntOrNull() ?: default
            else -> default
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val currentDate = getCurrentDateString()
        val prefs = HomeWidgetPlugin.getData(context)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            
            val lastDate = prefs.getString("lastDate", "")
            var water = getSafeInt(prefs, "water", 0)
            var goal = getSafeInt(prefs, "goal", 0)
            
            val flutterGoal = getSafeInt(flutterPrefs, "flutter.dailyGoal", 0)
            if (goal <= 0 && flutterGoal > 0) {
                goal = flutterGoal
            }
            if (goal <= 0) {
                goal = 8
            }

            val flutterWater = getSafeInt(flutterPrefs, "flutter.glassesToday", 0)
            if (flutterWater > water) {
                water = flutterWater
            }

            // Reset visual si es un nuevo día
            if (!lastDate.isNullOrEmpty() && lastDate != currentDate) {
                water = 0
            }

            val progressPercentage = if (goal > 0) {
                ((water.toFloat() / goal) * 100).toInt()
            } else 0

            val motivationalText = when {
                progressPercentage == 0 -> "¡Empecemos! \uD83D\uDCA7" // 💧
                progressPercentage < 50 -> "¡Sigue así! \uD83D\uDCA7" // 💧
                progressPercentage < 100 -> "¡Ya casi! \uD83C\uDF0A" // 🌊
                else -> "¡Meta cumplida! \uD83C\uDF89" // 🎉
            }

            views.setTextViewText(R.id.txt_progress, "$water / $goal")
            views.setTextViewText(R.id.txt_motivational, motivationalText)
            views.setProgressBar(R.id.progress_bar, 100, progressPercentage.coerceAtMost(100), false)

            val intent = Intent(context, WaterWidgetProvider::class.java).apply {
                action = ACTION_ADD_WATER
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            views.setOnClickPendingIntent(R.id.btn_add, pendingIntent)
            // Only the +1 button should add a glass; clear the root click action in case
            // an older widget instance still has a pending intent attached to the whole card.
            views.setOnClickPendingIntent(R.id.widget_root, null)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == ACTION_ADD_WATER) {
            val currentDate = getCurrentDateString()
            val prefs = HomeWidgetPlugin.getData(context)
            val lastDate = prefs.getString("lastDate", "")

            val current = getSafeInt(prefs, "water", 0)

            val updated = if (!lastDate.isNullOrEmpty() && lastDate != currentDate) {
                1 // Primer vaso del nuevo día
            } else {
                current + 1 // Siguiente vaso del mismo día
            }

            prefs.edit()
                .putLong("water", updated.toLong())
                .putString("lastDate", currentDate)
                .apply()

            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, WaterWidgetProvider::class.java))
            onUpdate(context, manager, ids)
        }
    }

    companion object {
        private const val ACTION_ADD_WATER = "com.example.tomatelo.ADD_WATER"
    }
}
