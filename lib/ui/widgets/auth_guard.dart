import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../screens/main_navigation.dart';

class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().userChanges, // ログイン状態を監視
      builder: (context, snapshot) {
        // 接続中なら読み込み中を表示
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ログインしていればメインのナビゲーション（タイムライン等）へ
        if (snapshot.hasData) {
          return const MainNavigation();
        }

        // ログインしていなければログインを促す画面へ
        // （今はとりあえずマイページがあるメイン画面へ流してもOKです）
        return const MainNavigation();
      },
    );
  }
}
