import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class MarkListButton extends StatelessWidget {
  final String creatorId; // リストの作成者ID
  final String listId; // リスト自体のID

  const MarkListButton({
    super.key,
    required this.creatorId,
    required this.listId,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    if (currentUser == null || currentUser.uid == creatorId) {
      return const SizedBox.shrink(); // 未ログインまたは自分のリストなら何も出さない
    }

    // 自分がマークしているかどうかをリアルタイムで監視
    return StreamBuilder<bool>(
      stream: DatabaseService().isListMarked(currentUser.uid, listId),
      builder: (context, snapshot) {
        final isMarked = snapshot.data ?? false;

        return IconButton(
          onPressed: () {
            DatabaseService().toggleMarkList(
              currentUser.uid,
              creatorId,
              listId,
            );
          },
          icon: Icon(
            isMarked ? Icons.add_circle : Icons.add_circle_outline,
            color: isMarked ? Colors.green : Colors.grey, // マークで緑、未マークで灰色
            size: 28,
          ),
          tooltip: isMarked ? 'マークを解除' : 'マイリストに登録',
        );
      },
    );
  }
}
