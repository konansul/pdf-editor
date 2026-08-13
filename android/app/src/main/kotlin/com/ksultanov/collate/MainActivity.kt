package com.ksultanov.collate

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "collate/ocr")
            .setMethodCallHandler { call, result ->
                if (call.method != "recognize") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val file = call.argument<String>("path")?.let { File(it) }
                if (file == null || !file.exists()) {
                    result.error("unreadable", "Could not read the page", null)
                    return@setMethodCallHandler
                }

                val image = try {
                    InputImage.fromFilePath(this, Uri.fromFile(file))
                } catch (error: Exception) {
                    result.error("unreadable", error.message, null)
                    return@setMethodCallHandler
                }

                TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                    .process(image)
                    .addOnSuccessListener { text -> result.success(text.text) }
                    .addOnFailureListener { error -> result.error("failed", error.message, null) }
            }
    }
}
