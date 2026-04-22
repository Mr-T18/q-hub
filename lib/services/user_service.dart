import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ログイン時にプロフィールを同期
  Future<void> syncUserProfile(User user) async {
    final userRef = _db.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        'name': user.displayName ?? '名無しのクイズ師',
        'bio': 'よろしくお願いします！',
        'photoUrl': user.photoURL ?? '',
        'department': '情報工学科',
        'year': '5年',
        'title': '新人',
        'totalCreated': 0,
        'totalSolved': 0,
        'consecutiveDays': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<AppUser> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        // 見つからない場合にエラーを投げるか、特定のフラグを立てたAppUserを返す
        throw Exception('User not found');
      }
      return AppUser.fromFirestore(doc);
    });
  }

  // プロフィール更新
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }
}
