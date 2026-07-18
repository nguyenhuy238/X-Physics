import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsStorage {
  SettingsStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _themeModeKey = 'theme_mode';

  final FlutterSecureStorage _storage;

  Future<ThemeMode> readThemeMode() async {
    final value = await _storage.read(key: _themeModeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    return _storage.write(key: _themeModeKey, value: value);
  }
}
