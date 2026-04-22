import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'practice/practice_setup_screen.dart';
import 'create/create_quiz_screen.dart';
import 'mypage/my_page_screen.dart'; // インポートを追加
import 'search/search_screen.dart';
import '../../services/auth_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const CreateQuizScreen(),
    const PracticeSetupScreen(),
    const MyPageScreen(),
  ];

  // 【修正】タップ時のロジックを強化
  void _onItemTapped(int index) {
    // 作問(2) または 練習(3) はログイン必須にする場合
    if (index == 2) {
      final user = AuthService().currentUser;
      if (user == null) {
        _showCuteLoginPrompt(); // 未ログインなら可愛い注意を出す
        return;
      }
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  // 【新規】可愛い注意（モーダル）を表示する関数
  void _showCuteLoginPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // 背景を透過させて自作デザインを浮かせる
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28), // かなり丸くする
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 内容に合わせて高さを決める
            children: [
              // アイコンを少し弾ませるようなイメージ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  color: Color(0xFF1A237E),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '作問するにはログインが必要だよ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              const Text(
                'Q-HUBで問題をシェアするために、\nまずはマイページからサインインしてね！',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // モーダルを閉じる
                    _onItemTapped(4); // マイページ(4)へ移動
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'マイページへ行く',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'あとで',
                  style: TextStyle(color: Colors.black26),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),

      // 中央の大きな投稿ボタン（インデックス 2 を開く）
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(2),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.zero,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.auto_awesome, 'タイムライン'),
              _buildNavItem(1, Icons.search, '検索'),

              // 中央の余白（FAB用）
              const SizedBox(width: 48),

              _buildNavItem(3, Icons.play_circle_fill, '練習'),
              _buildNavItem(4, Icons.person, 'マイページ'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF1A237E) : Colors.black26,
            size: 26,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF1A237E) : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}
