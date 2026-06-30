package com.example.budget_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** "This Week" widget: donut total + 7-day spend bars, rendered as a
 * single image by Flutter (see HomeWidgetService) and displayed here. */
class FinanceWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.finance_widget_layout).apply {
                // Built manually (not via HomeWidgetLaunchIntent.getActivity) because that
                // helper sets pendingIntentBackgroundActivityStartMode, which Android 15+
                // rejects when combined with FLAG_UPDATE_CURRENT, crashing onUpdate.
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.finance_widget_root, pendingIntent)

                val imagePath = widgetData.getString("weekly_spend_card", null)
                if (imagePath != null) {
                    val bitmap = BitmapFactory.decodeFile(imagePath)
                    if (bitmap != null) {
                        setImageViewBitmap(R.id.finance_widget_image, bitmap)
                        setViewVisibility(R.id.finance_widget_image, View.VISIBLE)
                        setViewVisibility(R.id.finance_widget_placeholder, View.GONE)
                    }
                } else {
                    setViewVisibility(R.id.finance_widget_image, View.GONE)
                    setViewVisibility(R.id.finance_widget_placeholder, View.VISIBLE)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
