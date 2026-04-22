import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/quiz.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../screens/create/create_quiz_screen.dart';
import '../../../services/user_service.dart';
import '../../../models/app_user.dart';
import '../screens/mypage/my_page_screen.dart';
import '../../services/admin_state.dart';

class ExpandableQuizCard extends StatefulWidget {
  final Quiz quiz;
  const ExpandableQuizCard({super.key, required this.quiz});

  @override
  State<ExpandableQuizCard> createState() => _ExpandableQuizCardState();
}

class _ExpandableQuizCardState extends State<ExpandableQuizCard> {
  bool _isExpanded = false;

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('問題を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              DatabaseService().deleteQuiz(widget.quiz.id);
              Navigator.pop(c);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('questions')
          .doc(widget.quiz.id)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final likedBy = List<String>.from(data?['likedBy'] ?? []);
        final likeCount = data?['likeCount'] ?? 0;
        final isLiked = user != null && likedBy.contains(user.uid);
        final bool isMine = user?.uid == widget.quiz.creatorId;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _difficultyStars(widget.quiz.difficulty),
                      const Spacer(),
                      // 作問者情報の表示
                      StreamBuilder<AppUser>(
                        stream: UserService().getUserStream(
                          widget.quiz.creatorId,
                        ),
                        builder: (context, userSnapshot) {
                          // 1. ロード中
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }

                          // 2. データがない、またはエラー（ここで「詠み人知らず」を返す）
                          if (!userSnapshot.hasData || userSnapshot.hasError) {
                            return _buildUnknownCreator();
                          }

                          final creator = userSnapshot.data!;

                          return GestureDetector(
                            onTap: () {
                              // 名前をタップしたらプロフィールへ
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MyPageScreen(
                                    targetUserId: creator.id,
                                    isMe:
                                        AuthService().currentUser?.uid ==
                                        creator.id,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  creator.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // // 自分の投稿なら編集メニューを表示
                      // if (AuthService().currentUser?.uid ==
                      //     widget.quiz.creatorId)
                      //   _editMenu(context),
                      ValueListenableBuilder<bool>(
                        valueListenable: AdminState().isModeEnabled,
                        builder: (context, isAdminMode, child) {
                          final bool isMyQuiz =
                              AuthService().currentUser?.uid ==
                              widget.quiz.creatorId;

                          // 自分の投稿、または「管理者モードがON」ならメニューを表示
                          if (isMyQuiz || isAdminMode) {
                            return _editMenu(context, isAdminMode);
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.quiz.qText,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isExpanded) _expandedArea(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          children: widget.quiz.tags
                              .map((t) => _tagChip(t))
                              .toList(),
                        ),
                      ),
                      if (user != null) _actions(user.uid, isLiked, likeCount),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _editMenu(BuildContext context, bool isAdminMode) {
    return PopupMenuButton(
      // 管理者モード中はアイコンの色を変えて「神モード」を意識させる
      icon: Icon(
        Icons.more_horiz,
        color: isAdminMode ? Colors.red : Colors.black26,
      ),
      onSelected: (v) {
        if (v == 'e') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateQuizScreen(quizToEdit: widget.quiz),
            ),
          );
        } else if (v == 'd') {
          _handleDelete();
        }
      },
      itemBuilder: (c) => [
        const PopupMenuItem(value: 'e', child: Text('編集')),
        const PopupMenuItem(
          value: 'd',
          child: Text('削除', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildUnknownCreator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('詠み人知らず', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _expandedArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          '【答え】',
          style: TextStyle(
            fontSize: 12,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          widget.quiz.aText,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.quiz.explanation,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _actions(String uid, bool isLiked, int likeCount) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: Colors.red,
            size: 22,
          ),
          onPressed: () => DatabaseService().toggleLike(uid, widget.quiz.id),
        ),
        Text(
          '$likeCount',
          style: const TextStyle(fontSize: 12, color: Colors.black38),
        ),
        const SizedBox(width: 4),
        StreamBuilder<List<String>>(
          stream: DatabaseService().getBookmarkIds(uid),
          builder: (context, snapshot) {
            final isSaved = snapshot.data?.contains(widget.quiz.id) ?? false;
            return IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.blue,
                size: 22,
              ),
              onPressed: () =>
                  DatabaseService().toggleBookmark(uid, widget.quiz.id),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.playlist_add, color: Colors.green, size: 22),
          onPressed: () => _showMyListPicker(context, uid, widget.quiz.id),
        ),
      ],
    );
  }

  // --- 共通のマイリストピッカー ---
  void _showMyListPicker(BuildContext context, String uid, String quizId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService().getMyLists(uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final lists = snapshot.data!;
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'マイリストに追加/削除',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.indigo,
                    ),
                    title: const Text(
                      '新しいリストを作成',
                      style: TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => _showCreateListDialog(context, uid),
                  ),
                  const Divider(),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: lists.length,
                      itemBuilder: (context, index) {
                        final list = lists[index];
                        final listId = list['id'] as String;
                        final List quizIdsInList = list['quizIds'] ?? [];
                        final bool isAlreadyInList = quizIdsInList.contains(
                          quizId,
                        );
                        return CheckboxListTile(
                          activeColor: Colors.green,
                          secondary: const Icon(
                            Icons.folder,
                            color: Colors.green,
                          ),
                          title: Text(list['title'] ?? '無題'),
                          value: isAlreadyInList,
                          onChanged: (bool? value) {
                            if (value == true) {
                              DatabaseService().addQuizToList(
                                uid,
                                listId,
                                quizId,
                              );
                            } else {
                              DatabaseService().removeQuizFromList(
                                uid,
                                listId,
                                quizId,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
              if (controller.text.isNotEmpty) {
                DatabaseService().createMyList(uid, controller.text, false);
                Navigator.pop(context);
              }
            },
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      color: Colors.indigo[50],
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      '#$t',
      style: const TextStyle(fontSize: 11, color: Colors.indigo),
    ),
  );

  Widget _difficultyStars(int level) => Row(
    children: List.generate(
      5,
      (i) => Icon(
        Icons.star,
        size: 14,
        color: i < level ? Colors.orange : Colors.grey[200],
      ),
    ),
  );

  // Widget _editMenu(BuildContext context) => PopupMenuButton(
  //   icon: const Icon(Icons.more_horiz, color: Colors.black26),
  //   onSelected: (v) {
  //     if (v == 'e') {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (_) => CreateQuizScreen(quizToEdit: widget.quiz),
  //         ),
  //       );
  //     } else if (v == 'd') {
  //       _handleDelete();
  //     }
  //   },
  //   itemBuilder: (c) => [
  //     const PopupMenuItem(
  //       value: 'e',
  //       child: Row(
  //         children: [
  //           Icon(Icons.edit, size: 18),
  //           SizedBox(width: 8),
  //           Text('編集'),
  //         ],
  //       ),
  //     ),
  //     const PopupMenuItem(
  //       value: 'd',
  //       child: Row(
  //         children: [
  //           Icon(Icons.delete_outline, size: 18, color: Colors.red),
  //           SizedBox(width: 8),
  //           Text('削除', style: TextStyle(color: Colors.red)),
  //         ],
  //       ),
  //     ),
  //   ],
  // );
}
