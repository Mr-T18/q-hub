import 'package:flutter/material.dart';
import '../../../models/quiz.dart';
import '../../../services/database_service.dart';
import '../../../services/auth_service.dart';
import './practice_session_screen.dart';
import '../../widgets/star_difficulty_selector.dart';

class PracticeSetupScreen extends StatefulWidget {
  const PracticeSetupScreen({super.key});

  @override
  State<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends State<PracticeSetupScreen> {
  String _selectedMode = 'random';
  List<String> _selectedTags = [];
  Map<String, dynamic>? _selectedList;
  bool _isShuffle = true;
  bool _isLoading = false;
  int? _randomDifficulty; // クラスのメンバ変数に追加

  final Color primaryColor = const Color(0xFF1A237E);

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '練習設定',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: primaryColor,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('練習モードを選択'),
                _buildModeSelector(),
                const SizedBox(height: 24),

                // 【修正点】AnimatedSwitcherを削除し、高さを固定したContainerに変更
                Container(
                  height: 320, // 高さを固定（適宜調整してください）
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  // 固定枠の中でスクロールさせる
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildModeSpecificSettings(user?.uid),
                  ),
                ),

                const SizedBox(height: 40),

                _buildStartButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        showSelectedIcon: false, // アイコンを消して文字スペースを確保
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.white,
          selectedBackgroundColor: primaryColor,
          selectedForegroundColor: Colors.white,
          side: BorderSide(color: primaryColor.withOpacity(0.2)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        segments: const [
          ButtonSegment(
            value: 'random',
            label: Text('ランダム', style: TextStyle(fontSize: 13)),
          ),
          ButtonSegment(
            value: 'tag',
            label: Text('タグ指定', style: TextStyle(fontSize: 13)),
          ),
          ButtonSegment(
            value: 'list',
            label: Text('マイリスト', style: TextStyle(fontSize: 13)),
          ),
        ],
        selected: {_selectedMode},
        onSelectionChanged: (newSelection) {
          setState(() {
            _selectedMode = newSelection.first;
            _selectedTags.clear();
            _selectedList = null;
          });
        },
      ),
    );
  }

  Widget _buildModeSpecificSettings(String? uid) {
    if (_selectedMode == 'random') {
      return _buildRandomInfo(); // メソッドとして呼び出し
    } else if (_selectedMode == 'tag') {
      return _buildTagSelector();
    } else if (_selectedMode == 'list') {
      return _buildListSelector(uid);
    }
    return const SizedBox.shrink();
  }

  Widget _buildRandomInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shuffle, size: 40, color: Colors.grey),
        const SizedBox(height: 12),
        const Text(
          '出題する難易度を選択',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // 星型セレクターを配置
        StarDifficultySelector(
          selectedLevel: _randomDifficulty,
          onSelected: (val) => setState(() => _randomDifficulty = val),
        ),
      ],
    );
  }

  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'タグを選択（複数可）',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<String>>(
          future: DatabaseService().getAllTags(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final tags = snapshot.data!;
            return Wrap(
              spacing: 8,
              runSpacing: 4,
              children: tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.grey[100],
                  onSelected: (selected) {
                    setState(() {
                      selected
                          ? _selectedTags.add(tag)
                          : _selectedTags.remove(tag);
                    });
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildListSelector(String? uid) {
    if (uid == null) return const Center(child: Text('ログインが必要です'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'リストを選択',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService().getAllMyVisibleLists(uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final lists = snapshot.data!;
            if (lists.isEmpty)
              return const Text(
                'リストがありません',
                style: TextStyle(color: Colors.grey),
              );
            return Column(
              children: [
                ...lists.map((l) {
                  final isSelected = _selectedList?['id'] == l['id'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? primaryColor : Colors.grey[200]!,
                        ),
                      ),
                      tileColor: isSelected
                          ? primaryColor.withOpacity(0.05)
                          : Colors.transparent,
                      leading: Icon(
                        Icons.playlist_play,
                        color: isSelected ? primaryColor : Colors.grey,
                      ),
                      title: Text(
                        l['title'] ?? '無題',
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${(l['quizIds'] as List? ?? []).length}問',
                      ),
                      onTap: () => setState(() => _selectedList = l),
                    ),
                  );
                }),
                const Divider(height: 32),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('シャッフル再生', style: TextStyle(fontSize: 14)),
                  value: _isShuffle,
                  activeColor: primaryColor,
                  onChanged: (val) => setState(() => _isShuffle = val),
                  secondary: Icon(
                    _isShuffle ? Icons.shuffle : Icons.sort,
                    size: 20,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    final bool canStart = _canStart() && !_isLoading;
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: canStart
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: canStart ? _startPractice : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          '練習を開始する',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  bool _canStart() {
    if (_selectedMode == 'random') return true;
    if (_selectedMode == 'tag') return _selectedTags.isNotEmpty;
    if (_selectedMode == 'list') return _selectedList != null;
    return false;
  }

  void _startPractice() async {
    setState(() => _isLoading = true);

    // モードに合わせて問題を取得
    List<Quiz> questions = await DatabaseService().getPracticeQuizzes(
      mode: _selectedMode,
      tags: _selectedTags,
      quizIds: _selectedList != null
          ? List<String>.from(_selectedList!['quizIds'] ?? [])
          : null,
      // 【修正点】選択した難易度を渡す（randomモード時のみ）
      difficulty: _selectedMode == 'random' ? _randomDifficulty : null,
      shuffle: _selectedMode == 'list' ? _isShuffle : true,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (questions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('条件に合う問題が見つかりませんでした')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeSessionScreen(
          quizzes: questions, // 引数名に注意
          isShuffle: _selectedMode == 'list' ? _isShuffle : true,
        ),
      ),
    );
  }
}
