import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get userChanges => _auth.userChanges();

  Future<User?> signInWithGoogle() async {
    try {
      // 1. Google 認証プロバイダーを作成
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // 2. [Web用] Firebase Auth のポップアップを使用して直接サインイン
      // google_sign_in パッケージの UnimplementedError を回避できます
      final UserCredential userCredential = await _auth.signInWithPopup(
        googleProvider,
      );

      final User? user = userCredential.user;

      if (user != null) {
        // 3. Firestore プロフィール同期
        await UserService().syncUserProfile(user);
      }
      return user;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      // Firebase からサインアウトするだけで Web 版は完結します
      await _auth.signOut();
    } catch (e) {
      print("Sign-Out Error: $e");
    }
  }
}
