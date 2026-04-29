import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
