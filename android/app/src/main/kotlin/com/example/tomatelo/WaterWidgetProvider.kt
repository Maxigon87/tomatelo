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

class WaterWidgetProvider : AppWidgetProvider() {

    private fun getCurrentDateString(): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        return sdf.format(Date())
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val currentDate = getCurrentDateString()
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val lastDate = prefs.getString("lastDate", "")
            var water = prefs.getInt("water", 0)
            val goal = prefs.getInt("goal", 8)

            // Reset visual si es un nuevo día
            if (lastDate != currentDate) {
                water = 0
            }

            val progressPercentage = if (goal > 0) {
                ((water.toFloat() / goal) * 100).toInt()
            } else 0

            val motivationalText = when {
                progressPercentage == 0 -> "Let's start! \uD83D\uDCA7" // 💧
                progressPercentage < 50 -> "Keep going! \uD83D\uDCA7" // 💧
                progressPercentage < 100 -> "Almost there! \uD83C\uDF0A" // 🌊
                else -> "Goal reached! \uD83C\uDF89" // 🎉
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
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == ACTION_ADD_WATER) {
            val currentDate = getCurrentDateString()
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val lastDate = prefs.getString("lastDate", "")

            val current = prefs.getInt("water", 0)

            val updated = if (lastDate != currentDate) {
                1 // Primer vaso del nuevo día
            } else {
                current + 1 // Siguiente vaso del mismo día
            }

            prefs.edit()
                .putInt("water", updated)
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
