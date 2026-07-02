import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _kCompact = 'display_compact';

  static Future<bool> isCompact() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kCompact) ?? true;
  }

  static Future<void> setCompact(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCompact, value);
  }
}
