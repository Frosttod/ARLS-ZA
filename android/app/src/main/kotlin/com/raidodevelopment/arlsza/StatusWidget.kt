package com.raidodevelopment.arlsza

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.text.format.DateUtils
import android.widget.RemoteViews

/**
 * The 4×1 home-screen widget: three bars, a pulse and what is wrong.
 *
 * ⚠️ **It renders, it does not decide.** Every number and every word arrives
 * from Dart through [MainActivity]'s channel and is stored in preferences as
 * given — which ailments made the cut, in what order and in which language is
 * settled in `lib/game/home_status.dart`, where it can be tested. Duplicating
 * any of that here would be a second copy of the rules, drifting from the
 * first the day somebody rewords a string.
 *
 * The one thing this side does own is **age**. The widget outlives the app: it
 * is still on the home screen an hour after the process was killed, and the
 * only honest thing to do with a reading from an hour ago is to say so.
 */
class StatusWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray,
    ) {
        for (id in ids) {
            manager.updateAppWidget(id, render(context))
        }
    }

    companion object {
        const val PREFS = "arlsza.widget"

        /**
         * Past this, the reading is old enough that the widget says when it was
         * true rather than implying it still is.
         *
         * ⚠️ Ten minutes, the same figure as `kFreshFor` in
         * `lib/game/home_status.dart` — Dart has already dropped the live
         * facts (an enemy nearby) by the time this matters, so the two have to
         * agree or the widget would dim a line that still says "something is
         * nearby".
         */
        private const val FRESH_FOR_MS = 10 * 60 * 1000L

        /** Redraws every placed widget. Called after each push from Dart. */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, StatusWidget::class.java),
            )
            for (id in ids) {
                manager.updateAppWidget(id, render(context))
            }
        }

        private fun render(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.status_widget)

            val at = prefs.getLong("at", 0L)
            val known = at > 0L

            bar(views, R.id.widget_water_bar, R.id.widget_water_value,
                prefs.getInt("water", 0), known)
            bar(views, R.id.widget_kcal_bar, R.id.widget_kcal_value,
                prefs.getInt("kcal", 0), known)
            bar(views, R.id.widget_sleep_bar, R.id.widget_sleep_value,
                prefs.getInt("sleep", 0), known)

            views.setTextViewText(
                R.id.widget_water_label,
                prefs.getString("waterLabel", "") ?: "",
            )
            views.setTextViewText(
                R.id.widget_kcal_label,
                prefs.getString("kcalLabel", "") ?: "",
            )
            views.setTextViewText(
                R.id.widget_sleep_label,
                prefs.getString("sleepLabel", "") ?: "",
            )

            views.setTextViewText(
                R.id.widget_bpm,
                if (known) "${prefs.getInt("bpm", 0)}" else "—",
            )

            // Either the list of what is wrong, or the reassurance that
            // nothing is — Dart sends exactly one of the two filled in.
            val ailments = prefs.getString("ailments", "") ?: ""
            val ok = prefs.getString("ok", "") ?: ""
            views.setTextViewText(
                R.id.widget_ailments,
                if (ailments.isNotEmpty()) ailments else ok,
            )

            // §13.1: how old this is. Only once it is old enough to matter —
            // a timestamp on a live reading is noise on a widget this small.
            val age = System.currentTimeMillis() - at
            views.setTextViewText(
                R.id.widget_age,
                if (known && age > FRESH_FOR_MS) {
                    DateUtils.getRelativeTimeSpanString(
                        at,
                        System.currentTimeMillis(),
                        DateUtils.MINUTE_IN_MILLIS,
                    ).toString()
                } else {
                    ""
                },
            )

            // Tapping it opens the game. A widget about a body the player can
            // do something about should be one tap from doing it.
            val open = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
            if (open != null) {
                views.setOnClickPendingIntent(
                    R.id.widget_root,
                    PendingIntent.getActivity(
                        context,
                        0,
                        open,
                        PendingIntent.FLAG_IMMUTABLE,
                    ),
                )
            }

            return views
        }

        /**
         * One bar, and its percentage beside it.
         *
         * ⚠️ An unknown reading draws an empty bar and a dash rather than a
         * zero: "no character yet" and "no water left" must not look the same
         * on a home screen, because one of them is a reason to go drink.
         */
        private fun bar(
            views: RemoteViews,
            barId: Int,
            textId: Int,
            value: Int,
            known: Boolean,
        ) {
            views.setProgressBar(barId, 100, if (known) value else 0, false)
            views.setTextViewText(textId, if (known) "$value%" else "—")
        }
    }
}
