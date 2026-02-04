import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';

/// Notification service for scheduled stock and customer alerts.
/// This runs in a background isolate via AndroidAlarmManager.
class NotificationService {
  static const int morningAlarmId = 1;
  static const int afternoonAlarmId = 2;
  static const int eveningAlarmId = 3;

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification plugin
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  /// Request notification permissions (required for Android 13+)
  static Future<bool> requestPermissions() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      // Request permission for Android 13+ (API 33+)
      final granted = await androidImplementation
          .requestNotificationsPermission();
      return granted ?? false;
    }
    return true; // For older Android versions, permission is granted at install
  }

  /// Schedule alarms for 9 AM, 3:15 PM, and 7 PM IST
  static Future<void> scheduleAlarms() async {
    final now = DateTime.now();

    // Calculate next 9 AM IST
    var morningTime = DateTime(now.year, now.month, now.day, 9, 0, 0);
    if (now.isAfter(morningTime)) {
      morningTime = morningTime.add(const Duration(days: 1));
    }

    // TESTING: Trigger 2 minutes after login - COMMENT OUT AFTER TESTING
    var afternoonTime = now.add(const Duration(minutes: 2));
    // Production code (uncomment after testing):
    // var afternoonTime = DateTime(now.year, now.month, now.day, 15, 15, 0);
    // if (now.isAfter(afternoonTime)) {
    //   afternoonTime = afternoonTime.add(const Duration(days: 1));
    // }

    // Calculate next 7 PM (19:00) IST
    var eveningTime = DateTime(now.year, now.month, now.day, 19, 0, 0);
    if (now.isAfter(eveningTime)) {
      eveningTime = eveningTime.add(const Duration(days: 1));
    }

    // Schedule morning alarm (9 AM) - repeating daily
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      morningAlarmId,
      checkAndNotify,
      startAt: morningTime,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    // Schedule afternoon alarm - using oneShot for testing (more reliable)
    // TESTING: Using oneShot for 2-minute test - CHANGE BACK TO PERIODIC AFTER TESTING
    await AndroidAlarmManager.oneShot(
      const Duration(minutes: 2),
      afternoonAlarmId,
      checkAndNotify,
      exact: true,
      wakeup: true,
      alarmClock: true, // Uses AlarmClock API for highest priority
    );

    // Schedule evening alarm (7 PM) - repeating daily
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      eveningAlarmId,
      checkAndNotify,
      startAt: eveningTime,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  /// Background callback that checks for alerts and shows notifications.
  /// This function must be a top-level function or static method.
  @pragma('vm:entry-point')
  static Future<void> checkAndNotify() async {
    // Initialize Flutter bindings for background isolate
    DartPluginRegistrant.ensureInitialized();

    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://sdcibdhdkbwdzmuzqtwu.supabase.co',
      anonKey: 'sb_publishable_0BoS3JOgkmBr-SQcV6cxQw_0sBKe4VY',
    );

    // Initialize notifications
    await initialize();

    final supabase = Supabase.instance.client;

    // Get user ID from SharedPreferences instead of auth.currentUser
    // This is necessary because background isolates don't have access to auth state
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) return; // Not logged in
    final lowStockThreshold = prefs.getDouble('low_stock_threshold') ?? 10.0;
    final maxCreditLimit = prefs.getDouble('max_credit_limit') ?? 5000.0;

    // Initialize lists to store alert details
    final outOfStockItems = <String>[];
    final lowStockItems = <String>[];
    final highDueCustomers = <String>[];

    try {
      final inventoryResponse = await supabase
          .from('items')
          .select('name, total_quantity, unit, low_stock_threshold')
          .eq('user_id', userId);

      final items = inventoryResponse as List;

      for (final item in items) {
        final qty = (item['total_quantity'] ?? 0).toDouble();
        final name = item['name'] as String;
        // Use item-specific threshold if set, otherwise use global default
        final threshold =
            (item['low_stock_threshold'] as num?)?.toDouble() ??
            lowStockThreshold;

        if (qty <= 0) {
          outOfStockItems.add(name);
        } else if (qty <= threshold) {
          lowStockItems.add('$name ($qty left)');
        }
      }
    } catch (_) {
      // Ignore errors
    }

    // Check customers exceeding credit limit
    try {
      final customersResponse = await supabase
          .from('customers')
          .select('id, name, balance')
          .eq('user_id', userId);

      final customers = customersResponse as List;

      for (final customer in customers) {
        final balance = (customer['balance'] ?? 0).toDouble();
        if (balance > maxCreditLimit) {
          highDueCustomers.add(customer['name'] as String);
        }
      }
    } catch (_) {
      // Ignore errors
    }

    // Construct Notification Content
    if (outOfStockItems.isNotEmpty ||
        lowStockItems.isNotEmpty ||
        highDueCustomers.isNotEmpty) {
      final sb = StringBuffer();

      if (outOfStockItems.isNotEmpty) {
        sb.writeln('🔴 Out of Stock: ${outOfStockItems.length}');
        sb.writeln(outOfStockItems.take(3).map((e) => '• $e').join('\n'));
        if (outOfStockItems.length > 3) {
          sb.writeln('• and ${outOfStockItems.length - 3} more...');
        }
        sb.writeln();
      }

      if (lowStockItems.isNotEmpty) {
        sb.writeln('⚠️ Low Stock: ${lowStockItems.length}');
        sb.writeln(lowStockItems.take(3).map((e) => '• $e').join('\n'));
        if (lowStockItems.length > 3) {
          sb.writeln('• and ${lowStockItems.length - 3} more...');
        }
        sb.writeln();
      }

      if (highDueCustomers.isNotEmpty) {
        sb.writeln('📉 Credit Limit Exceeded: ${highDueCustomers.length}');
        sb.writeln(highDueCustomers.take(3).map((e) => '• $e').join('\n'));
        if (highDueCustomers.length > 3) {
          sb.writeln('• and ${highDueCustomers.length - 3} more...');
        }
      }

      // Summary for collapsed view
      final summaryParts = <String>[];
      if (outOfStockItems.isNotEmpty) {
        summaryParts.add('${outOfStockItems.length} out of stock');
      }
      if (lowStockItems.isNotEmpty) {
        summaryParts.add('${lowStockItems.length} low stock');
      }
      if (highDueCustomers.isNotEmpty) {
        summaryParts.add('${highDueCustomers.length} credit alert');
      }

      await _showNotification(
        'Inventory & Credit Alert',
        summaryParts.join(' • '),
        bodyDetail: sb.toString().trim(),
      );
    } else {
      // TESTING: Always show notification for testing - COMMENT OUT AFTER TESTING
      await _showNotification(
        'Shop Ledger - Auto Test',
        'Background alarm triggered at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ✓',
        bodyDetail:
            'This automatic notification confirms the alarm system is working!\n\n✅ No inventory issues\n✅ No credit limit issues',
      );
    }
  }

  static Future<void> _showNotification(
    String title,
    String body, {
    String? bodyDetail,
  }) async {
    final styleInformation = bodyDetail != null
        ? BigTextStyleInformation(
            bodyDetail,
            contentTitle: '<b>$title</b>',
            htmlFormatContentTitle: true,
            summaryText: body,
          )
        : null;

    final androidDetails = AndroidNotificationDetails(
      'shop_ledger_alerts',
      'Shop Ledger Alerts',
      channelDescription: 'Alerts for low stock and customer credit limits',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      color: AppColors.primary,
      styleInformation: styleInformation,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(0, title, body, details);
  }
}
