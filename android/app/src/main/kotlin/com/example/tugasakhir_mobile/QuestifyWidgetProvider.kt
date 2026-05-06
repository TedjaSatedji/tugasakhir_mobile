package com.example.tugasakhir_mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class QuestifyWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    widgetData: SharedPreferences
  ) {
    val balance = widgetData.getString("balance", "Rp0")
    val income = widgetData.getString("income", "Rp0")
    val expense = widgetData.getString("expense", "Rp0")

    for (widgetId in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.questify_home_widget)
      views.setTextViewText(R.id.widget_balance, balance)
      views.setTextViewText(R.id.widget_income, income)
      views.setTextViewText(R.id.widget_expense, expense)
      val launchIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
      views.setOnClickPendingIntent(R.id.widget_root, launchIntent)
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
