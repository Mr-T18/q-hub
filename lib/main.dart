import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'ui/screens/main_navigation.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ビルド時の引数 --dart-define=FLAVOR=prod を取得
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  await Firebase.initializeApp(
    options: flavor == 'prod'
        ? prod.DefaultFirebaseOptions.currentPlatform
        : dev.DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: SenQApp()));
}

class SenQApp extends StatelessWidget {
  const SenQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Q-HUB',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigation(),
    );
  }
}
