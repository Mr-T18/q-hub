// lib/ui/screens/admin/user_management_screen.dart

import 'package:flutter/material.dart';
import '../../../models/app_user.dart';
import '../../../services/database_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/admin_state.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '部員管理',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A237E),
        elevation: 0,
      ),
      body: StreamBuilder<List<AppUser>>(
        // 全ユーザーを取得するストリーム（DatabaseServiceに実装が必要）
        stream: DatabaseService().getAllUsersStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: user.isAdmin
                      ? Colors.orange
                      : Colors.grey[200],
                  child: Icon(
                    user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: user.isAdmin ? Colors.white : Colors.grey,
                  ),
                ),
                title: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(user.isAdmin ? '管理者' : '一般部員'),
                trailing: const Icon(Icons.edit_note),
                onTap: () => _showRoleDialog(context, user),
              );
            },
          );
        },
      ),
    );
  }

  // ロール変更の確認ダイアログ
  void _showRoleDialog(BuildContext context, AppUser targetUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${targetUser.name}さんの権限変更'),
        content: Text(
          targetUser.isAdmin
              ? 'このユーザーを「一般部員」に変更しますか？'
              : 'このユーザーを「管理者」に昇格させますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final currentUserId = AuthService().currentUser?.uid;
                final isSelf = targetUser.id == currentUserId;
                final newRole = targetUser.isAdmin ? 'user' : 'admin';

                // 権限の更新を実行（DatabaseService側で「最後の1人」チェックが走る）
                await DatabaseService().updateUserRole(targetUser.id, newRole);

                if (context.mounted) {
                  // 1. まず確認ダイアログを閉じる
                  Navigator.pop(context);

                  // 2. もし自分自身の権限を「一般部員」に落とした場合
                  if (isSelf && newRole == 'user') {
                    // 管理者モード（スイッチ）を強制的にOFFにする
                    AdminState().isModeEnabled.value = false;

                    // 3. 現在の「部員管理画面」を閉じてマイページに戻る
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('管理者権限を返上しました。ユーザーモードに戻ります。'),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  // ダイアログは閉じずにエラーを表示（「管理者が0人になる」等の警告）
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                    ),
                  );
                }
              }
            },
            child: const Text('変更する'),
          ),
        ],
      ),
    );
  }
}
