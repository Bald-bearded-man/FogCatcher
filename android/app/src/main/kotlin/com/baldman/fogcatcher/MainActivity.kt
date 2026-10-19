package com.baldman.fogcatcher

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Back at the root would finish() the activity, killing the engine and the location service.
    override fun popSystemNavigator(): Boolean = moveTaskToBack(true)
}
