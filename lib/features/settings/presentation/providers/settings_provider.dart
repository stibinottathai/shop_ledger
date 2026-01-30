import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for SharedPreferences instance (Future)
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

// Settings State
class SettingsState {
  final bool hideSensitiveData;
  final double maxCreditLimit;
  final ThemeMode themeMode;

  const SettingsState({
    this.hideSensitiveData = false,
    this.maxCreditLimit = 5000.0,
    this.themeMode = ThemeMode.system,
  });

  SettingsState copyWith({
    bool? hideSensitiveData,
    double? maxCreditLimit,
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      hideSensitiveData: hideSensitiveData ?? this.hideSensitiveData,
      maxCreditLimit: maxCreditLimit ?? this.maxCreditLimit,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

// Settings Notifier using Notifier (Riverpod 2.0)
class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadSettings();
    return const SettingsState();
  }

  Future<void> _loadSettings() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final hide = prefs.getBool('hide_sensitive_data') ?? false;
    final limit = prefs.getDouble('max_credit_limit') ?? 5000.0;

    final themeIndex =
        prefs.getInt('theme_mode') ?? 0; // 0: system, 1: light, 2: dark
    final themeMode = ThemeMode.values.length > themeIndex
        ? ThemeMode.values[themeIndex]
        : ThemeMode.system;

    state = state.copyWith(
      hideSensitiveData: hide,
      maxCreditLimit: limit,
      themeMode: themeMode,
    );
  }

  Future<void> toggleHideSensitiveData(bool value) async {
    state = state.copyWith(hideSensitiveData: value);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool('hide_sensitive_data', value);
  }

  Future<void> updateMaxCreditLimit(double value) async {
    state = state.copyWith(maxCreditLimit: value);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setDouble('max_credit_limit', value);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setInt('theme_mode', mode.index);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
