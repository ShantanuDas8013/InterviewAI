package com.csdcorp.speech_to_text

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.util.*

/** SpeechToTextPlugin */
public class SpeechToTextPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private var speechRecognizer: SpeechRecognizer? = null
    private var recognizerIntent: Intent? = null
    private var currentActivity: Activity? = null
    private var pluginContext: Context? = null
    private var activeResult: Result? = null
    private var localeId: String = "en_US"
    private var partialResults: Boolean = true

    companion object {
        private const val logTag = "SpeechToTextPlugin"
        private const val speechToTextPermissionCode = 28521

        // This static function is optional and equivalent to onAttachedToEngine. It supports the old
        // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
        // plugin registration via this function while apps migrate to use the new Android APIs
        // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
        //
        // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
        // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
        // depending on the user's project. onAttachedToEngine or registerWith must both be defined
        // in the same class.
        @JvmStatic
        fun registerWith(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
            val plugin = SpeechToTextPlugin()
            plugin.onAttachedToEngine(flutterPluginBinding)
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "speech_to_text")
        channel.setMethodCallHandler(this)
        pluginContext = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        activeResult = result
        when (call.method) {
            "initialize" -> {
                initializeSpeechRecognizer(result)
            }
            "listen" -> {
                startListening(call, result)
            }
            "stop" -> {
                stopListening(result)
            }
            "cancel" -> {
                cancelListening(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        pluginContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        currentActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        currentActivity = null
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode == speechToTextPermissionCode) {
            // Handle permission result
            return true
        }
        return false
    }

    private fun initializeSpeechRecognizer(result: Result) {
        if (pluginContext == null) {
            result.error("no_context", "Plugin context is null", null)
            return
        }

        if (SpeechRecognizer.isRecognitionAvailable(pluginContext!!)) {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(pluginContext!!)
            speechRecognizer?.setRecognitionListener(createRecognitionListener())
            recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
            recognizerIntent?.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            recognizerIntent?.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, partialResults)
            recognizerIntent?.putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeId)
            result.success(true)
        } else {
            result.error("not_available", "Speech recognition is not available on this device", null)
        }
    }

    private fun startListening(call: MethodCall, result: Result) {
        if (speechRecognizer == null) {
            result.error("not_initialized", "Speech recognizer not initialized", null)
            return
        }

        // Update locale and partial results if provided
        call.argument<String>("localeId")?.let { localeId = it }
        call.argument<Boolean>("partialResults")?.let { partialResults = it }

        recognizerIntent?.putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeId)
        recognizerIntent?.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, partialResults)

        try {
            speechRecognizer?.startListening(recognizerIntent)
            result.success(true)
        } catch (e: Exception) {
            result.error("listen_failed", "Failed to start listening: ${e.message}", null)
        }
    }

    private fun stopListening(result: Result) {
        if (speechRecognizer == null) {
            result.error("not_initialized", "Speech recognizer not initialized", null)
            return
        }

        try {
            speechRecognizer?.stopListening()
            result.success(true)
        } catch (e: Exception) {
            result.error("stop_failed", "Failed to stop listening: ${e.message}", null)
        }
    }

    private fun cancelListening(result: Result) {
        if (speechRecognizer == null) {
            result.error("not_initialized", "Speech recognizer not initialized", null)
            return
        }

        try {
            speechRecognizer?.cancel()
            result.success(true)
        } catch (e: Exception) {
            result.error("cancel_failed", "Failed to cancel listening: ${e.message}", null)
        }
    }

    private fun createRecognitionListener(): RecognitionListener {
        return object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                channel.invokeMethod("onStatus", mapOf("status" to "ready"))
            }

            override fun onBeginningOfSpeech() {
                channel.invokeMethod("onStatus", mapOf("status" to "listening"))
            }

            override fun onRmsChanged(rmsdB: Float) {
                channel.invokeMethod("onSoundLevel", mapOf("level" to rmsdB))
            }

            override fun onBufferReceived(buffer: ByteArray?) {
                // Not used
            }

            override fun onEndOfSpeech() {
                channel.invokeMethod("onStatus", mapOf("status" to "done"))
            }

            override fun onError(error: Int) {
                val errorMessage = getErrorMessage(error)
                channel.invokeMethod("onError", mapOf("errorMsg" to errorMessage, "permanent" to isPermanentError(error)))
            }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val confidence = results?.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)
                val resultMap = mutableMapOf<String, Any>()
                resultMap["recognizedWords"] = matches?.get(0) ?: ""
                resultMap["finalResult"] = true
                channel.invokeMethod("onSpeechResult", resultMap)
            }

            override fun onPartialResults(partialResults: Bundle?) {
                if (!this@SpeechToTextPlugin.partialResults) return
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (matches != null && matches.isNotEmpty()) {
                    val resultMap = mutableMapOf<String, Any>()
                    resultMap["recognizedWords"] = matches[0]
                    resultMap["finalResult"] = false
                    channel.invokeMethod("onSpeechResult", resultMap)
                }
            }

            override fun onEvent(eventType: Int, params: Bundle?) {
                // Not used
            }
        }
    }

    private fun getErrorMessage(error: Int): String {
        return when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
            SpeechRecognizer.ERROR_CLIENT -> "Client side error"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
            SpeechRecognizer.ERROR_NETWORK -> "Network error"
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
            SpeechRecognizer.ERROR_NO_MATCH -> "No match"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer busy"
            SpeechRecognizer.ERROR_SERVER -> "Server error"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
            else -> "Unknown error"
        }
    }

    private fun isPermanentError(error: Int): Boolean {
        return when (error) {
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> true
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> false
            SpeechRecognizer.ERROR_AUDIO -> true
            else -> false
        }
    }
}