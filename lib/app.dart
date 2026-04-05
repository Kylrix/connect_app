import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/connect_store.dart';
import 'screens/connect_home_page.dart';

class ConnectApp extends StatelessWidget {
  const ConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConnectStore()..bootstrap(),
      child: Consumer<ConnectStore>(
        builder: (context, store, _) {
          final baseTheme = ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF59E0B),
              brightness: Brightness.dark,
              surface: const Color(0xFF161412),
            ),
          );

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Kylrix Connect',
            theme: baseTheme.copyWith(
              textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
              primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
              scaffoldBackgroundColor: const Color(0xFF0A0908),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF0A0908),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              cardTheme: const CardThemeData(
                color: Color(0xFF161412),
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  side: BorderSide(color: Color(0x14FFFFFF)),
                ),
              ),
            ),
            home: const ConnectHomePage(),
          );
        },
      ),
    );
  }
}
