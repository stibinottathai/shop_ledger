import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notification service for scheduled stock and customer alerts.
/// This runs in a background isolate via AndroidAlarmManager.
class NotificationService {
  static const int morningAlarmId = 1;
  static const int eveningAlarmId = 2;

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

  /// Schedule alarms for 9 AM and 7 PM IST
  static Future<void> scheduleAlarms() async {
    final now = DateTime.now();

    // Calculate next 9 AM IST
    var morningTime = DateTime(now.year, now.month, now.day, 9, 0, 0);
    if (now.isAfter(morningTime)) {
      morningTime = morningTime.add(const Duration(days: 1));
    }

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
    final user = supabase.auth.currentUser;

    if (user == null) return; // Not logged in

    // Get settings
    final prefs = await SharedPreferences.getInstance();
    final lowStockThreshold = prefs.getDouble('low_stock_threshold') ?? 10.0;
    final maxCreditLimit = prefs.getDouble('max_credit_limit') ?? 5000.0;

    final alerts = <String>[];

    // Check inventory for low/out of stock
    try {
      final inventoryResponse = await supabase
          .from('items')
          .select('name, total_quantity')
          .eq('user_id', user.id);

      final items = inventoryResponse as List;
      int outOfStock = 0;
      int lowStock = 0;

      for (final item in items) {
        final qty = (item['total_quantity'] ?? 0).toDouble();
        if (qty <= 0) {
          outOfStock++;
        } else if (qty <= lowStockThreshold) {
          lowStock++;
        }
      }

      if (outOfStock > 0) {
        alerts.add('$outOfStock items out of stock');
      }
      if (lowStock > 0) {
        alerts.add('$lowStock items low on stock');
      }
    } catch (_) {
      // Ignore errors
    }

    // Check customers exceeding credit limit
    try {
      final customersResponse = await supabase
          .from('customers')
          .select('id, name, balance')
          .eq('user_id', user.id);

      final customers = customersResponse as List;
      int highDue = 0;

      for (final customer in customers) {
        final balance = (customer['balance'] ?? 0).toDouble();
        if (balance > maxCreditLimit) {
          highDue++;
        }
      }

      if (highDue > 0) {
        alerts.add('$highDue customers exceeded credit limit');
      }
    } catch (_) {
      // Ignore errors
    }

    // Show notification if there are alerts
    if (alerts.isNotEmpty) {
      await _showNotification('Shop Ledger Alert', alerts.join(', '));
    }
  }

  static Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'shop_ledger_alerts',
      'Shop Ledger Alerts',
      channelDescription: 'Alerts for low stock and customer credit limits',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(0, title, body, details);
  }
}
