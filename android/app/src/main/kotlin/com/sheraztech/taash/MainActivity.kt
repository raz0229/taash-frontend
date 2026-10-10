package com.sheraztech.taash

import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Draw behind the system bars on every API level, not just on Android
        // 15+ where edge-to-edge is enforced. Flutter reports the bar insets
        // through MediaQuery, so SafeArea keeps content clear of them.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        // Keep the display awake while the app is in the foreground so a turn
        // timer never runs out behind a dimmed screen. The flag is scoped to
        // this window, so the device sleeps normally once the app is left.
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        lockPortraitOnPhones(resources.configuration)
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        // Foldables can cross the phone/tablet line without recreating the
        // activity (smallestScreenSize is in configChanges), so re-evaluate.
        lockPortraitOnPhones(newConfig)
    }

    /// The layout is built for portrait phones, so phones stay portrait. Large
    /// screens (tablets, unfolded foldables, desktop windows) may rotate and
    /// resize freely; PortraitViewport letterboxes and scales the UI there.
    private fun lockPortraitOnPhones(config: Configuration) {
        requestedOrientation = if (config.smallestScreenWidthDp < 600) {
            ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        } else {
            ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
        }
    }
}
