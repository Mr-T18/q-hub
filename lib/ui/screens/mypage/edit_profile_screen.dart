import 'package:flutter/material.dart';
import '../../../models/app_user.dart';
import '../../../services/user_service.dart';
import '../../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _photoController;
  late TextEditingController _deptController;
  late TextEditingController _yearController;
  late TextEditingController _titleController; // タイトル用を追加

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
    _photoController = TextEditingController(text: widget.user.photoUrl);
    _deptController = TextEditingController(text: widget.user.department);
    _yearController = TextEditingController(text: widget.user.year);
    _titleController = TextEditingController(text: widget.user.title); // 初期値セット
  }

  Future<void> _save() async {
    // 保存データに 'title' を追加
    await UserService().updateProfile(widget.user.id, {
      'name': _nameController.text,
      'bio': _bioController.text,
      'photoUrl': _photoController.text,
      'department': _deptController.text,
      'year': _yearController.text,
      'title': _titleController.text, // ここを忘れずに
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'プロフィール編集',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(_photoController.text),
            ),
            const SizedBox(height: 32),
            _f('名前', _nameController),
            _f('肩書き (タイトル)', _titleController, hint: '例：会長'), // タイトル編集ボックス
            _f('写真URL', _photoController),
            Row(
              children: [
                Expanded(child: _f('学科', _deptController)),
                const SizedBox(width: 16),
                Expanded(child: _f('学年', _yearController)),
              ],
            ),
            _f('自己紹介', _bioController, maxLines: 3),
            const SizedBox(height: 40),
            const Divider(),
            TextButton.icon(
              onPressed: () async {
                // 1. サインアウト実行
                await AuthService().signOut();
                if (context.mounted) {
                  // 2. 編集画面を閉じる（呼び出し元のマイページに戻る）
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('ログアウト', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _f(
    String l,
    TextEditingController c, {
    int maxLines = 1,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: l,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
