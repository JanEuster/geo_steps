

import 'package:shared_preferences/shared_preferences.dart';

class PreferenceKey<T> {
  late String key;
  late T initialValue;
  PreferenceKey(this.key, this.initialValue);

  Future<void> set(T value, {SharedPreferences? prefs}) async {
    prefs ??= await SharedPreferences.getInstance(); // set prefs if not provided as argument
    switch (T) {
      case int: {
        await prefs.setInt(key, value as int);
        break;
      }
      case bool: {
        await prefs.setBool(key, value as bool);
        break;
      }
      case double: {
        await prefs.setDouble(key, value as double);
        break;
      }
      case String: {
        await prefs.setString(key, value as String);
        break;
      }
      case List<String>: {
        await prefs.setStringList(key, value as List<String>);
        break;
      }
    }
  }
  Future<T?> get({SharedPreferences? prefs}) async {
    prefs ??= await SharedPreferences.getInstance(); // set prefs if not provided as argument
    switch (T) {
      case int: {
        return prefs.getInt(key) as T?;
      }
      case bool: {
        return prefs.getBool(key) as T?;
      }
      case double: {
        return prefs.getDouble(key) as T?;
      }
      case String: {
        return prefs.getString(key) as T?;
      }
      case List<String>: {
        return prefs.getStringList(key) as T?;
      }
    }
  }
  Future<bool> setIfUnset({SharedPreferences? prefs}) async {
    prefs ??= await SharedPreferences.getInstance(); // set prefs if not provided as argument
    var value = await get(prefs: prefs);
    if (value == null) {
      set(initialValue, prefs: prefs);
      return true;
    }
    return false;
  }
  Future<void> remove({SharedPreferences? prefs}) async {
    prefs ??= await SharedPreferences.getInstance(); // set prefs if not provided as argument
    await prefs.remove(key);
  }
}

class AppSettings {
  PreferenceKey<bool> trackingLocation = PreferenceKey("trackingLocation", false);
  late List<PreferenceKey<dynamic>> _preferences;
  AppSettings() {
    _preferences = [trackingLocation];
  }

  Future<void> initialize() async {
    for (var i = 0; i < _preferences.length; i++) {
      var pref = _preferences[i];
      pref.setIfUnset();
    }
  }
}


