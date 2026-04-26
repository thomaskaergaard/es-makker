import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/setup_screen.dart';

void main() {
  runApp(const EsMakkerApp());
}

class EsMakkerApp extends StatelessWidget {
  const EsMakkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Es Makker',
      theme: buildAppTheme(),
      home: const SetupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
