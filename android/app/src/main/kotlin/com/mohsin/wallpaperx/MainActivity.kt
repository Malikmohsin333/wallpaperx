package com.mohsin.wallpaperx

import android.app.WallpaperManager
import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "wallpaper_channel"
    private val DOWNLOAD_CHANNEL = "download_channel"

    // Track pending result callback
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Wallpaper Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setWallpaper" -> {
                    val path = call.argument<String>("path")
                    val type = call.argument<Int>("type") ?: 0 // 0=home, 1=lock, 2=both
                    if (path != null) {
                        val success = openWallpaperCropScreen(path, type)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is null", null)
                    }
                }
                "setWallpaperDirect" -> {
                    // For direct set without crop UI (fallback)
                    val path = call.argument<String>("path")
                    val type = call.argument<Int>("type") ?: WallpaperManager.FLAG_SYSTEM
                    if (path != null) {
                        val success = setWallpaperDirect(path, type)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Download Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, DOWNLOAD_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "saveToGallery") {
                val bytes = call.argument<ByteArray>("imageBytes")
                val fileName = call.argument<String>("fileName") ?: "wallpaper.jpg"
                if (bytes != null) {
                    val success = saveToGallery(bytes, fileName)
                    result.success(if (success) "success" else "failure")
                } else {
                    result.error("INVALID_ARGUMENT", "Bytes are null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    /**
     * Opens system wallpaper crop screen — instant UI, no delay.
     * type: 0 = home screen, 1 = lock screen, 2 = both
     */
    private fun openWallpaperCropScreen(path: String, type: Int): Boolean {
        return try {
            val file = File(path)
            val uri: Uri = FileProvider.getUriForFile(
                this,
                "${packageName}.fileprovider",
                file
            )

            val wallpaperManager = WallpaperManager.getInstance(this)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Android 7+ — use setCropAndSetWallpaper for instant crop screen
                try {
                    val inputStream = contentResolver.openInputStream(uri)
                    if (inputStream != null) {
                        // type: 0=home(FLAG_SYSTEM=1), 1=lock(FLAG_LOCK=2), 2=both(3)
                        val whichWallpaper = when (type) {
                            0 -> WallpaperManager.FLAG_SYSTEM   // = 1
                            1 -> WallpaperManager.FLAG_LOCK     // = 2
                            else -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK // = 3
                        }
                        wallpaperManager.setStream(inputStream, null, true, whichWallpaper)
                        inputStream.close()
                        true
                    } else {
                        fallbackWallpaperIntent(uri)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                    fallbackWallpaperIntent(uri)
                }
            } else {
                fallbackWallpaperIntent(uri)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun fallbackWallpaperIntent(uri: Uri): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_ATTACH_DATA).apply {
                setDataAndType(uri, "image/*")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                putExtra("mimeType", "image/*")
            }
            startActivity(Intent.createChooser(intent, "Set as wallpaper"))
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    /**
     * Direct wallpaper set without crop UI (for "Both" option)
     */
    private fun setWallpaperDirect(path: String, type: Int): Boolean {
    return try {
        val bitmap = BitmapFactory.decodeFile(path)
        val wallpaperManager = WallpaperManager.getInstance(this)
        
        // Get screen dimensions
        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels
        
        // Scale bitmap to fit screen exactly
        val scaledBitmap = Bitmap.createScaledBitmap(bitmap, screenWidth, screenHeight, true)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            wallpaperManager.setBitmap(scaledBitmap, null, true, type)
        } else {
            @Suppress("DEPRECATION")
            wallpaperManager.setBitmap(scaledBitmap)
        }
        true
    } catch (e: Exception) {
        e.printStackTrace()
        false
    }
}

    private fun saveToGallery(bytes: ByteArray, fileName: String): Boolean {
        return try {
            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val resolver = contentResolver
                val contentValues = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                    put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
                    put(
                        MediaStore.MediaColumns.RELATIVE_PATH,
                        "${Environment.DIRECTORY_PICTURES}/WallpaperX"
                    )
                }
                val uri =
                    resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
                if (uri != null) {
                    resolver.openOutputStream(uri)?.use { outputStream ->
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
                    }
                    true
                } else {
                    false
                }
            } else {
                @Suppress("DEPRECATION")
                val picturesDir =
                    Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
                val appDir = File(picturesDir, "WallpaperX")
                if (!appDir.exists()) appDir.mkdirs()

                val file = File(appDir, fileName)
                FileOutputStream(file).use { outputStream ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
                }
                true
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
