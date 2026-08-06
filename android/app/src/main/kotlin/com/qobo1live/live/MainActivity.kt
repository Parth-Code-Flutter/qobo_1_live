package com.qobo1live.live

import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Host activity for Flutter.
 *
 * Facebook Login needs [FlutterFragmentActivity] for activity-result handling.
 * Also hosts the screen-capture MethodChannel used by 1:1 video calls.
 */
class MainActivity : FlutterFragmentActivity() {

    companion object {
        /** Must match Dart [ScreenCaptureGuard] channel name. */
        private const val SCREEN_CAPTURE_CHANNEL =
            "com.qobo1live.live/screen_capture_guard"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCREEN_CAPTURE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                // Blocks screenshots, recent-apps preview, and screen recording.
                "enable" -> {
                    setCaptureBlocked(true)
                    result.success(true)
                }
                // Restore normal capture after the protected screen closes.
                "disable" -> {
                    setCaptureBlocked(false)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * [FLAG_SECURE] alone is not enough when Zego (or Flutter PlatformViews)
     * render into [SurfaceView]s — some OEMs still capture those layers.
     * We also walk the view tree and call [SurfaceView.setSecure].
     */
    private fun setCaptureBlocked(blocked: Boolean) {
        runOnUiThread {
            if (blocked) {
                window.setFlags(
                    WindowManager.LayoutParams.FLAG_SECURE,
                    WindowManager.LayoutParams.FLAG_SECURE,
                )
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
            markSurfaceViewsSecure(window.decorView, blocked)
        }
    }

    private fun markSurfaceViewsSecure(view: View?, secure: Boolean) {
        if (view == null) return
        if (view is SurfaceView) {
            try {
                view.setSecure(secure)
            } catch (_: Throwable) {
                // Best-effort — never crash the call over capture guard.
            }
        }
        if (view is ViewGroup) {
            for (i in 0 until view.childCount) {
                markSurfaceViewsSecure(view.getChildAt(i), secure)
            }
        }
    }
}
