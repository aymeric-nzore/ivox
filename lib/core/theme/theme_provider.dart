import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ThemePreference { system, light, dark }

class ThemeProvider extends ChangeNotifier {
	ThemePreference _preference = ThemePreference.system;

	ThemePreference get preference => _preference;

	ThemeMode get themeMode {
		switch (_preference) {
			case ThemePreference.dark:
				return ThemeMode.dark;
			case ThemePreference.light:
				return ThemeMode.light;
			case ThemePreference.system:
				return ThemeMode.system;
		}
	}

	ThemeData get lightTheme => ThemeData(
				brightness: Brightness.light,
				colorScheme: ColorScheme.fromSeed(
					seedColor: Colors.amber,
					brightness: Brightness.light,
				),
				scaffoldBackgroundColor: Colors.white,
				appBarTheme: const AppBarTheme(
					backgroundColor: Colors.white,
					foregroundColor: Colors.black,
					elevation: 0,
					iconTheme: IconThemeData(color: Colors.black),
				),
				listTileTheme: const ListTileThemeData(
					iconColor: Colors.black87,
					textColor: Colors.black87,
				),
				iconTheme: const IconThemeData(color: Colors.black87),
				textTheme: GoogleFonts.poppinsTextTheme(),
				useMaterial3: true,
			);

	ThemeData get darkTheme => ThemeData(
				brightness: Brightness.dark,
				colorScheme: ColorScheme.fromSeed(
					seedColor: Colors.amber,
					brightness: Brightness.dark,
				),
				scaffoldBackgroundColor: const Color(0xFF0F1115),
				appBarTheme: const AppBarTheme(
					backgroundColor: Color(0xFF0F1115),
					foregroundColor: Colors.white,
					elevation: 0,
					iconTheme: IconThemeData(color: Colors.white),
				),
				listTileTheme: const ListTileThemeData(
					iconColor: Colors.white70,
					textColor: Colors.white70,
				),
				iconTheme: const IconThemeData(color: Colors.white70),
				textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
				useMaterial3: true,
			);

	void setThemePreference(ThemePreference value) {
		_preference = value;
		notifyListeners();
	}
}
