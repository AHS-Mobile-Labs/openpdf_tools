package com.ahsmobilelabs.openpdf_tools

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PDF_OPENER_CHANNEL = "com.openpdf.tools/pdfOpener"
    private val PDF_MANIPULATION_CHANNEL = "com.openpdf.tools/pdfManipulation"
    private lateinit var pdfManipulationHandler: PdfManipulationHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        pdfManipulationHandler = PdfManipulationHandler(this)

        // PDF Opener channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PDF_OPENER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "registerPdfOpener" -> result.success(true)
                    "getReceivedPdfPath" -> result.success(extractPdfPathFromIntent())
                    else -> result.notImplemented()
                }
            }

        // PDF Manipulation channel — delegate everything to the handler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PDF_MANIPULATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                pdfManipulationHandler.handleMethodCall(call, result)
            }

        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (intent.action == Intent.ACTION_VIEW) {
            val uri = intent.data ?: return
            if (isPdfFile(uri)) {
                val path = getFilePathFromUri(uri) ?: return
                flutterEngine?.let {
                    MethodChannel(it.dartExecutor.binaryMessenger, PDF_OPENER_CHANNEL)
                        .invokeMethod("openPdf", path)
                }
            }
        }
    }

    private fun extractPdfPathFromIntent(): String? {
        val uri = intent?.data ?: return null
        return if (isPdfFile(uri)) getFilePathFromUri(uri) else null
    }

    private fun getFilePathFromUri(uri: Uri): String? {
        return when (uri.scheme) {
            "file" -> uri.path
            "content" -> uri.toString()
            "openpdf" -> uri.pathSegments.drop(1).joinToString("/")
            else -> uri.toString()
        }
    }

    private fun isPdfFile(uri: Uri): Boolean {
        val mimeType = contentResolver.getType(uri)
        val path = uri.path ?: uri.toString()
        return mimeType == "application/pdf" || path.endsWith(".pdf", ignoreCase = true)
    }
}
