package space.d11s.niceproportions

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var audio: AudioCues? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        audio = AudioCues(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        audio?.release()
        audio = null
        super.onDestroy()
    }
}
