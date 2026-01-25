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

  const SettingsState({this.hideSensitiveData = false});

  SettingsState copyWith({bool? hideSensitiveData}) {
    return SettingsState(
      hideSensitiveData: hideSensitiveData ?? this.hideSensitiveData,
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
    state = state.copyWith(hideSensitiveData: hide);
  }

  Future<void> toggleHideSensitiveData(bool value) async {
    state = state.copyWith(hideSensitiveData: value);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool('hide_sensitive_data', value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
