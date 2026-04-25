import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_hub/ui/screens/home/home_screen.dart';
import '../../../models/quiz.dart';
import '../../../services/database_service.dart';
import '../../../services/auth_service.dart';
import '../main_navigation.dart';

class CreateQuizScreen extends StatefulWidget {
  final Quiz? quizToEdit;
  const CreateQuizScreen({super.key, this.quizToEdit});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  late TextEditingController _qController;
  late TextEditingController _aController;
  late TextEditingController _expController;
  late TextEditingController _tagController;
  List<String> _selectedTags = [];
  List<String> _allExistingTags = [];
  List<String> _filteredSuggestions = [];
  double _difficulty = 3;
  bool _isSaving = false;
  bool _isPublic = true; // 公開・非公開の選択状態
  Quiz? _currentEditingQuiz;

  @override
  void initState() {
    super.initState();
    _currentEditingQuiz = widget.quizToEdit;
    _initFields();
    _tagController = TextEditingController();
    _loadAllTags();
    _tagController.addListener(_onTagChanged);
  }

  void _initFields() {
    _qController = TextEditingController(
      text: _currentEditingQuiz?.qText ?? '',
    );
    _aController = TextEditingController(
      text: _currentEditingQuiz?.aText ?? '',
    );
    _expController = TextEditingController(
      text: _currentEditingQuiz?.explanation ?? '',
    );
    _selectedTags = _currentEditingQuiz != null
        ? List.from(_currentEditingQuiz!.tags)
        : [];
    _difficulty = _currentEditingQuiz?.difficulty.toDouble() ?? 3;
    _isPublic = _currentEditingQuiz?.isPublic ?? true; // 編集時は現在の状態を反映
  }

  @override
  void dispose() {
    _tagController.removeListener(_onTagChanged);
    _qController.dispose();
    _aController.dispose();
    _expController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadAllTags() async {
    final tags = await DatabaseService().getAllTags();
    if (mounted) setState(() => _allExistingTags = tags);
  }

  void _onTagChanged() {
    final text = _tagController.text.trim();
    if (text.isEmpty) {
      setState(() => _filteredSuggestions = []);
      return;
    }
    setState(() {
      _filteredSuggestions = _allExistingTags
          .where((t) => t.toLowerCase().contains(text.toLowerCase()))
          .where((t) => !_selectedTags.contains(t))
          .toList();
    });
  }

  void _addTag(String val) {
    final tag = val.trim();
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _tagController.clear();
        _filteredSuggestions = [];
      });
    }
  }

  Future<void> _handleSave({required bool isPublic}) async {
    final user = AuthService().currentUser;
    if (user == null || _qController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      // 編集か新規かを判定
      final isEditing = _currentEditingQuiz != null;

      if (isEditing) {
        // --- 【編集の場合】 ---
        // 既存の saveQuiz を呼び出す（カウントアップはしない）
        final Map<String, dynamic> data = {
          'qText': _qController.text.trim(),
          'aText': _aController.text.trim(),
          'explanation': _expController.text.trim(),
          'tags': _selectedTags,
          'difficulty': _difficulty.toInt(),
          'isPublic': isPublic,
          'creatorId': _currentEditingQuiz!.creatorId,
          'creatorName': _currentEditingQuiz!.creatorName,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': _currentEditingQuiz!.createdAt,
        };

        await DatabaseService().saveQuiz(
          quizId: _currentEditingQuiz!.id,
          data: data,
        );
      } else {
        // --- 【新規投稿の場合】 ---
        // 作成した addQuiz を呼び出す（ここで totalQuizCount が +1 される）
        await DatabaseService().addQuiz(
          qText: _qController.text.trim(),
          aText: _aController.text.trim(),
          explanation: _expController.text.trim(),
          tags: _selectedTags,
          difficulty: _difficulty.toInt(),
          creatorId: user.uid,
          creatorName: user.displayName ?? '詠み人知らず',
          isPublic: isPublic,
        );
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Save Error: $e");
      // 必要に応じてユーザーにエラー通知を表示
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // build メソッド内のボタン部分の修正
  @override
  Widget build(BuildContext context) {
    final bool isNewQuiz = _currentEditingQuiz == null;
    final bool isDraft =
        _currentEditingQuiz != null && !_currentEditingQuiz!.isPublic;
    final bool isPublishedEdit =
        _currentEditingQuiz != null && _currentEditingQuiz!.isPublic;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPublishedEdit ? '問題を編集' : (isDraft ? '下書きを編集' : '問題を投稿')),
        actions: [
          // 公開済みの編集時は、他の下書きを呼び出すと混乱するため非表示にする
          if (!isPublishedEdit)
            IconButton(
              onPressed: _showDraftsModal,
              icon: const Icon(Icons.folder_open),
              tooltip: '下書きを読み込む',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            /* ... 入力フィールド ... */
            _section('問題と答え', [
              TextField(
                controller: _qController,
                minLines: 5, // 最初から5行分の高さを確保
                maxLines: 10, // 最大10行まで自動で伸びる
                decoration: const InputDecoration(
                  labelText: '問題文',
                  alignLabelWithHint: true, // 複数行の時にラベルを上に寄せる
                  border: OutlineInputBorder(), // 枠線をつけると領域が分かりやすくなります
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _aController,
                minLines: 2, // 正解欄も少し広めに
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '正解',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _section('解説', [
              TextField(
                controller: _expController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: '解説'),
              ),
            ]),
            const SizedBox(height: 20),
            // 【新規追加】難易度設定
            _section('難易度設定', [
              Row(
                children: [
                  const Text(
                    '簡単',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Expanded(
                    child: Slider(
                      value: _difficulty,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: const Color(0xFF1A237E),
                      label: '星${_difficulty.toInt()}',
                      onChanged: (val) => setState(() => _difficulty = val),
                    ),
                  ),
                  const Text(
                    '難しい',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Center(
                child: Text(
                  '難易度: ${_difficulty.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _section('タグ', [
              TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  labelText: 'タグ検索',
                  suffixIcon: Icon(Icons.search),
                ),
                onSubmitted: _addTag,
              ),
              if (_filteredSuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    children: _filteredSuggestions
                        .take(5)
                        .map(
                          (s) => ListTile(
                            title: Text(s),
                            dense: true,
                            onTap: () => _addTag(s),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _selectedTags
                    .map(
                      (t) => Chip(
                        label: Text(t),
                        onDeleted: () =>
                            setState(() => _selectedTags.remove(t)),
                      ),
                    )
                    .toList(),
              ),
            ]),
            const SizedBox(height: 20),

            if (_isSaving)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _handleSave(isPublic: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '投稿する',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _handleSave(isPublic: false),
                    child: const Text(
                      '下書きに保存',
                      style: TextStyle(color: Colors.black45),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showDraftsModal() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    // 下書きリストを取得
    final drafts = await DatabaseService().getMyDrafts(user.uid);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '下書きから読み込む',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const Divider(),
              if (drafts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('保存された下書きはありません'),
                ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: drafts.length,
                  itemBuilder: (context, index) {
                    final d = drafts[index];
                    return ListTile(
                      leading: const Icon(Icons.article_outlined),
                      title: Text(
                        d.qText.isEmpty ? '(無題の問題)' : d.qText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        setState(() {
                          _currentEditingQuiz = d;
                          _initFields(); // 取得したデータでフィールドをリセット
                        });
                        Navigator.pop(context);
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
  }

  Widget _section(String t, List<Widget> c) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 16),
        ...c,
      ],
    ),
  );
}
