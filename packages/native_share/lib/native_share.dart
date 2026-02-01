import 'package:flutter/services.dart';

/// Enum representing supported social media platforms for direct sharing.
enum SharePlatform {
  /// Native system share dialog
  system,

  /// WhatsApp
  whatsapp,

  /// WhatsApp Business
  whatsappBusiness,

  /// Instagram
  instagram,

  /// Instagram Stories
  instagramStories,

  /// Facebook
  facebook,

  /// Twitter/X
  twitter,

  /// Telegram
  telegram,

  /// LinkedIn
  linkedin,

  /// Email
  email,

  /// SMS/Messages
  sms,
}

/// Configuration options for iPad popover presentation.
class SharePosition {
  /// X coordinate relative to the view
  final double? x;

  /// Y coordinate relative to the view
  final double? y;

  /// Width of the source rectangle
  final double? width;

  /// Height of the source rectangle
  final double? height;

  /// Whether to show at center of screen
  final bool center;

  const SharePosition({
    this.x,
    this.y,
    this.width,
    this.height,
    this.center = true,
  });

  Map<String, dynamic> toMap() {
    return {'x': x, 'y': y, 'width': width, 'height': height, 'center': center};
  }
}

/// Share parameters for customizing share behavior.
class ShareParams {
  /// List of file paths to share
  final List<String>? filePaths;

  /// Text content to share
  final String? text;

  /// Subject line (useful for emails)
  final String? subject;

  /// Target platform for direct sharing
  final SharePlatform platform;

  /// Phone number for WhatsApp/SMS (with country code, e.g., "919876543210")
  final String? phoneNumber;

  /// Email addresses for direct email sharing
  final List<String>? emailAddresses;

  /// Position for iPad popover
  final SharePosition? position;

  /// MIME type override (e.g., "image/png", "application/pdf")
  final String? mimeType;

  const ShareParams({
    this.filePaths,
    this.text,
    this.subject,
    this.platform = SharePlatform.system,
    this.phoneNumber,
    this.emailAddresses,
    this.position,
    this.mimeType,
  });

  Map<String, dynamic> toMap() {
    return {
      'filePaths': filePaths,
      'text': text,
      'subject': subject,
      'platform': platform.name,
      'phoneNumber': phoneNumber,
      'emailAddresses': emailAddresses,
      'position': position?.toMap(),
      'mimeType': mimeType,
    };
  }
}

/// Share result containing information about the share action.
class ShareResult {
  /// Whether the share was successful
  final bool success;

  /// Status message
  final String? message;

  /// The platform that was used for sharing (if known)
  final String? platform;

  const ShareResult({required this.success, this.message, this.platform});

  factory ShareResult.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const ShareResult(success: false, message: 'No result received');
    }
    return ShareResult(
      success: map['success'] as bool? ?? false,
      message: map['message'] as String?,
      platform: map['platform'] as String?,
    );
  }
}

/// A Flutter plugin for native file and content sharing using method channels.
///
/// Supports:
/// - General system share dialog
/// - Direct sharing to specific social media apps
/// - File and text sharing
/// - Email with subject lines
/// - WhatsApp with phone number
/// - iPad popover position customization
class NativeShare {
  static const MethodChannel _channel = MethodChannel(
    'com.shopled/native_share',
  );

  /// Shares content using the specified parameters.
  ///
  /// This is the main entry point for all sharing functionality.
  ///
  /// Example - Simple file share:
  /// ```dart
  /// await NativeShare.share(ShareParams(
  ///   filePaths: ['/path/to/file.pdf'],
  ///   text: 'Check out this document!',
  /// ));
  /// ```
  ///
  /// Example - WhatsApp share with phone number:
  /// ```dart
  /// await NativeShare.share(ShareParams(
  ///   text: 'Hello!',
  ///   platform: SharePlatform.whatsapp,
  ///   phoneNumber: '919876543210',
  /// ));
  /// ```
  ///
  /// Example - Email with subject:
  /// ```dart
  /// await NativeShare.share(ShareParams(
  ///   text: 'Email body content',
  ///   subject: 'Email Subject',
  ///   platform: SharePlatform.email,
  ///   emailAddresses: ['recipient@example.com'],
  /// ));
  /// ```
  static Future<ShareResult> share(ShareParams params) async {
    try {
      print(
        'NativeShare: share() called with platform: ${params.platform}, text: ${params.text}, files: ${params.filePaths}',
      );

      final Map? invocationResult;
      invocationResult = await _channel.invokeMethod<Map>(
        'share',
        params.toMap(),
      );

      print('NativeShare: share() result: $invocationResult');
      return ShareResult.fromMap(invocationResult);
    } catch (e, stack) {
      print('NativeShare: share() error: $e');
      print('NativeShare: share() stack: $stack');
      return ShareResult(success: false, message: e.toString());
    }
  }

  /// Shares files using the native share dialog.
  ///
  /// This is a convenience method for simple file sharing.
  /// For more options, use [share] with [ShareParams].
  ///
  /// [filePaths] - List of absolute file paths to share.
  /// [text] - Optional text to include with the share.
  /// [subject] - Optional subject line (useful for emails).
  ///
  /// Returns `true` if the share dialog was successfully presented.
  static Future<bool> shareFiles({
    required List<String> filePaths,
    String? text,
    String? subject,
  }) async {
    print('NativeShare: shareFiles() called with paths: $filePaths');
    final shareResult = await share(
      ShareParams(filePaths: filePaths, text: text, subject: subject),
    );
    return shareResult.success;
  }

  /// Shares text content using the native share dialog.
  ///
  /// [text] - The text content to share.
  /// [subject] - Optional subject line.
  ///
  /// Returns `true` if the share dialog was successfully presented.
  static Future<bool> shareText({required String text, String? subject}) async {
    final result = await share(ShareParams(text: text, subject: subject));
    return result.success;
  }

  /// Shares content directly to WhatsApp.
  ///
  /// [text] - Message text to share.
  /// [phoneNumber] - Phone number with country code (e.g., "919876543210").
  /// [filePath] - Optional file path to share.
  ///
  /// Note: If phone number is provided, it will open chat with that contact.
  static Future<ShareResult> shareToWhatsApp({
    String? text,
    String? phoneNumber,
    String? filePath,
  }) async {
    return share(
      ShareParams(
        text: text,
        filePaths: filePath != null ? [filePath] : null,
        platform: SharePlatform.whatsapp,
        phoneNumber: phoneNumber,
      ),
    );
  }

  /// Shares content to Instagram.
  ///
  /// [filePath] - Path to image or video file.
  /// [toStories] - If true, shares to Instagram Stories.
  static Future<ShareResult> shareToInstagram({
    required String filePath,
    bool toStories = false,
  }) async {
    return share(
      ShareParams(
        filePaths: [filePath],
        platform: toStories
            ? SharePlatform.instagramStories
            : SharePlatform.instagram,
      ),
    );
  }

  /// Shares content via email.
  ///
  /// [body] - Email body content.
  /// [subject] - Email subject line.
  /// [recipients] - List of email addresses.
  /// [attachmentPaths] - Optional list of file paths to attach.
  static Future<ShareResult> shareViaEmail({
    required String body,
    String? subject,
    List<String>? recipients,
    List<String>? attachmentPaths,
  }) async {
    return share(
      ShareParams(
        text: body,
        subject: subject,
        emailAddresses: recipients,
        filePaths: attachmentPaths,
        platform: SharePlatform.email,
      ),
    );
  }

  /// Shares content via SMS/Messages.
  ///
  /// [text] - Message text.
  /// [phoneNumber] - Optional phone number to send to.
  static Future<ShareResult> shareViaSMS({
    required String text,
    String? phoneNumber,
  }) async {
    return share(
      ShareParams(
        text: text,
        phoneNumber: phoneNumber,
        platform: SharePlatform.sms,
      ),
    );
  }

  /// Shares content to Telegram.
  ///
  /// [text] - Message text.
  /// [filePath] - Optional file to share.
  static Future<ShareResult> shareToTelegram({
    String? text,
    String? filePath,
  }) async {
    return share(
      ShareParams(
        text: text,
        filePaths: filePath != null ? [filePath] : null,
        platform: SharePlatform.telegram,
      ),
    );
  }

  /// Shares content to Twitter/X.
  ///
  /// [text] - Tweet content.
  /// [filePath] - Optional image/video to attach.
  static Future<ShareResult> shareToTwitter({
    String? text,
    String? filePath,
  }) async {
    return share(
      ShareParams(
        text: text,
        filePaths: filePath != null ? [filePath] : null,
        platform: SharePlatform.twitter,
      ),
    );
  }

  /// Shares content to Facebook.
  ///
  /// [text] - Post content.
  /// [filePath] - Optional image/video to share.
  static Future<ShareResult> shareToFacebook({
    String? text,
    String? filePath,
  }) async {
    return share(
      ShareParams(
        text: text,
        filePaths: filePath != null ? [filePath] : null,
        platform: SharePlatform.facebook,
      ),
    );
  }

  /// Checks if a specific platform app is installed.
  ///
  /// Returns `true` if the app is available for sharing.
  static Future<bool> canShareTo(SharePlatform platform) async {
    try {
      final result = await _channel.invokeMethod<bool>('canShareTo', {
        'platform': platform.name,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
