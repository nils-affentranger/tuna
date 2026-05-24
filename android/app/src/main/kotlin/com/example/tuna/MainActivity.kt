package com.example.tuna

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var isNativeRunning = false
    private var pendingPermissionStart = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PITCH_STREAM_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                    if (hasAudioPermission()) {
                        startNativeStream()
                    } else {
                        pendingPermissionStart = true
                        requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), RECORD_AUDIO_REQUEST)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    pendingPermissionStart = false
                    stopNativeStream()
                    eventSink = null
                }
            },
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        mainHandler.post(pitchPoller)
    }

    override fun onDestroy() {
        stopNativeStream()
        mainHandler.removeCallbacks(pitchPoller)
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != RECORD_AUDIO_REQUEST || !pendingPermissionStart) {
            return
        }

        pendingPermissionStart = false
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            startNativeStream()
        } else {
            eventSink?.error(
                "record_audio_denied",
                "Microphone permission is required for pitch detection.",
                null,
            )
        }
    }

    private fun hasAudioPermission(): Boolean =
        checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

    private fun startNativeStream() {
        if (isNativeRunning) {
            return
        }

        isNativeRunning = nativeStartTuner()
        if (!isNativeRunning) {
            eventSink?.error("oboe_start_failed", nativeGetLastError(), null)
        }
    }

    private fun stopNativeStream() {
        if (!isNativeRunning) {
            return
        }

        nativeStopTuner()
        isNativeRunning = false
    }

    private val pitchPoller =
        object : Runnable {
            override fun run() {
                if (isNativeRunning) {
                    val pitch = nativeGetLatestPitch()
                    eventSink?.success(
                        mapOf(
                            "hz" to pitch.getOrElse(0) { 0f }.toDouble(),
                            "clarity" to pitch.getOrElse(1) { 0f }.toDouble(),
                        ),
                    )
                }
                mainHandler.postDelayed(this, PITCH_POLL_INTERVAL_MS)
            }
        }

    private external fun nativeStartTuner(): Boolean
    private external fun nativeStopTuner()
    private external fun nativeGetLatestPitch(): FloatArray
    private external fun nativeGetLastError(): String

    companion object {
        private const val PITCH_STREAM_CHANNEL = "tuna/pitch_stream"
        private const val RECORD_AUDIO_REQUEST = 9101
        private const val PITCH_POLL_INTERVAL_MS = 33L

        init {
            System.loadLibrary("tuna_audio")
        }
    }
}
