# Native Share

A Flutter plugin for native file and content sharing using method channels. Supports direct sharing to popular social media apps, email with attachments, SMS, and customizable share dialogs.

## Features

- 📤 **System Share Dialog** - Use the native iOS/Android share sheet
- 💬 **WhatsApp** - Share directly to WhatsApp or WhatsApp Business with optional phone number
- 📷 **Instagram** - Share to feed or Stories
- 🐦 **Twitter/X** - Post tweets directly
- 📘 **Facebook** - Share content to Facebook
- ✈️ **Telegram** - Share to Telegram chats
- 💼 **LinkedIn** - Share to LinkedIn
- 📧 **Email** - Compose emails with subject, body, recipients, and attachments
- 💬 **SMS** - Send text messages with optional phone number
- 🎯 **Platform Detection** - Check if apps are installed before sharing
- 📱 **iPad Support** - Customizable popover positioning

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  native_share:
    path: packages/native_share
```

### iOS Configuration

Add the following to your `ios/Runner/Info.plist` to enable URL scheme queries:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>whatsapp</string>
    <string>whatsapp-business</string>
    <string>instagram</string>
    <string>instagram-stories</string>
    <string>fb</string>
    <string>twitter</string>
    <string>tg</string>
    <string>linkedin</string>
</array>
```

### Android Configuration

The plugin automatically handles file sharing via `FileProvider`. Ensure your app's `AndroidManifest.xml` has the FileProvider configured (usually done by Flutter automatically).

## Usage

### Basic File Sharing

```dart
import 'package:native_share/native_share.dart';

// Simple file share
await NativeShare.shareFiles(
  filePaths: ['/path/to/document.pdf'],
  text: 'Check out this document!',
  subject: 'Important Document',
);
```

### Text Sharing

```dart
await NativeShare.shareText(
  text: 'Hello World!',
  subject: 'Greeting',
);
```

### Advanced Sharing with ShareParams

```dart
final result = await NativeShare.share(ShareParams(
  filePaths: ['/path/to/image.png'],
  text: 'Check this out!',
  subject: 'Cool Image',
  platform: SharePlatform.system,
));

if (result.success) {
  print('Shared via: ${result.platform}');
}
```

## Social Media Sharing

### WhatsApp

```dart
// Share to WhatsApp with phone number
await NativeShare.shareToWhatsApp(
  text: 'Hello from Flutter!',
  phoneNumber: '919876543210', // With country code
);

// Share file to WhatsApp
await NativeShare.shareToWhatsApp(
  filePath: '/path/to/image.jpg',
  text: 'Check this image!',
);
```

### Instagram

```dart
// Share to Instagram feed
await NativeShare.shareToInstagram(
  filePath: '/path/to/photo.jpg',
);

// Share to Instagram Stories
await NativeShare.shareToInstagram(
  filePath: '/path/to/story.jpg',
  toStories: true,
);
```

### Twitter/X

```dart
await NativeShare.shareToTwitter(
  text: 'Posting from my Flutter app! #Flutter',
);
```

### Telegram

```dart
await NativeShare.shareToTelegram(
  text: 'Hello from Flutter!',
  filePath: '/path/to/document.pdf',
);
```

### Facebook

```dart
await NativeShare.shareToFacebook(
  text: 'Check out my app!',
  filePath: '/path/to/image.jpg',
);
```

## Email Sharing

```dart
await NativeShare.shareViaEmail(
  body: 'Please find the report attached.',
  subject: 'Monthly Report',
  recipients: ['manager@company.com', 'team@company.com'],
  attachmentPaths: ['/path/to/report.pdf'],
);
```

## SMS Sharing

```dart
await NativeShare.shareViaSMS(
  text: 'Your OTP is 123456',
  phoneNumber: '+919876543210',
);
```

## Check Platform Availability

```dart
// Check if WhatsApp is installed
if (await NativeShare.canShareTo(SharePlatform.whatsapp)) {
  await NativeShare.shareToWhatsApp(text: 'Hello!');
} else {
  // Fall back to system share
  await NativeShare.shareText(text: 'Hello!');
}
```

## iPad Popover Position

Customize the share dialog position on iPad:

```dart
await NativeShare.share(ShareParams(
  text: 'Hello!',
  position: SharePosition(
    x: 100,
    y: 200,
    width: 50,
    height: 50,
    center: false,
  ),
));
```

## API Reference

### Classes

| Class | Description |
|-------|-------------|
| `NativeShare` | Main class with static methods for sharing |
| `ShareParams` | Configuration for share operations |
| `ShareResult` | Result of a share operation |
| `SharePosition` | iPad popover position configuration |
| `SharePlatform` | Enum of supported platforms |

### SharePlatform Enum

| Value | Description |
|-------|-------------|
| `system` | Native system share dialog |
| `whatsapp` | WhatsApp Messenger |
| `whatsappBusiness` | WhatsApp Business |
| `instagram` | Instagram feed |
| `instagramStories` | Instagram Stories |
| `facebook` | Facebook |
| `twitter` | Twitter/X |
| `telegram` | Telegram |
| `linkedin` | LinkedIn |
| `email` | Email client |
| `sms` | SMS/Messages |

### NativeShare Methods

| Method | Description |
|--------|-------------|
| `share(ShareParams)` | Full-featured share with all options |
| `shareFiles(...)` | Quick file sharing |
| `shareText(...)` | Quick text sharing |
| `shareToWhatsApp(...)` | Direct WhatsApp share |
| `shareToInstagram(...)` | Direct Instagram share |
| `shareToTwitter(...)` | Direct Twitter share |
| `shareToTelegram(...)` | Direct Telegram share |
| `shareToFacebook(...)` | Direct Facebook share |
| `shareViaEmail(...)` | Email with attachments |
| `shareViaSMS(...)` | SMS message |
| `canShareTo(SharePlatform)` | Check if platform is available |

## ShareParams Properties

| Property | Type | Description |
|----------|------|-------------|
| `filePaths` | `List<String>?` | File paths to share |
| `text` | `String?` | Text content |
| `subject` | `String?` | Email subject |
| `platform` | `SharePlatform` | Target platform |
| `phoneNumber` | `String?` | Phone for WhatsApp/SMS |
| `emailAddresses` | `List<String>?` | Email recipients |
| `position` | `SharePosition?` | iPad popover position |
| `mimeType` | `String?` | Custom MIME type |

## ShareResult Properties

| Property | Type | Description |
|----------|------|-------------|
| `success` | `bool` | Whether share succeeded |
| `message` | `String?` | Status/error message |
| `platform` | `String?` | Platform used for sharing |

## Platform Support

| Feature | Android | iOS |
|---------|---------|-----|
| System Share | ✅ | ✅ |
| WhatsApp | ✅ | ✅ |
| WhatsApp Business | ✅ | ✅ |
| Instagram | ✅ | ✅ |
| Instagram Stories | ✅ | ✅ |
| Twitter/X | ✅ | ✅ |
| Facebook | ✅ | ✅* |
| Telegram | ✅ | ✅ |
| LinkedIn | ✅ | ✅ |
| Email | ✅ | ✅ |
| SMS | ✅ | ✅ |
| Platform Detection | ✅ | ✅ |

*Note: Facebook on iOS may fall back to system share due to Facebook SDK requirements.

## Error Handling

```dart
final result = await NativeShare.share(ShareParams(
  text: 'Hello!',
  platform: SharePlatform.whatsapp,
));

if (!result.success) {
  print('Share failed: ${result.message}');
  // Handle error - maybe app not installed
}
```

## Migration from share_plus

Replace:
```dart
import 'package:share_plus/share_plus.dart';

await SharePlus.instance.share(ShareParams(
  files: [XFile(filePath)],
  text: 'Hello!',
));
```

With:
```dart
import 'package:native_share/native_share.dart';

await NativeShare.shareFiles(
  filePaths: [filePath],
  text: 'Hello!',
);
```

## License

MIT License - see [LICENSE](LICENSE) file.
