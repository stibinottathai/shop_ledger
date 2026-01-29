package com.shopled.native_share

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class NativeSharePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null

    companion object {
        // Package names for social media apps
        private const val WHATSAPP_PACKAGE = "com.whatsapp"
        private const val WHATSAPP_BUSINESS_PACKAGE = "com.whatsapp.w4b"
        private const val INSTAGRAM_PACKAGE = "com.instagram.android"
        private const val FACEBOOK_PACKAGE = "com.facebook.katana"
        private const val TWITTER_PACKAGE = "com.twitter.android"
        private const val TELEGRAM_PACKAGE = "org.telegram.messenger"
        private const val LINKEDIN_PACKAGE = "com.linkedin.android"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.shopled/native_share")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "share" -> {
                handleShare(call, result)
            }
            "shareFiles" -> {
                // Legacy support
                val filePaths = call.argument<List<String>>("filePaths")
                val text = call.argument<String>("text")
                
                if (filePaths == null || filePaths.isEmpty()) {
                    result.error("INVALID_ARGUMENTS", "filePaths cannot be null or empty", null)
                    return
                }
                
                shareFiles(filePaths, text, null, null, result)
            }
            "shareText" -> {
                val text = call.argument<String>("text")
                
                if (text == null) {
                    result.error("INVALID_ARGUMENTS", "text cannot be null", null)
                    return
                }
                
                shareText(text, null, result)
            }
            "canShareTo" -> {
                val platform = call.argument<String>("platform")
                result.success(canShareTo(platform))
            }
            else -> result.notImplemented()
        }
    }

    private fun handleShare(call: MethodCall, result: Result) {
        val filePaths = call.argument<List<String>>("filePaths")
        val text = call.argument<String>("text")
        val subject = call.argument<String>("subject")
        val platform = call.argument<String>("platform") ?: "system"
        val phoneNumber = call.argument<String>("phoneNumber")
        val emailAddresses = call.argument<List<String>>("emailAddresses")
        val mimeType = call.argument<String>("mimeType")

        android.util.Log.d("NativeShare", "handleShare: platform=$platform, text=$text, files=$filePaths")

        try {
            when (platform) {
                "whatsapp" -> shareToWhatsApp(filePaths, text, phoneNumber, false, result)
                "whatsappBusiness" -> shareToWhatsApp(filePaths, text, phoneNumber, true, result)
                "instagram" -> shareToInstagram(filePaths?.firstOrNull(), false, result)
                "instagramStories" -> shareToInstagram(filePaths?.firstOrNull(), true, result)
                "facebook" -> shareToFacebook(filePaths, text, result)
                "twitter" -> shareToTwitter(filePaths, text, result)
                "telegram" -> shareToTelegram(filePaths, text, result)
                "linkedin" -> shareToLinkedIn(filePaths, text, result)
                "email" -> shareViaEmail(filePaths, text, subject, emailAddresses, result)
                "sms" -> shareViaSMS(text, phoneNumber, result)
                else -> {
                    // System share
                    if (!filePaths.isNullOrEmpty()) {
                        shareFiles(filePaths, text, subject, mimeType, result)
                    } else if (!text.isNullOrEmpty()) {
                        shareText(text, subject, result)
                    } else {
                        android.util.Log.e("NativeShare", "Invalid arguments: neither filePaths nor text provided")
                        result.error("INVALID_ARGUMENTS", "Either filePaths or text must be provided", null)
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("NativeShare", "Error handling share", e)
            result.success(mapOf(
                "success" to false,
                "message" to (e.message ?: "Unknown error")
            ))
        }
    }

    private fun shareFiles(filePaths: List<String>, text: String?, subject: String?, mimeType: String?, result: Result) {
        android.util.Log.d("NativeShare", "shareFiles: paths=$filePaths")
        try {
            val ctx = context ?: run {
                android.util.Log.e("NativeShare", "Context is null")
                result.success(mapOf("success" to false, "message" to "Context is not available"))
                return
            }
            
            val act = activity ?: run {
                android.util.Log.e("NativeShare", "Activity is null")
                result.success(mapOf("success" to false, "message" to "Activity is not available"))
                return
            }   

            val uris = ArrayList<Uri>()
            
            for (path in filePaths) {
                val file = File(path)
                if (!file.exists()) {
                    result.success(mapOf("success" to false, "message" to "File not found: $path"))
                    return
                }
                
                val uri = FileProvider.getUriForFile(
                    ctx,
                    "${ctx.packageName}.fileprovider",
                    file
                )
                uris.add(uri)
            }

            val intent = if (uris.size == 1) {
                Intent(Intent.ACTION_SEND).apply {
                    putExtra(Intent.EXTRA_STREAM, uris[0])
                }
            } else {
                Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                    putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                }
            }

            intent.apply {
                type = mimeType ?: getMimeType(filePaths[0])
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                if (!text.isNullOrEmpty()) {
                    putExtra(Intent.EXTRA_TEXT, text)
                }
                if (!subject.isNullOrEmpty()) {
                    putExtra(Intent.EXTRA_SUBJECT, subject)
                }
            }

            val chooser = Intent.createChooser(intent, null)
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            act.startActivity(chooser)
            
            result.success(mapOf("success" to true, "message" to "Share dialog opened"))
        } catch (e: Exception) {
            result.success(mapOf("success" to false, "message" to (e.message ?: "Unknown error")))
        }
    }

    private fun shareText(text: String, subject: String?, result: Result) {
        try {
            val act = activity ?: run {
                result.success(mapOf("success" to false, "message" to "Activity is not available"))
                return
            }

            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                if (!subject.isNullOrEmpty()) {
                    putExtra(Intent.EXTRA_SUBJECT, subject)
                }
            }

            val chooser = Intent.createChooser(intent, null)
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            act.startActivity(chooser)
            
            result.success(mapOf("success" to true, "message" to "Share dialog opened"))
        } catch (e: Exception) {
            result.success(mapOf("success" to false, "message" to (e.message ?: "Unknown error")))
        }
    }

    private fun shareToWhatsApp(filePaths: List<String>?, text: String?, phoneNumber: String?, isBusiness: Boolean, result: Result) {
        try {
            val ctx = context ?: run {
                result.success(mapOf("success" to false, "message" to "Context not available"))
                return
            }
            
            val act = activity ?: run {
                result.success(mapOf("success" to false, "message" to "Activity not available"))
                return
            }

            val packageName = if (isBusiness) WHATSAPP_BUSINESS_PACKAGE else WHATSAPP_PACKAGE
            
            if (!isPackageInstalled(packageName)) {
                result.success(mapOf("success" to false, "message" to "WhatsApp is not installed"))
                return
            }

            val intent: Intent
            
            if (!phoneNumber.isNullOrEmpty() && filePaths.isNullOrEmpty()) {
                // Open WhatsApp chat with specific number (text only)
                val cleanNumber = phoneNumber.replace(Regex("[^0-9]"), "")
                val uri = Uri.parse("https://api.whatsapp.com/send?phone=$cleanNumber${if (!text.isNullOrEmpty()) "&text=${Uri.encode(text)}" else ""}")
                intent = Intent(Intent.ACTION_VIEW, uri)
            } else {
                // Share via intent
                intent = Intent(Intent.ACTION_SEND)
                intent.setPackage(packageName)
                
                if (!filePaths.isNullOrEmpty()) {
                    val file = File(filePaths[0])
                    val uri = FileProvider.getUriForFile(ctx, "${ctx.packageName}.fileprovider", file)
                    intent.putExtra(Intent.EXTRA_STREAM, uri)
                    intent.type = getMimeType(filePaths[0])
                    intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                } else {
                    intent.type = "text/plain"
                }
                
                if (!text.isNullOrEmpty()) {
                    intent.putExtra(Intent.EXTRA_TEXT, text)
                }
            }
            
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            act.startActivity(intent)
            
            result.success(mapOf("success" to true, "platform" to "whatsapp"))
        } catch (e: Exception) {
            result.success(mapOf("success" to false, "message" to (e.message ?: "Unknown error")))
        }
    }

    private fun shareToInstagram(filePath: String?, isStories: Boolean, result: Result) {
        try {
            val ctx = context ?: run {
                result.success(mapOf("success" to false, "message" to "Context not available"))
                return
            }
            
            val act = activity ?: run {
                result.success(mapOf("success" to false, "message" to "Activity not available"))
                return
            }

            if (!isPackageInstalled(INSTAGRAM_PACKAGE)) {
                result.success(mapOf("success" to false, "message" to "Instagram is not installed"))
                return
            }

            if (filePath.isNullOrEmpty()) {
                result.success(mapOf("success" to false, "message" to "File path required for Instagram"))
                return
            }

            val file = File(filePath)
            val uri = FileProvider.getUriForFile(ctx, "${ctx.packageName}.fileprovider", file)
            
            val intent = if (isStories) {
                Intent("com.instagram.share.ADD_TO_STORY").apply {
                    setDataAndType(uri, getMimeType(filePath))
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    setPackage(INSTAGRAM_PACKAGE)
                }
            } else {
                Intent(Intent.ACTION_SEND).apply {
                    type = getMimeType(filePath)
                    putExtra(Intent.EXTRA_STREAM, uri)
                    setPackage(INSTAGRAM_PACKAGE)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
            }
            
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            act.startActivity(intent)
            
            result.success(mapOf("success" to true, "platform" to "instagram"))
        } catch (e: Exception) {
            result.success(mapOf("success" to false, "message" to (e.message ?: "Unknown error")))
        }
    }

    private fun shareToFacebook(filePaths: List<String>?, text: String?, result: Result) {
        shareToPackage(FACEBOOK_PACKAGE, "facebook", filePaths, text, result)
    }

    private fun shareToTwitter(filePaths: List<String>?, text: String?, result: Result) {
        shareToPackage(TWITTER_PACKAGE, "twitter", filePaths, text, result)
    }

    private fun shareToTelegram(filePaths: List<String>?, text: String?, result: Result) {
        shareToPackage(TELEGRAM_PACKAGE, "telegram", filePaths, text, result)
    }

    private fun shareToLinkedIn(filePaths: List<String>?, text: String?, result: Result) {
        shareToPackage(LINKEDIN_PACKAGE, "linkedin", filePaths, text, result)
    }

    private fun shareToPackage(packageName: String, platformName: String, filePaths: List<String>?, text: String?, result: Result) {
        try {
            val ctx = context ?: run {
                result.success(mapOf("success" to false, "message" to "Context not available"))
                return
            }
            
            val act = activity ?: run {
                result.success(mapOf("success" to false, "message" to "Activity not available"))
                return
            }

            if (!isPackageInstalled(packageName)) {
                result.success(mapOf("success" to false, "message" to "$platformName is not installed"))
                return
            }

            val intent = Intent(Intent.ACTION_SEND)
            intent.setPackage(packageName)
            
            if (!filePaths.isNullOrEmpty()) {
                val file = File(filePaths[0])
                val uri = FileProvider.getUriForFile(ctx, "${ctx.packageName}.fileprovider", file)
                intent.putExtra(Intent.EXTRA_STREAM, uri)
                intent.type = getMimeType(filePaths[0])
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } else {
                intent.type = "text/plain"
            }
            
            if (!text.isNullOrEmpty()) {
                intent.putExtra(Intent.EXTRA_TEXT, text)
            }
            
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            act.startActivity(intent)
            
            result.success(mapOf("success" to true, "platform" to platformName))
        } catch (e: Exception) {
            result.success(mapOf("success" to false, "message" to (e.message ?: "Unknown error")))
        }
    }

    private fun shareViaEmail(filePaths: List<String>?, body: String?, subject: String?, recipients: List<String>?, result: Result) {
        try {
            val ctx = context ?: run {
                result.success(mapOf("success" to false, "message" to "Context not available"))
                return
            }
            
            val act = activity ?: run {
                result.success(mapOf("success" to false, "message" to "Activity not available"))
                return
            }

            val intent = Intent(Intent.ACTION_SEND_MULTIPLE)
            intent.type = "message/rfc822"
            
            if (!recipients.isNullOrEmpty()) {
                intent.putExtra(Intent.EXTRA_EMAIL, recipients.toTypedArray())
            }
            
            if (!subject.isNullOrEmpty()) {
                intent.putExtra(Intent.EXTRA_SUBJECT, subject)
            }
            
            if (!body.isNullOrEmpty()) {
                intent.putExtra(Intent.EXTRA_TEXT, body)
            }
            
            if (!filePaths.isNullOrEmpty()) {
                val uris = ArrayList<Uri>()
                for (path in filePaths) {
                    val file = File(path)
                    val uri = FileProvider.getUriForFile(ctx, "${ctx.packageName}.fileprovider", file)
                    uris.add(uri)
                }
                intent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            
            val chooser = Intent.createChooser(intent, "Send email via...")
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            act.startActivity(chooser)
            
            result.success(mapOf("success" to true, "platform" to "email"))
        } catch (e: Exception) {
            result.success(mapOf("success" to false, "message" to (e.message ?: "Unknown error")))
        }
    }

    private fun shareViaSMS(text: String?, phoneNumber: String?, result: Result) {
        try {
            val act = activity ?: run {
                result.success(mapOf("success" to false, "message" to "Activity not available"))
                return
            }

            val uri = if (!phoneNumber.isNullOrEmpty()) {
                Uri.parse("smsto:$phoneNumber")
            } else {
                Uri.parse("smsto:")
            }
            
            val intent = Intent(Intent.ACTION_SENDTO, uri)
            if (!text.isNullOrEmpty()) {
                intent.putExtra("sms_body", text)
            }
            
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            act.startActivity(intent)
            
            result.success(mapOf("success" to true, "platform" to "sms"))
        } catch (e: Exception) {
            result.success(mapOf("success" to false, "message" to (e.message ?: "Unknown error")))
        }
    }

    private fun canShareTo(platform: String?): Boolean {
        return when (platform) {
            "whatsapp" -> isPackageInstalled(WHATSAPP_PACKAGE)
            "whatsappBusiness" -> isPackageInstalled(WHATSAPP_BUSINESS_PACKAGE)
            "instagram", "instagramStories" -> isPackageInstalled(INSTAGRAM_PACKAGE)
            "facebook" -> isPackageInstalled(FACEBOOK_PACKAGE)
            "twitter" -> isPackageInstalled(TWITTER_PACKAGE)
            "telegram" -> isPackageInstalled(TELEGRAM_PACKAGE)
            "linkedin" -> isPackageInstalled(LINKEDIN_PACKAGE)
            "email", "sms", "system" -> true
            else -> true
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            context?.packageManager?.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun getMimeType(filePath: String): String {
        return when {
            filePath.endsWith(".pdf", ignoreCase = true) -> "application/pdf"
            filePath.endsWith(".png", ignoreCase = true) -> "image/png"
            filePath.endsWith(".jpg", ignoreCase = true) || 
            filePath.endsWith(".jpeg", ignoreCase = true) -> "image/jpeg"
            filePath.endsWith(".gif", ignoreCase = true) -> "image/gif"
            filePath.endsWith(".webp", ignoreCase = true) -> "image/webp"
            filePath.endsWith(".mp4", ignoreCase = true) -> "video/mp4"
            filePath.endsWith(".mov", ignoreCase = true) -> "video/quicktime"
            filePath.endsWith(".txt", ignoreCase = true) -> "text/plain"
            filePath.endsWith(".html", ignoreCase = true) -> "text/html"
            filePath.endsWith(".doc", ignoreCase = true) -> "application/msword"
            filePath.endsWith(".docx", ignoreCase = true) -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            filePath.endsWith(".xls", ignoreCase = true) -> "application/vnd.ms-excel"
            filePath.endsWith(".xlsx", ignoreCase = true) -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            filePath.endsWith(".zip", ignoreCase = true) -> "application/zip"
            else -> "*/*"
        }
    }
}
