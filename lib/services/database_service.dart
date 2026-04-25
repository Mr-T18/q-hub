import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz.dart';
import '../models/app_user.dart';
import 'auth_service.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // 1. クイズ基本操作 (投稿・編集・削除)
  // ==========================================

  // --- 1. クイズ投稿（カウントアップ付き） ---
  Future<void> addQuiz({
    required String qText,
    required String aText,
    required String explanation,
    required List<String> tags,
    required int difficulty,
    required String creatorId,
    required String creatorName,
    bool isPublic = true,
  }) async {
    // 投稿の保存
    await _db.collection('questions').add({
      'qText': qText,
      'aText': aText,
      'explanation': explanation,
      'tags': tags,
      'difficulty': difficulty,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'likeCount': 0,
      'likedBy': [],
      'isPublic': isPublic,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ユーザーの総作問数をインクリメント
    await _db.collection('users').doc(creatorId).update({
      'totalQuizCount': FieldValue.increment(1),
    });
  }

  // 保存関数（下書きフラグを復活）
  Future<void> saveQuiz({
    String? quizId,
    required Map<String, dynamic> data,
  }) async {
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (quizId != null) {
      await _db.collection('questions').doc(quizId).update(data);
    } else {
      data['createdAt'] = FieldValue.serverTimestamp();
      await _db.collection('questions').add(data);
    }
  }

  Future<void> updateQuiz(String quizId, Map<String, dynamic> data) async {
    await _db.collection('questions').doc(quizId).update(data);
  }

  Future<void> deleteQuiz(String quizId) async {
    await _db.collection('questions').doc(quizId).delete();
  }

  // ==========================================
  // 2. ユーザーアクション (いいね・保存・リスト)
  // ==========================================

  Future<void> toggleLike(String uid, String quizId) async {
    final quizRef = _db.collection('questions').doc(quizId);
    final doc = await quizRef.get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    List<String> likedBy = List<String>.from(data['likedBy'] ?? []);

    if (likedBy.contains(uid)) {
      likedBy.remove(uid);
      await quizRef.update({
        'likedBy': likedBy,
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      likedBy.add(uid);
      await quizRef.update({
        'likedBy': likedBy,
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> toggleBookmark(String uid, String quizId) async {
    final userRef = _db.collection('users').doc(uid);
    final doc = await userRef.get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    List<String> bookmarks = List<String>.from(data['bookmarks'] ?? []);

    if (bookmarks.contains(quizId)) {
      bookmarks.remove(quizId);
    } else {
      bookmarks.add(quizId);
    }
    await userRef.update({'bookmarks': bookmarks});
  }

  // --- 自分のマイリストを完全に削除 ---
  Future<void> deleteMyList(String uid, String listId) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('myLists')
          .doc(listId)
          .delete();
    } catch (e) {
      print('Error deleting list: $e');
      rethrow;
    }
  }

  // 【新規】マイリスト名の変更
  Future<void> updateMyListTitle(
    String uid,
    String listId,
    String newTitle,
  ) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('myLists')
        .doc(listId)
        .update({'title': newTitle});
  }

  // 既存の createMyList (再掲)
  Future<void> createMyList(String uid, String title, bool isPublic) async {
    await _db.collection('users').doc(uid).collection('myLists').add({
      'title': title,
      'isPublic': isPublic,
      'quizIds': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 指定したマイリストにクイズを追加
  Future<void> addQuizToList(String uid, String listId, String quizId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('myLists')
        .doc(listId)
        .update({
          'quizIds': FieldValue.arrayUnion([quizId]),
        });
  }

  // 【新規】指定したマイリストからクイズを削除
  Future<void> removeQuizFromList(
    String uid,
    String listId,
    String quizId,
  ) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('myLists')
        .doc(listId)
        .update({
          'quizIds': FieldValue.arrayRemove([quizId]),
        });
  }

  // --- 特定のリストをマークしているか監視する ---
  Stream<bool> isListMarked(String uid, String listId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('markedLists')
        .doc(listId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // --- 2. 練習履歴保存（カウントアップ付き） ---
  Future<void> savePracticeHistory(
    String uid,
    Quiz quiz,
    bool isCorrect,
  ) async {
    await _db.collection('users').doc(uid).collection('history').add({
      'quizId': quiz.id,
      'qText': quiz.qText,
      'isCorrect': isCorrect,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // ユーザーの練習回数をインクリメント
    await _db.collection('users').doc(uid).update({
      'practiceCount': FieldValue.increment(1),
    });
  }

  // --- マイリストをマーク（参照）する ---
  Future<void> toggleMarkList(
    String uid,
    String creatorId,
    String listId,
  ) async {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('markedLists')
        .doc(listId);
    final doc = await ref.get();

    if (doc.exists) {
      await ref.delete(); // すでにマーク済みなら解除
    } else {
      await ref.set({
        'originalCreatorId': creatorId,
        'markedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 自分のページで「マークしたリスト」も含めて取得する時
  Stream<List<Map<String, dynamic>>> getAllMyVisibleLists(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    final markedLists = _db
        .collection('users')
        .doc(uid)
        .collection('markedLists')
        .snapshots();

    return markedLists.asyncMap((markedSnap) async {
      List<Map<String, dynamic>> results = [];

      // 自分のリスト
      final mySnap = await _db
          .collection('users')
          .doc(uid)
          .collection('myLists')
          .get();
      for (var d in mySnap.docs) {
        results.add({
          ...d.data(),
          'id': d.id,
          'isMine': true,
          'creatorId': uid,
        }); // ★入れる
      }

      // マークしたリスト
      for (var d in markedSnap.docs) {
        final data = d.data();
        final String originalCreatorId = data['originalCreatorId'] ?? '';
        if (originalCreatorId.isEmpty) continue;

        final original = await _db
            .collection('users')
            .doc(originalCreatorId)
            .collection('myLists')
            .doc(d.id)
            .get();
        if (original.exists) {
          results.add({
            ...original.data()!,
            'id': original.id,
            'isMine': false,
            'creatorId': originalCreatorId, // ★入れる
          });
        }
      }
      return results;
    });
  }

  // ==========================================
  // 3. 取得・ストリーム系 (タイムライン・マイページ用)
  // ==========================================

  Stream<List<Quiz>> getRecentQuizzes() {
    return _db
        .collection('questions')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Quiz.fromFirestore(d)).toList());
  }

  // 【修正案の反映】無限ループ防止のため orderBy を追加
  Stream<List<Quiz>> getMyPostedQuizzes(String uid) {
    return _db
        .collection('questions')
        .where('creatorId', isEqualTo: uid)
        .where('isPublic', isEqualTo: true)
        // 一時的に orderBy('createdAt') を削除。
        // ※ orderBy を使う場合は Firebase Console で「複合インデックス」の作成が必要です。
        .snapshots()
        .map((s) => s.docs.map((d) => Quiz.fromFirestore(d)).toList());
  }

  Future<List<Quiz>> getMyDrafts(String uid) async {
    final s = await _db
        .collection('questions')
        .where('creatorId', isEqualTo: uid)
        .where('isPublic', isEqualTo: false)
        .get();
    return s.docs.map((d) => Quiz.fromFirestore(d)).toList();
  }

  Stream<List<Quiz>> getBookmarkedQuizzes(List<String> quizIds) {
    if (quizIds.isEmpty) return Stream.value([]);
    return _db
        .collection('questions')
        .where("isPublic", isEqualTo: true)
        .where(FieldPath.documentId, whereIn: quizIds.take(30).toList())
        .snapshots()
        .map((s) => s.docs.map((d) => Quiz.fromFirestore(d)).toList());
  }

  Future<Quiz?> getQuizById(String id) async {
    final doc = await _db.collection('questions').doc(id).get();
    if (doc.exists) {
      return Quiz.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<Quiz>> getQuizzesByIds(List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);
    return _db
        .collection('questions')
        .where(FieldPath.documentId, whereIn: ids.take(30).toList())
        .snapshots()
        .map((s) => s.docs.map((d) => Quiz.fromFirestore(d)).toList());
  }

  // --- タグ指定での取得（安定版） ---
  Stream<List<Quiz>> getQuizzesByTag(String tag) {
    return _db
        .collection('questions')
        .where('isPublic', isEqualTo: true)
        .where('tags', arrayContains: tag)
        // 修正：複合インデックス作成の手間を省くため、一旦 orderBy を削除
        .snapshots()
        .map((s) => s.docs.map((d) => Quiz.fromFirestore(d)).toList());
  }

  // --- 追加機能：履歴の取得 ---
  Stream<List<Map<String, dynamic>>> getPracticeHistory(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('history')
        .where("isPublic", isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  // ==========================================
  // 4. その他 (タグ・メタデータ)
  // ==========================================

  Future<List<String>> getAllTags() async {
    final snapshot = await _db
        .collection('questions')
        .where("isPublic", isEqualTo: true)
        .get();
    Set<String> allTags = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      List<dynamic> tags = data['tags'] ?? [];
      for (var tag in tags) {
        allTags.add(tag.toString());
      }
    }
    return allTags.toList();
  }

  Stream<List<String>> getBookmarkIds(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return List<String>.from(data?['bookmarks'] ?? []);
    });
  }

  // 他人のリストを取得する時
  Stream<List<Map<String, dynamic>>> getMyLists(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('myLists')
        .snapshots()
        .map((snap) {
          return snap.docs
              .map(
                (doc) => {
                  ...doc.data(),
                  'id': doc.id,
                  'isMine': true,
                  'creatorId': uid, // ★これを絶対に入れる
                },
              )
              .toList();
        });
  }

  Stream<List<Map<String, dynamic>>> getNotifications(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  // --- 3. 検索・ランキング用取得系 ---

  // 全ユーザー取得（作問者検索用）
  Stream<List<AppUser>> getAllUsers() {
    return _db
        .collection('users')
        .snapshots()
        .map((s) => s.docs.map((d) => AppUser.fromFirestore(d)).toList());
  }

  // ランキング取得（作問数順）
  Future<List<AppUser>> getTopCreators() async {
    final s = await _db
        .collection('users')
        .orderBy('totalQuizCount', descending: true)
        .limit(5)
        .get();
    return s.docs.map((d) => AppUser.fromFirestore(d)).toList();
  }

  // ランキング取得（練習数順）
  Future<List<AppUser>> getTopPractitioners() async {
    final s = await _db
        .collection('users')
        .orderBy('practiceCount', descending: true)
        .limit(5)
        .get();
    return s.docs.map((d) => AppUser.fromFirestore(d)).toList();
  }

  // キーワード検索用の全クイズ取得
  Stream<List<Quiz>> getAllQuizzesForSearch() {
    return _db
        .collection('questions')
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Quiz.fromFirestore(d)).toList());
  }

  // 公開・非公開のワンタップ切り替え
  Future<void> updateQuizVisibility({
    required String quizId,
    required bool newIsPublic,
  }) async {
    try {
      // 【重要】ここを 'questions' に統一してください
      await _db.collection('questions').doc(quizId).update({
        'isPublic': newIsPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Update Visibility Error: $e');
      rethrow;
    }
  }

  Stream<List<Quiz>> getQuizzes(String? myUid) {
    Query query = _db.collection('questions');

    if (myUid == null) {
      // 1. 未ログインの場合：公開問題のみ
      return query
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Quiz.fromFirestore(doc)).toList(),
          );
    }

    // 2. ログイン済みの場合：「公開されている」または「自分が作った」問題を統合して取得
    // ※このクエリを使用するには、Firestoreコンソールで複合インデックスの作成が必要になる場合があります
    return query
        .where(
          Filter.or(
            Filter('isPublic', isEqualTo: true),
            Filter('creatorId', isEqualTo: myUid),
          ),
        )
        .orderBy('createdAt', descending: true) // 新着順
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Quiz.fromFirestore(doc)).toList(),
        );
  }

  // my_page_screen.dart 内のクエリ部分を想定

  // タイムライン用
  Stream<List<Quiz>> getTimelineQuizzes() {
    return _db
        .collection('questions')
        .where("isPublic", isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((doc) => Quiz.fromFirestore(doc)).toList();
          // アプリ側で新着順にソート（インデックスエラーを回避）
          list.sort(
            (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
              a.createdAt ?? DateTime.now(),
            ),
          );
          return list;
        });
  }

  // マイページ用
  Stream<List<Quiz>> getUserQuizzes(String targetUserId) {
    return _db
        .collection('questions')
        .where('creatorId', isEqualTo: targetUserId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((doc) => Quiz.fromFirestore(doc)).toList();
          list.sort(
            (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
              a.createdAt ?? DateTime.now(),
            ),
          );
          return list;
        });
  }

  Future<List<Quiz>> getPracticeQuizzes({
    required String mode,
    List<String>? tags,
    List<String>? quizIds,
    int? difficulty, // ← 【ここを追加】
    bool shuffle = true,
  }) async {
    List<Quiz> results = [];

    if (mode == 'random') {
      // 1. クエリの初期化
      Query query = _db
          .collection('questions')
          .where("isPublic", isEqualTo: true);

      // 2. 難易度が指定されていれば絞り込みを追加
      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty);
      }

      // 3. データを取得
      final snap = await query.limit(50).get();
      results = snap.docs.map((doc) => Quiz.fromFirestore(doc)).toList();
    } else if (mode == 'tag') {
      // タグ指定モード（タグはいずれかを含むものを検索）
      final snap = await _db
          .collection('questions')
          .where('tags', arrayContainsAny: tags)
          .get();
      results = snap.docs.map((doc) => Quiz.fromFirestore(doc)).toList();

      // タグモードでも難易度絞り込みをしたい場合はここに where を追加できます
    } else if (mode == 'list') {
      // マイリストモード
      if (quizIds != null) {
        for (String id in quizIds) {
          final doc = await _db.collection('questions').doc(id).get();
          if (doc.exists) results.add(Quiz.fromFirestore(doc));
        }
      }
    }

    // シャッフル設定が true なら混ぜる
    if (shuffle) {
      results.shuffle();
    }

    return results;
  }

  // 難易度指定でのクイズ取得
  Stream<List<Quiz>> getQuizzesByDifficulty(int? level) {
    Query query = _db.collection('questions');
    if (level != null) {
      // 難易度で絞り込む
      query = query
          .where('difficulty', isEqualTo: level)
          .where("questions", isEqualTo: true);
    }
    return query.snapshots().map(
      (snap) => snap.docs.map((doc) => Quiz.fromFirestore(doc)).toList(),
    );
  }

  // ユーザーのロールを変更する
  Future<void> updateUserRole(String targetUid, String newRole) async {
    // もし管理者を辞めようとしている（roleを'user'にする）場合
    if (newRole == 'user') {
      // 現在の管理者の数をカウント
      final adminCount = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get()
          .then((snap) => snap.size);

      if (adminCount <= 1) {
        throw Exception('管理者が0人になるため、ロールを変更できません。');
      }
    }

    await _db.collection('users').doc(targetUid).update({'role': newRole});
  }

  Stream<List<AppUser>> getAllUsersStream() {
    return _db.collection('users').snapshots().map((snap) {
      return snap.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    });
  }
}
