package space.d11s.niceproportions

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.SoundPool
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Workout sound cues and the optional music loop, played from the app's own
 * bundled WAVs. Other apps' audio is ducked (lowered), never stopped, and
 * nothing plays while the phone is on silent or vibrate.
 */
class AudioCues(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL)
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val main = Handler(Looper.getMainLooper())

    // Cues ride the media stream (the volume the side buttons change in an
    // app). SONIFICATION went to the system stream, which many phones keep at 0.
    private val cueAttrs = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()
    private val musicAttrs = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
        .build()

    private val pool = SoundPool.Builder().setMaxStreams(3).setAudioAttributes(cueAttrs).build()
    private val sounds = mutableMapOf<String, Int>()
    private var music: MediaPlayer? = null
    private var focus: AudioFocusRequest? = null
    private var cueFocusHeld = false
    private val releaseCueFocus = Runnable {
        cueFocusHeld = false
        if (music == null) abandonFocus()
    }

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "load" -> {
                    @Suppress("UNCHECKED_CAST")
                    val assets = call.arguments as Map<String, String>
                    for ((name, asset) in assets) {
                        if (!sounds.containsKey(name)) sounds[name] = pool.load(copyAsset(asset).path, 1)
                    }
                    result.success(null)
                }
                "play" -> {
                    val id = sounds[call.argument<String>("name")]
                    val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
                    if (id != null && volume > 0f && !isSilenced()) {
                        requestFocus()
                        cueFocusHeld = true
                        main.removeCallbacks(releaseCueFocus)
                        main.postDelayed(releaseCueFocus, CUE_FOCUS_MS)
                        pool.play(id, volume, volume, 1, 0, 1f)
                    }
                    result.success(null)
                }
                "startMusic" -> {
                    val asset = call.argument<String>("asset")!!
                    val volume = (call.argument<Double>("volume") ?: 0.3).toFloat()
                    if (!isSilenced()) startMusic(asset, volume)
                    result.success(null)
                }
                "musicVolume" -> {
                    val volume = (call.argument<Double>("volume") ?: 0.3).toFloat()
                    music?.setVolume(volume, volume)
                    result.success(null)
                }
                "pauseMusic" -> {
                    music?.takeIf { it.isPlaying }?.pause()
                    result.success(null)
                }
                "resumeMusic" -> {
                    if (!isSilenced()) music?.start()
                    result.success(null)
                }
                "stopMusic" -> {
                    stopMusic()
                    result.success(null)
                }
                "isSilenced" -> result.success(isSilenced())
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("audio", e.message, null)
        }
    }

    private fun isSilenced() = audioManager.ringerMode != AudioManager.RINGER_MODE_NORMAL

    /** SoundPool and MediaPlayer need a real file; copy the bundled asset to the cache once. */
    private fun copyAsset(asset: String): File {
        val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)
        val out = File(context.cacheDir, "sounds/" + asset.substringAfterLast('/'))
        if (!out.exists()) {
            out.parentFile?.mkdirs()
            context.assets.open(key).use { input -> out.outputStream().use { input.copyTo(it) } }
        }
        return out
    }

    private fun startMusic(asset: String, volume: Float) {
        stopMusic()
        requestFocus()
        music = MediaPlayer().apply {
            setAudioAttributes(musicAttrs)
            setDataSource(copyAsset(asset).path)
            isLooping = true
            setVolume(volume, volume)
            prepare()
            start()
        }
    }

    private fun stopMusic() {
        music?.run {
            try { stop() } catch (_: IllegalStateException) {}
            release()
        }
        music = null
        if (!cueFocusHeld) abandonFocus()
    }

    /** Ask other apps to duck, not stop. */
    private fun requestFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (focus == null) {
                focus = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                    .setAudioAttributes(cueAttrs)
                    .setWillPauseWhenDucked(false)
                    .build()
            }
            audioManager.requestAudioFocus(focus!!)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                null, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
            )
        }
    }

    private fun abandonFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focus?.let { audioManager.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(null)
        }
    }

    fun release() {
        main.removeCallbacks(releaseCueFocus)
        stopMusic()
        abandonFocus()
        pool.release()
        channel.setMethodCallHandler(null)
    }

    companion object {
        const val CHANNEL = "space.d11s.niceproportions/audio"
        const val CUE_FOCUS_MS = 1200L
    }
}
