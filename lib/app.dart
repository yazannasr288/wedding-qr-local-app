import 'package:flutter/material.dart';

import 'features/dashboard/dashboard_screen.dart';

class WeddingQrApp extends StatelessWidget {
  const WeddingQrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'دعوات الزفاف',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8D6E63)),
        scaffoldBackgroundColor: const Color(0xFFFBF8F3),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
      ),
      locale: const Locale('ar'),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: DashboardScreen(),
      ),
    );
  }
}
