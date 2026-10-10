package com.sheraztech.taash

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Keep the display awake while the app is in the foreground so a turn
        // timer never runs out behind a dimmed screen. The flag is scoped to
        // this window, so the device sleeps normally once the app is left.
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
