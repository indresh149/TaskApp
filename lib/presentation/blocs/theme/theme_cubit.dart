
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_state.dart';

const String _themePrefKey = 'appThemePreferenceBloc';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(ThemeMode.system)) {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themePrefKey);
    ThemeMode currentMode;
    if (themeString == 'light') {
      currentMode = ThemeMode.light;
    } else if (themeString == 'dark') {
      currentMode = ThemeMode.dark;
    } else {
      currentMode = ThemeMode.system; 
    }
    emit(ThemeState(currentMode));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state.themeMode == mode) return;
    emit(ThemeState(mode));

    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      await prefs.setString(_themePrefKey, 'light');
    } else if (mode == ThemeMode.dark) {
      await prefs.setString(_themePrefKey, 'dark');
    } else {
      await prefs.remove(_themePrefKey); 
    }
  }

  void toggleTheme(Brightness platformBrightness) {
   
    bool isCurrentlyDark;
    if (state.themeMode == ThemeMode.system) {
        isCurrentlyDark = platformBrightness == Brightness.dark;
    } else {
        isCurrentlyDark = state.themeMode == ThemeMode.dark;
    }

    if (isCurrentlyDark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}