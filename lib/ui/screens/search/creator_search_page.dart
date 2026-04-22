import 'package:flutter/material.dart';
import '../../../models/app_user.dart';
import '../../../services/database_service.dart';
import '../mypage/my_page_screen.dart';

class CreatorSearchPage extends StatelessWidget {
  const CreatorSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('作問者一覧')),
      body: StreamBuilder<List<AppUser>>(
        stream: DatabaseService().getAllUsers(), // 全ユーザ取得
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final user = users[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(user.photoUrl),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    user.bio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MyPageScreen(targetUserId: user.id, isMe: false),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
