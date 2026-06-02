package com.ahsmobilelabs.openpdf_tools

import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Environment
import android.os.ParcelFileDescriptor
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.apache.pdfbox.Loader
import org.apache.pdfbox.pdmodel.PDDocument
import org.apache.pdfbox.pdmodel.PDPage
import org.apache.pdfbox.pdmodel.PDPageContentStream
import org.apache.pdfbox.pdmodel.common.PDRectangle
import org.apache.pdfbox.pdmodel.encryption.AccessPermission
import org.apache.pdfbox.pdmodel.encryption.StandardProtectionPolicy
import org.apache.pdfbox.pdmodel.font.PDType1Font
import org.apache.pdfbox.pdmodel.font.Standard14Fonts
import org.apache.pdfbox.pdmodel.graphics.state.PDExtendedGraphicsState
import org.apache.pdfbox.text.PDFTextStripper
import org.apache.pdfbox.util.Matrix
import java.io.File
import java.io.FileOutputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

class PdfManipulationHandler(private val context: Context) {

    private val mainHandler = Handler(Looper.getMainLooper())

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "mergePdfs" -> mergePdfs(call, result)
                "splitPdf" -> splitPdf(call, result)
                "splitPdfRange" -> splitPdfRange(call, result)
                "compressPdf" -> compressPdf(call, result)
                "extractText" -> extractText(call, result)
                "pdfToImages" -> pdfToImages(call, result)
                "zipDirectory" -> zipDirectory(call, result)
                "encryptPdf" -> encryptPdf(call, result)
                "createPdfA" -> createPdfA(call, result)
                "getPageCount" -> getPageCount(call, result)
                "rotatePdf" -> rotatePdf(call, result)
                "addTextToPdf" -> addTextToPdf(call, result)
                "addWatermark" -> addWatermark(call, result)
                "cropPdf" -> cropPdf(call, result)
                "changeBackgroundColor" -> changeBackgroundColor(call, result)
                "copyUriToCache" -> copyUriToCache(call, result)
                "exportToPublicDirectory" -> exportToPublicDirectory(call, result)
                else -> result.notImplemented()
            }
        } catch (e: Throwable) {
            result.error("PDF_ERROR", "PDF operation failed: ${e.message}", e.stackTraceToString())
        }
    }

    // ─── MERGE ───────────────────────────────────────────────────────────────

    private fun mergePdfs(call: MethodCall, result: MethodChannel.Result) {
        val inputPaths = call.argument<List<String>>("inputPaths")
            ?: return result.error("INVALID_ARGS", "inputPaths required", null)
        val outputPath = call.argument<String>("outputPath")
            ?: return result.error("INVALID_ARGS", "outputPath required", null)

        Thread {
            val merged = PDDocument()
            val sourceDocs = mutableListOf<PDDocument>()
            try {
                ensureParentDir(outputPath)

                for (path in inputPaths) {
                    val file = File(path)
                    if (!file.exists()) throw Exception("File not found: $path")
                    val doc = Loader.loadPDF(file)
                    sourceDocs.add(doc)
                    for (i in 0 until doc.numberOfPages) {
                        merged.importPage(doc.getPage(i))
                    }
                }

                merged.save(outputPath)

                mainHandler.post { result.success(outputPath) }
            } catch (e: Exception) {
                mainHandler.post { result.error("MERGE_FAILED", e.message, e.stackTraceToString()) }
            } finally {
                try { merged.close() } catch (_: Exception) {}
                sourceDocs.forEach { try { it.close() } catch (_: Exception) {} }
            }
        }.start()
    }

    // ─── SPLIT ───────────────────────────────────────────────────────────────

    private fun splitPdf(call: MethodCall, result: MethodChannel.Result) {
        val inputPath = call.argument<String>("inputPath")
            ?: return result.error("INVALID_ARGS", "inputPath required", null)
        val outputDir = call.argument<String>("outputDir")
            ?: return result.error("INVALID_ARGS", "outputDir required", null)

        Thread {
            try {
                File(outputDir).mkdirs()
                val outputPaths = mutableListOf<String>()
                val ts = System.currentTimeMillis()
                Loader.loadPDF(File(inputPath)).use { doc ->
                    val pageCount = doc.numberOfPages

                    for (i in 0 until pageCount) {
                        PDDocument().use { singlePage ->
                            singlePage.importPage(doc.getPage(i))
                            val outPath = "$outputDir/page_${i + 1}_$ts.pdf"
                            singlePage.save(outPath)
                            outputPaths.add(outPath)
                        }
                    }
                }
                mainHandler.post { result.success(outputPaths) }
            } catch (e: Exception) {
                mainHandler.post { result.error("SPLIT_FAILED", e.message, e.stackTraceToString()) }
            }
        }.start()
    }

    private fun splitPdfRange(call: MethodCall, result: MethodChannel.Result) {
        val inputPath  = call.argument<String>("inputPath")  ?: return result.error("INVALID_ARGS","inputPath required",null)
        val outputPath = call.argument<String>("outputPath") ?: return result.error("INVALID_ARGS","outputPath required",null)
        val startPage  = call.argument<Int>("startPage") ?: 1
        val endPage    = call.argument<Int>("endPage")   ?: 1

        Thread {
            try {
                Loader.loadPDF(File(inputPath)).use { doc ->
                    PDDocument().use { rangeDoc ->
                        val start = (startPage - 1).coerceAtLeast(0)
                        val end   = (endPage   - 1).coerceAtMost(doc.numberOfPages - 1)
                        if (start > end) {
                            throw Exception("Invalid page range: $startPage-$endPage")
                        }

                        for (i in start..end) {
                            rangeDoc.importPage(doc.getPage(i))
                        }
                        ensureParentDir(outputPath)
                        rangeDoc.save(outputPath)
                    }
                }
                mainHandler.post { result.success(outputPath) }
            } catch (e: Exception) {
                mainHandler.post { result.error("SPLIT_RANGE_FAILED", e.message, null) }
            }
        }.start()
    }

    // ─── COMPRESS ────────────────────────────────────────────────────────────

    private fun compressPdf(call: MethodCall, result: MethodChannel.Result) {
        val inputPath = call.argument<String>("inputPath")
            ?: return result.error("INVALID_ARGS", "inputPath is required", null)
        val outputPath = call.argument<String>("outputPath")
            ?: return result.error("INVALID_ARGS", "outputPath is required", null)
        val quality = call.argument<Int>("quality") ?: 60

        Thread {
            try {
                val inputFile = File(inputPath)
                if (!inputFile.exists()) {
                    mainHandler.post { result.error("COMPRESS_FAILED", "Input file not found: $inputPath", null) }
                    return@Thread
                }

                ensureParentDir(outputPath)

                // Render each page as a compressed JPEG bitmap, then rebuild a new PDF
                // using Android-native APIs only (no PDFBox AWT dependencies).
                val pfd = ParcelFileDescriptor.open(inputFile, ParcelFileDescriptor.MODE_READ_ONLY)
                val renderer = PdfRenderer(pfd)
                val pageCount = renderer.pageCount

                val jpegQuality = quality.coerceIn(30, 90)
                val dpiScale = when {
                    quality <= 40 -> 1.0f   // screen quality
                    quality <= 60 -> 1.5f   // ebook quality
                    else -> 2.0f            // print quality
                }

                val newPdfDoc = android.graphics.pdf.PdfDocument()

                for (i in 0 until pageCount) {
                    val page = renderer.openPage(i)
                    val pageWidth = page.width
                    val pageHeight = page.height
                    val renderWidth = (pageWidth * dpiScale).toInt()
                    val renderHeight = (pageHeight * dpiScale).toInt()

                    // Render page to bitmap
                    val bitmap = Bitmap.createBitmap(renderWidth, renderHeight, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(bitmap)
                    canvas.drawColor(Color.WHITE)
                    page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_PRINT)
                    page.close()

                    // Compress through JPEG to reduce size
                    val jpegStream = java.io.ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.JPEG, jpegQuality, jpegStream)
                    bitmap.recycle()
                    val jpegBytes = jpegStream.toByteArray()
                    val compressedBitmap = android.graphics.BitmapFactory.decodeByteArray(jpegBytes, 0, jpegBytes.size)

                    // Write compressed bitmap to new PDF page
                    val pageInfo = android.graphics.pdf.PdfDocument.PageInfo.Builder(pageWidth, pageHeight, i + 1).create()
                    val pdfPage = newPdfDoc.startPage(pageInfo)
                    val destRect = android.graphics.RectF(0f, 0f, pageWidth.toFloat(), pageHeight.toFloat())
                    pdfPage.canvas.drawBitmap(compressedBitmap, null, destRect, null)
                    newPdfDoc.finishPage(pdfPage)
                    compressedBitmap.recycle()
                }

                renderer.close()
                pfd.close()

                FileOutputStream(outputPath).use { fos ->
                    newPdfDoc.writeTo(fos)
                }
                newPdfDoc.close()

                mainHandler.post { result.success(outputPath) }
            } catch (e: Throwable) {
                mainHandler.post { result.error("COMPRESS_FAILED", e.message ?: "Unknown error", null) }
            }
        }.start()
    }

    // ─── EXTRACT TEXT ─────────────────────────────────────────────────────────

    private fun extractText(call: MethodCall, result: MethodChannel.Result) {
        val inputPath = call.argument<String>("inputPath")
            ?: return result.error("INVALID_ARGS", "inputPath is required", null)
        val outputPath = call.argument<String>("outputPath")
            ?: return result.error("INVALID_ARGS", "outputPath is required", null)

        Thread {
            try {
                val doc = Loader.loadPDF(File(inputPath))
                val text = PDFTextStripper().getText(doc)
                doc.close()
                ensureParentDir(outputPath)
                File(outputPath).writeText(text)
                mainHandler.post { result.success(outputPath) }
            } catch (e: Exception) {
                mainHandler.post { result.error("EXTRACT_TEXT_FAILED", e.message, null) }
            }
        }.start()
    }

    // ─── PDF TO IMAGES ────────────────────────────────────────────────────────

    private fun pdfToImages(call: MethodCall, result: MethodChannel.Result) {
        val inputPath = call.argument<String>("inputPath")
            ?: return result.error("INVALID_ARGS", "inputPath is required", null)
        val outputDir = call.argument<String>("outputDir")
            ?: return result.error("INVALID_ARGS", "outputDir is required", null)
        val format = call.argument<String>("format") ?: "png"
        val quality = call.argument<Int>("quality") ?: 150

        Thread {
            try {
                val file = File(inputPath)
                val pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                val renderer = PdfRenderer(pfd)
                val outputPaths = mutableListOf<String>()
                val ts = System.currentTimeMillis()
                val outDirFile = File(outputDir).also { it.mkdirs() }

                val compressFormat = if (format.lowercase() == "jpg" || format.lowercase() == "jpeg")
                    Bitmap.CompressFormat.JPEG else Bitmap.CompressFormat.PNG
                val ext = if (format.lowercase() == "jpg" || format.lowercase() == "jpeg") "jpg" else "png"

                for (i in 0 until renderer.pageCount) {
                    val page = renderer.openPage(i)
                    val scale = quality / 72f
                    val width = (page.width * scale).toInt()
                    val height = (page.height * scale).toInt()
                    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)

                    val canvas = Canvas(bitmap)
                    canvas.drawColor(Color.WHITE)

                    page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                    page.close()

                    val outPath = "${outDirFile.absolutePath}/page_${i + 1}_$ts.$ext"
                    FileOutputStream(outPath).use { fos ->
                        bitmap.compress(compressFormat, 85, fos)
                    }
                    bitmap.recycle()
                    outputPaths.add(outPath)
                }
                renderer.close()
                pfd.close()
                mainHandler.post { result.success(outputPaths) }
            } catch (e: Exception) {
                mainHandler.post { result.error("PDF_TO_IMAGES_FAILED", e.message, null) }
            }
        }.start()
    }

    // ─── ZIP DIRECTORY ────────────────────────────────────────────────────────

    private fun zipDirectory(call: MethodCall, result: MethodChannel.Result) {
        val inputDir = call.argument<String>("inputDir")
            ?: return result.error("INVALID_ARGS", "inputDir is required", null)
        val outputPath = call.argument<String>("outputPath")
            ?: return result.error("INVALID_ARGS", "outputPath is required", null)

        Thread {
            try {
                ensureParentDir(outputPath)
                ZipOutputStream(FileOutputStream(outputPath)).use { zos ->
                    File(inputDir).walkTopDown().filter { it.isFile }.forEach { file ->
                        val entry = ZipEntry(file.name)
                        zos.putNextEntry(entry)
                        file.inputStream().use { it.copyTo(zos) }
                        zos.closeEntry()
                    }
                }
                mainHandler.post { result.success(outputPath) }
            } catch (e: Exception) {
                mainHandler.post { result.error("ZIP_FAILED", e.message, null) }
            }
        }.start()
    }

    // ─── ENCRYPT PDF ──────────────────────────────────────────────────────────

    private fun encryptPdf(call: MethodCall, result: MethodChannel.Result) {
        val inputPath = call.argument<String>("inputPath")
            ?: return result.error("INVALID_ARGS", "inputPath is required", null)
        val outputPath = call.argument<String>("outputPath")
            ?: return result.error("INVALID_ARGS", "outputPath is required", null)
        val userPassword = call.argument<String>("userPassword") ?: "user"
        val ownerPassword = call.argument<String>("ownerPassword") ?: "owner"

        Thread {
            try {
                val doc = Loader.loadPDF(File(inputPath))
                val policy = StandardProtectionPolicy(ownerPassword, userPassword, AccessPermission())
                policy.encryptionKeyLength = 256
                doc.protect(policy)
                ensureParentDir(outputPath)
                doc.save(outputPath)
                doc.close()
                mainHandler.post { result.success(outputPath) }
            } catch (e: Exception) {
                mainHandler.post { result.error("ENCRYPT_FAILED", e.message, null) }
            }
        }.start()
    }

    // ─── CREATE PDF/A ─────────────────────────────────────────────────────────

    private fun createPdfA(call: MethodCall, result: MethodChannel.Result) {
        val inputPath = call.argument<String>("inputPath")
            ?: return result.error("INVALID_ARGS", "inputPath is required", null)
        val outputPath = call.argument<String>("outputPath")
            ?: return result.error("INVALID_ARGS", "outputPath is required", null)

        Thread {
            try {
                val doc = Loader.loadPDF(File(inputPath))
                ensureParentDir(outputPath)
                doc.save(outputPath)
                doc.close()
                mainHandler.post { result.success(outputPath) }
            } catch (e: Exception) {
                mainHandler.post { result.error("PDFA_FAILED", e.message, null) }
            }
        }.start()
    }

    // ─── GET PAGE COUNT ───────────────────────────────────────────────────────

    private fun getPageCount(call: MethodCall, result: MethodChannel.Result) {
        val inputPath = call.argument<String>("inputPath")
            ?: return result.error("INVALID_ARGS", "inputPath is required", null)

        Thread {
            try {
                val doc = Loader.loadPDF(File(inputPath))
                val count = doc.numberOfPages
                doc.close()
                mainHandler.post { result.success(count) }
            } catch (e: Exception) {
                mainHandler.post { result.error("PAGE_COUNT_FAILED", e.message, null) }
            }
        }.start()
    }

    // ─── ROTATE PDF ───────────────────────────────────────────────────────────

    private fun rotatePdf(call: MethodCall, result: MethodChannel.Result) {
        val inputPath = call.argument<String>("inputPath")
            ?: return result.error("INVALID_ARGS", "inputPath is required", null)
        val outputPath = call.argument<String>("outputPath")
            ?: return result.error("INVALID_ARGS", "outputPath is required", null)
        val angle = call.argument<Int>("angle") ?: 90

        Thread {
            try {
                val doc = Loader.loadPDF(File(inputPath))
                for (page in doc.pages.toList()) {
                    page.rotation = (page.rotation + angle) % 360
                }
                ensureParentDir(outputPath)
                doc.save(outputPath)
                doc.close()
                mainHandler.post { result.success(outputPath) }
            } catch (e: Exception) {
                mainHandler.post { result.error("ROTATE_FAILED", e.message, null) }
            }
        }.start()
    }

    // ─── ADD TEXT ─────────────────────────────────────────────────────────────

    private fun addTextToPdf(call: MethodCall, result: MethodChannel.Result) {
        val inputPath = call.argument<String>("inputPath")
            ?: return result.error("INVALID_ARGS", "inputPath is required", null)
        val outputPath = call.argument<String>("outputPath")
            ?: return result.error("INVALID_ARGS", "outputPath is required", null)
        val text = call.argument<String>("text") ?: "Text"
        val fontSize = call.argument<Double>("fontSize")?.toFloat() ?: 16f
        val x = call.argument<Double>("x")?.toFloat() ?: 50f
        val y = call.argument<Double>("y")?.toFloat() ?: 700f

        Thread {
            try {
                val doc  = Loader.loadPDF(File(inputPath))
                val font = PDType1Font(Standard14Fonts.FontName.HELVETICA)
                val page = doc.pages.toList().firstOrNull()
                if (page != null) {
                    PDPageContentStream(
                        doc, page, PDPageContentStream.AppendMode.APPEND, true
                    ).use { cs ->
                        cs.beginText()
                        cs.setFont(font, fontSize)
                        cs.newLineAtOffset(x, y)
                        cs.showText(text)
                        cs.endText()
                    }
                }
                ensureParentDir(outputPath)
                doc.save(outputPath)
                doc.close()
                mainHandler.post { result.success(outputPath) }
            } catch (e: Exception) {
                mainHandler.post { result.error("ADD_TEXT_FAILED", e.message, null) }
            }
        }.start()
    }

    // ─── ADD WATERMARK ────────────────────────────────────────────────────────

    private fun addWatermark(call: MethodCall, result: MethodChannel.Result) {
        val inputPath = call.argument<String>("inputPath")
            ?: return result.error("INVALID_ARGS", "inputPath is required", null)
        val outputPath = call.argument<String>("outputPath")
            ?: return result.error("INVALID_ARGS", "outputPath is required", null)
        val text = call.argument<String>("text") ?: "WATERMARK"
        val fontSize = call.argument<Double>("fontSize")?.toFloat() ?: 48f
        val opacity = call.argument<Double>("opacity")?.toFloat() ?: 0.3f

        Thread {
            try {
                val doc  = Loader.loadPDF(File(inputPath))
                val font = PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD)

                for (page in doc.pages.toList()) {
                    val mediaBox = page.mediaBox
                    val centerX  = mediaBox.width  / 2f
                    val centerY  = mediaBox.height / 2f
                    val gs = PDExtendedGraphicsState()
                    gs.nonStrokingAlphaConstant = opacity

                    PDPageContentStream(
                        doc, page, PDPageContentStream.AppendMode.APPEND, true
                    ).use { cs ->
                        cs.saveGraphicsState()
                        cs.setGraphicsStateParameters(gs)
                        cs.beginText()
                        cs.setFont(font, fontSize)
                        val rad  = Math.toRadians(45.0)
                        val cosA = Math.cos(rad).toFloat()
                        val sinA = Math.sin(rad).toFloat()
                        cs.setTextMatrix(Matrix(cosA, sinA, -sinA, cosA, centerX - 80f, centerY))
                        cs.showText(text)
                        cs.endText()
                        cs.restoreGraphicsState()
                    }
                }
                ensureParentDir(outputPath)
                doc.save(outputPath)
                doc.close()
                mainHandler.post { result.success(outputPath) }
            } catch (e: Exception) {
                mainHandler.post { result.error("WATERMARK_FAILED", e.message, null) }
            }
        }.start()
    }

    // ─── CROP PDF ─────────────────────────────────────────────────────────────

    private fun cropPdf(call: MethodCall, result: MethodChannel.Result) {
        val inputPath = call.argument<String>("inputPath")
            ?: return result.error("INVALID_ARGS", "inputPath is required", null)
        val outputPath = call.argument<String>("outputPath")
            ?: return result.error("INVALID_ARGS", "outputPath is required", null)
        val left = call.argument<Double>("left")?.toFloat() ?: 0f
        val bottom = call.argument<Double>("bottom")?.toFloat() ?: 0f
        val right = call.argument<Double>("right")?.toFloat() ?: 612f
        val top = call.argument<Double>("top")?.toFloat() ?: 792f

        Thread {
            try {
                val doc = Loader.loadPDF(File(inputPath))
                val cropBox = PDRectangle(left, bottom, right - left, top - bottom)
                for (page in doc.pages.toList()) {
                    page.cropBox = cropBox
                }
                ensureParentDir(outputPath)
                doc.save(outputPath)
                doc.close()
                mainHandler.post { result.success(outputPath) }
            } catch (e: Exception) {
                mainHandler.post { result.error("CROP_FAILED", e.message, null) }
            }
        }.start()
    }

    // ─── CHANGE BACKGROUND COLOR ──────────────────────────────────────────────

    private fun changeBackgroundColor(call: MethodCall, result: MethodChannel.Result) {
        val inputPath = call.argument<String>("inputPath")
            ?: return result.error("INVALID_ARGS", "inputPath is required", null)
        val outputPath = call.argument<String>("outputPath")
            ?: return result.error("INVALID_ARGS", "outputPath is required", null)
        val hexColor = call.argument<String>("hexColor") ?: "#FFFFFF"

        Thread {
            try {
                val doc = Loader.loadPDF(File(inputPath))
                val color = Color.parseColor(hexColor)
                val r = Color.red(color) / 255f
                val g = Color.green(color) / 255f
                val b = Color.blue(color) / 255f

                for (page in doc.pages.toList()) {
                    val mediaBox = page.mediaBox
                    PDPageContentStream(
                        doc, page, PDPageContentStream.AppendMode.PREPEND, true
                    ).use { cs ->
                        cs.setNonStrokingColor(r, g, b)
                        cs.addRect(
                            mediaBox.lowerLeftX, mediaBox.lowerLeftY,
                            mediaBox.width, mediaBox.height
                        )
                        cs.fill()
                    }
                }
                ensureParentDir(outputPath)
                doc.save(outputPath)
                doc.close()
                mainHandler.post { result.success(outputPath) }
            } catch (e: Exception) {
                mainHandler.post { result.error("BG_COLOR_FAILED", e.message, null) }
            }
        }.start()
    }

    private fun copyUriToCache(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
            ?: return result.error("INVALID_ARGS", "uri required", null)

        Thread {
            try {
                val uri = android.net.Uri.parse(uriString)
                val fileName = getFileNameFromUri(uri) ?: "temp_${System.currentTimeMillis()}.pdf"
                val outFile = File(context.cacheDir, fileName)

                val inputStream = context.contentResolver.openInputStream(uri)
                    ?: if (uri.scheme == "file" && uri.path != null) {
                        File(uri.path!!).inputStream()
                    } else {
                        null
                    }
                    ?: throw Exception("Cannot open URI: $uriString")

                inputStream.use { input ->
                    outFile.outputStream().use { output -> input.copyTo(output) }
                }

                mainHandler.post { result.success(outFile.absolutePath) }
            } catch (e: Exception) {
                mainHandler.post { result.error("COPY_FAILED", e.message, null) }
            }
        }.start()
    }

    private fun exportToPublicDirectory(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
            ?: return result.error("INVALID_ARGS", "sourcePath required", null)
        val fileName = call.argument<String>("fileName")
            ?: return result.error("INVALID_ARGS", "fileName required", null)
        val category = call.argument<String>("category") ?: "exports"
        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"

        Thread {
            try {
                val sourceFile = File(sourcePath)
                if (!sourceFile.exists()) {
                    throw Exception("Source file not found: $sourcePath")
                }

                val relativePath = publicRelativePath(category)

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val values = ContentValues().apply {
                        put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                        put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                        put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                        put(MediaStore.MediaColumns.IS_PENDING, 1)
                    }

                    val collection = when (category) {
                        "pictures" -> MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                        "documents" -> MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                        else -> MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                    }

                    val uri = context.contentResolver.insert(collection, values)
                        ?: throw Exception("Could not create public output file")

                    context.contentResolver.openOutputStream(uri)?.use { output ->
                        sourceFile.inputStream().use { input -> input.copyTo(output) }
                    } ?: throw Exception("Could not open public output stream")

                    val completeValues = ContentValues().apply {
                        put(MediaStore.MediaColumns.IS_PENDING, 0)
                    }
                    context.contentResolver.update(uri, completeValues, null, null)

                    mainHandler.post {
                        result.success(
                            mapOf(
                                "uri" to uri.toString(),
                                "fileName" to fileName,
                                "displayPath" to "$relativePath$fileName"
                            )
                        )
                    }
                } else {
                    @Suppress("DEPRECATION")
                    val baseDir = when (category) {
                        "pictures" -> Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
                        "documents" -> Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
                        else -> Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                    }
                    val subDir = if (category == "exports") {
                        File(baseDir, "OpenPDF Tools/Exports")
                    } else {
                        File(baseDir, "OpenPDF Tools")
                    }
                    subDir.mkdirs()
                    val target = uniqueFile(subDir, fileName)
                    sourceFile.copyTo(target, overwrite = false)
                    mainHandler.post {
                        result.success(
                            mapOf(
                                "uri" to target.toURI().toString(),
                                "fileName" to target.name,
                                "displayPath" to target.absolutePath
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                mainHandler.post { result.error("EXPORT_FAILED", e.message, e.stackTraceToString()) }
            }
        }.start()
    }

    private fun publicRelativePath(category: String): String {
        return when (category) {
            "documents" -> "${Environment.DIRECTORY_DOCUMENTS}/OpenPDF Tools/"
            "pictures" -> "${Environment.DIRECTORY_PICTURES}/OpenPDF Tools/"
            "exports" -> "${Environment.DIRECTORY_DOWNLOADS}/OpenPDF Tools/Exports/"
            else -> "${Environment.DIRECTORY_DOWNLOADS}/OpenPDF Tools/"
        }
    }

    private fun uniqueFile(dir: File, fileName: String): File {
        val dot = fileName.lastIndexOf('.')
        val base = if (dot > 0) fileName.substring(0, dot) else fileName
        val ext = if (dot > 0) fileName.substring(dot) else ""
        var candidate = File(dir, fileName)
        var index = 1
        while (candidate.exists()) {
            candidate = File(dir, "${base}_$index$ext")
            index++
        }
        return candidate
    }

    private fun getFileNameFromUri(uri: android.net.Uri): String? {
        if (uri.scheme == "content") {
            context.contentResolver.query(
                uri,
                arrayOf(android.provider.OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    return cursor.getString(
                        cursor.getColumnIndexOrThrow(android.provider.OpenableColumns.DISPLAY_NAME)
                    )
                }
            }
        }
        return uri.lastPathSegment
    }

    // ─── HELPER ───────────────────────────────────────────────────────────────

    private fun ensureParentDir(path: String) {
        File(path).parentFile?.mkdirs()
    }
}
