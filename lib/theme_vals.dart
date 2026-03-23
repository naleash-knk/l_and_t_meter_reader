import 'package:flutter/material.dart';

class AppThemeTokens {
	static const Color darkBlue = Color(0xFF0B2A4A);
	static const Color lightBackground = Colors.white;
	static const Color darkBackground = Colors.black;
	static const String logoAssetPath = 'assets/icon/logo.png';
	static const String splashImageAssetPath = 'assets/icon/image.png';
}

ThemeData buildLightTheme() {
	final base = ThemeData(
		useMaterial3: true,
		brightness: Brightness.light,
		fontFamily: 'Inter',
		colorScheme: ColorScheme.fromSeed(
			seedColor: AppThemeTokens.darkBlue,
			brightness: Brightness.light,
		).copyWith(
			primary: AppThemeTokens.darkBlue,
			surface: AppThemeTokens.lightBackground,
		),
	);

	return base.copyWith(
		scaffoldBackgroundColor: AppThemeTokens.lightBackground,
		appBarTheme: const AppBarTheme(centerTitle: true),
		progressIndicatorTheme: const ProgressIndicatorThemeData(
			linearMinHeight: 6,
		),
	);
}

ThemeData buildDarkTheme() {
	final base = ThemeData(
		useMaterial3: true,
		brightness: Brightness.dark,
		fontFamily: 'Inter',
		colorScheme: ColorScheme.fromSeed(
			seedColor: AppThemeTokens.darkBlue,
			brightness: Brightness.dark,
		).copyWith(
			primary: AppThemeTokens.darkBlue,
			surface: AppThemeTokens.darkBackground,
		),
	);

	return base.copyWith(
		scaffoldBackgroundColor: AppThemeTokens.darkBackground,
		appBarTheme: const AppBarTheme(centerTitle: true),
		snackBarTheme: SnackBarThemeData(
			backgroundColor: Colors.white,
			contentTextStyle: base.textTheme.bodyMedium?.copyWith(
				color: Colors.black,
			),
		),
		filledButtonTheme: FilledButtonThemeData(
			style: FilledButton.styleFrom(
				foregroundColor: Colors.white,
			),
		),
		progressIndicatorTheme: const ProgressIndicatorThemeData(
			linearMinHeight: 6,
		),
	);
}

class AppCustomization extends ChangeNotifier {
	ThemeMode _themeMode = ThemeMode.system;
	double _indicatorHeight = 6;
	Duration _splashDuration = const Duration(seconds: 5);

	ThemeMode get themeMode => _themeMode;
	double get indicatorHeight => _indicatorHeight;
	Duration get splashDuration => _splashDuration;

	void setThemeMode(ThemeMode mode) {
		if (_themeMode == mode) return;
		_themeMode = mode;
		notifyListeners();
	}

	void setIndicatorHeight(double value) {
		final next = value.clamp(4.0, 12.0);
		if (_indicatorHeight == next) return;
		_indicatorHeight = next;
		notifyListeners();
	}

	void setSplashDurationSeconds(int seconds) {
		final nextSeconds = seconds.clamp(5, 8);
		final next = Duration(seconds: nextSeconds);
		if (_splashDuration == next) return;
		_splashDuration = next;
		notifyListeners();
	}
}
