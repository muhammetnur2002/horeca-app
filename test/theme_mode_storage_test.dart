import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/app/di.dart';

void main() {
  test('системная тема сохраняется отдельно от тёмной', () {
    expect(encodeThemeMode(ThemeMode.system), 'system');
    expect(encodeThemeMode(ThemeMode.light), 'light');
    expect(encodeThemeMode(ThemeMode.dark), 'dark');
    expect(decodeThemeMode('system'), ThemeMode.system);
    expect(decodeThemeMode('light'), ThemeMode.light);
    expect(decodeThemeMode('dark'), ThemeMode.dark);
    expect(decodeThemeMode(null), ThemeMode.system);
  });
}
