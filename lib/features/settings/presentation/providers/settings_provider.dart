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
  final ThemeMode themeMode;

  const SettingsState({
    this.hideSensitiveData = false,
    this.themeMode = ThemeMode.system,
  });

  SettingsState copyWith({bool? hideSensitiveData, ThemeMode? themeMode}) {
    return SettingsState(
      hideSensitiveData: hideSensitiveData ?? this.hideSensitiveData,
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

    final themeString = prefs.getString('theme_mode') ?? 'system';
    ThemeMode mode;
    switch (themeString) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      default:
        mode = ThemeMode.system;
    }

    state = state.copyWith(hideSensitiveData: hide, themeMode: mode);
  }

  Future<void> toggleHideSensitiveData(bool value) async {
    state = state.copyWith(hideSensitiveData: value);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool('hide_sensitive_data', value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    String modeStr;
    switch (mode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      default:
        modeStr = 'system';
    }
    await prefs.setString('theme_mode', modeStr);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
