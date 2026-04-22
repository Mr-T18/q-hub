import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../services/database_service.dart';
import '../../../models/app_user.dart';
import '../../../models/quiz.dart';
import '../../widgets/quiz_card.dart';
import 'edit_profile_screen.dart';
import 'my_list_detail_screen.dart';
import '../../widgets/mark_list_button.dart';
import '../../../services/admin_state.dart';
import '../admin/user_management_screen.dart';

class MyPageScreen extends StatelessWidget {
  final String? targetUserId;
  final bool isMe;
  const MyPageScreen({super.key, this.targetUserId, this.isMe = true});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().userChanges,
      builder: (context, authSnapshot) {
        final bool isLoggedIn = authSnapshot.hasData;

        // 【修正】自分のページで未ログインの場合
        if (isMe && !isLoggedIn) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'マイページ',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 80,
                    color: Colors.black12,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ログインして「専Q」を楽しもう！',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 240,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => AuthService().signInWithGoogle(),
                      icon: const Icon(Icons.login),
                      label: const Text('Googleでサインイン'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // --- ログイン済み、または他人のプロフィールの場合は以前のロジックへ ---
        final String? uid = isMe ? authSnapshot.data?.uid : targetUserId;

        if (uid == null || uid.isEmpty) {
          return const Scaffold(body: Center(child: Text('ユーザー情報が読み込めません')));
        }

        // --- 3. Firestoreからユーザー詳細を取得 ---
        return StreamBuilder<AppUser>(
          stream: UserService().getUserStream(uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!userSnapshot.hasData) {
              return const Scaffold(body: Center(child: Text('ユーザーが見つかりません')));
            }
            return _MyPageBody(user: userSnapshot.data!, isMe: isMe);
          },
        );
      },
    );
  }
}

class _MyPageBody extends StatelessWidget {
  final AppUser user;
  final bool isMe; // 追加
  const _MyPageBody({required this.user, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          // 他人のページの場合は戻るボタンを表示
          leading: !isMe ? const BackButton(color: Colors.black) : null,
          title: Text(
            isMe ? 'マイページ' : '${user.name}のプロフィール',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (user.isAdmin) // ロールがadminの人だけに見える
              ValueListenableBuilder<bool>(
                valueListenable: AdminState().isModeEnabled,
                builder: (context, isEnabled, child) {
                  return TextButton.icon(
                    onPressed: () => AdminState().toggleMode(),
                    icon: Icon(
                      isEnabled
                          ? Icons.admin_panel_settings
                          : Icons.person_outline,
                      color: isEnabled ? Colors.red : Colors.grey,
                    ),
                    label: Text(
                      isEnabled ? '管理者モード中' : 'ユーザーモード',
                      style: TextStyle(
                        color: isEnabled ? Colors.red : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(
              child: ValueListenableBuilder<bool>(
                valueListenable: AdminState().isModeEnabled,
                builder: (context, isEnabled, child) {
                  // 「自分のページ」かつ「管理者モードがON」の時だけ表示
                  if (!isMe || !isEnabled) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: ListTile(
                      tileColor: Colors.orange[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: const Icon(Icons.people, color: Colors.orange),
                      title: const Text(
                        '部員権限の管理',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('管理者の追加・削除ができます'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserManagementScreen(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                const TabBar(
                  isScrollable: true,
                  labelColor: Color(0xFF1A237E),
                  unselectedLabelColor: Colors.black26,
                  indicatorColor: Color(0xFF1A237E),
                  tabs: [
                    Tab(text: '投稿済み'),
                    Tab(text: '履歴'),
                    Tab(text: '保存済み'),
                    Tab(text: 'マイリスト'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildPostedQuizzes(context),
              _buildHistoryList(),
              _buildBookmarks(),
              _buildMyLists(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(user.photoUrl),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _badge('${user.department} ${user.year}'),
                        const SizedBox(width: 8),
                        _badge(user.title, isSpecial: true),
                      ],
                    ),
                  ],
                ),
              ),
              // 自分の時だけ設定ボタンを表示
              if (isMe)
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(user: user),
                    ),
                  ),
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.black26,
                  ),
                ),
            ],
          ),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              user.bio,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostedQuizzes(BuildContext context) {
    return StreamBuilder<List<Quiz>>(
      stream: DatabaseService().getUserQuizzes(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ここでエラーが表示される場合は、コンソールの内容を教えてください
        if (snapshot.hasError) {
          return Center(child: Text('取得エラー: ${snapshot.error}'));
        }

        final quizzes = snapshot.data ?? [];
        if (quizzes.isEmpty) {
          return const Center(child: Text('まだ投稿がありません'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quizzes.length,
          itemBuilder: (context, index) =>
              ExpandableQuizCard(quiz: quizzes[index]),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().getPracticeHistory(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final history = snapshot.data ?? [];
        if (history.isEmpty) return const Center(child: Text('練習履歴がありません'));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: history.length,
          itemBuilder: (context, i) {
            final item = history[i];
            final quizId = item['quizId'] as String;
            final bool isCorrect = item['isCorrect'] ?? false;
            final timestamp = item['timestamp'] as Timestamp?;
            final dateStr = timestamp != null
                ? timestamp.toDate().toString().split('.')[0]
                : '';

            // 履歴の各項目に対して、最新のクイズデータを取得してカードを表示
            return FutureBuilder<Quiz?>(
              future: DatabaseService().getQuizById(quizId),
              builder: (context, quizSnapshot) {
                if (!quizSnapshot.hasData) return const SizedBox.shrink();
                final quiz = quizSnapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 履歴ステータス部分 ---
                    Padding(
                      padding: const EdgeInsets.only(left: 28, top: 16),
                      child: Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCorrect ? '正解' : '誤答',
                            style: TextStyle(
                              color: isCorrect ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black26,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // --- Home画面共通のクイズカード ---
                    ExpandableQuizCard(quiz: quiz),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTimelineTile({
    required BuildContext context,
    required bool isFirst,
    required bool isLast,
    required bool isCorrect,
    required String title,
    required String time,
    VoidCallback? onTap,
  }) {
    final color = isCorrect ? Colors.green : Colors.red;

    return InkWell(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // タイムラインのラインとインジケーター部分
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isFirst ? Colors.transparent : Colors.grey[300],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(
                      isCorrect ? Icons.check : Icons.close,
                      size: 16,
                      color: color,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isLast ? Colors.transparent : Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // コンテンツ部分
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isCorrect ? '正解' : '誤答',
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarks() {
    return StreamBuilder<List<String>>(
      stream: DatabaseService().getBookmarkIds(user.id),
      builder: (context, idSnapshot) {
        if (!idSnapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return StreamBuilder<List<Quiz>>(
          stream: DatabaseService().getQuizzesByIds(idSnapshot.data!),
          builder: (context, quizSnapshot) {
            if (quizSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = quizSnapshot.data ?? [];
            if (list.isEmpty) return const Center(child: Text('保存した問題はありません'));
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: list.length,
              itemBuilder: (c, i) => ExpandableQuizCard(quiz: list[i]),
            );
          },
        );
      },
    );
  }

  Widget _buildMyLists(BuildContext context) {
    // 【ガード】現在のページのユーザーIDが空、または初期化中の場合はクラッシュを防ぐ
    if (user.id == null || user.id.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      // 自分のページなら「マークしたリスト」を含むストリーム、他人なら「その人のリスト」のみ
      stream: isMe
          ? DatabaseService().getAllMyVisibleLists(user.id)
          : DatabaseService().getMyLists(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 万が一のエラーハンドリング（赤い画面を出さない）
        if (snapshot.hasError) {
          return Center(child: Text('読み込みエラーが発生しました'));
        }

        final lists = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 自分のページを見ている時だけ「作成ボタン」を表示
            if (isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: OutlinedButton.icon(
                  onPressed: () => _showCreateListDialog(context, user.id),
                  icon: const Icon(Icons.add),
                  label: const Text('新しいマイリストを作成'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            ...lists.map((l) {
              // そのリストの「実体の作者」のIDを取得
              // 自分のリストなら user.id、マークしたリストならデータ内の creatorId を使用
              final bool isMine = l['isMine'] ?? true;
              final String listCreatorId = isMine
                  ? user.id
                  : (l['creatorId'] ?? '');

              // 【超重要ガード】作者IDが空の場合は、その項目をスキップまたは警告表示にする
              // これで「A document path must be a non-empty string」を根絶します
              if (listCreatorId.isEmpty) {
                return const SizedBox.shrink();
              }

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),

                  // 左端：作成者のアイコン（listCreatorIdを使って取得）
                  leading: StreamBuilder<AppUser>(
                    stream: UserService().getUserStream(listCreatorId),
                    builder: (context, userSnap) {
                      final photoUrl = userSnap.data?.photoUrl;
                      return CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      );
                    },
                  ),

                  // タイトル：リスト名
                  title: Text(
                    l['title'] ?? '無題',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  // 字幕：作成者名 • 問題数
                  subtitle: StreamBuilder<AppUser>(
                    stream: UserService().getUserStream(listCreatorId),
                    builder: (context, userSnap) {
                      final name = userSnap.data?.name ?? '読み込み中...';
                      final count = (l['quizIds'] as List? ?? []).length;
                      return Text(
                        '$name • $count問',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      );
                    },
                  ),

                  // 右端：自分のページなら管理メニュー、他人のページならマークボタン（プラスボタン）
                  trailing: isMe
                      ? PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz),
                          onSelected: (value) {
                            if (value == 'rename') {
                              _showRenameListDialog(
                                context,
                                user.id,
                                l['id'],
                                l['title'] ?? '無題',
                              );
                            } else if (value == 'delete') {
                              _showDeleteConfirmDialog(
                                context,
                                user.id,
                                l['id'],
                              );
                            } else if (value == 'unmark') {
                              DatabaseService().toggleMarkList(
                                user.id,
                                listCreatorId,
                                l['id'],
                              );
                            }
                          },
                          itemBuilder: (context) => isMine
                              ? [
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 8),
                                        Text('名前を変更'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '削除',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]
                              : [
                                  const PopupMenuItem(
                                    value: 'unmark',
                                    child: Row(
                                      children: [
                                        Icon(Icons.bookmark_remove, size: 18),
                                        SizedBox(width: 8),
                                        Text('マークを解除'),
                                      ],
                                    ),
                                  ),
                                ],
                        )
                      : MarkListButton(
                          // 他人のページを見ている時
                          creatorId: listCreatorId,
                          listId: l['id'],
                        ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyListDetailScreen(
                        listData: {...l, 'creatorId': listCreatorId},
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // 自分のリストを完全に削除する確認
  void _showDeleteConfirmDialog(
    BuildContext context,
    String uid,
    String listId,
  ) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('マイリストを削除'),
        content: const Text('このリストと中身の登録情報を削除しますか？\n（クイズ自体は削除されません）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              DatabaseService().deleteMyList(uid, listId); // 実体を消す
              Navigator.pop(c);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ダイアログ系メソッド（引数などはそのまま維持）
  void _showCreateListDialog(BuildContext context, String uid) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しいマイリスト'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'リスト名を入力'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                DatabaseService().createMyList(
                  uid,
                  controller.text.trim(),
                  false,
                );
                Navigator.pop(context);
              }
            },
            child: const Text(
              '作成',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameListDialog(
    BuildContext context,
    String uid,
    String listId,
    String currentTitle,
  ) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('マイリスト名を変更'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                DatabaseService().updateMyListTitle(
                  uid,
                  listId,
                  controller.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text(
              '更新',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String t, {bool isSpecial = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: isSpecial ? Colors.orange[50] : Colors.indigo[50],
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 11,
        color: isSpecial ? Colors.orange[800] : Colors.indigo,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  _StickyTabBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate old) => false;
}
