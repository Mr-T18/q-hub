import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/quiz.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';

class PracticeSessionScreen extends StatefulWidget {
  final List<Quiz> quizzes;
  final bool isShuffle;
  const PracticeSessionScreen({
    super.key,
    required this.quizzes,
    required this.isShuffle,
  });

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

enum PracticeState { intro, scrolling, countdown, result }

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  int _currentIndex = 0;
  PracticeState _state = PracticeState.intro;
  String _displayedText = "";
  int _countdown = 5;
  bool? _selectedCorrect; // null: 未選択, true: 正解を選択, false: 誤答を選択
  Timer? _textTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _showIntro();
  }

  @override
  void dispose() {
    _textTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _showIntro() {
    setState(() {
      _state = PracticeState.intro;
      _displayedText = "";
      _countdown = 5;
      _selectedCorrect = null;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _startScrolling();
    });
  }

  void _startScrolling() {
    setState(() => _state = PracticeState.scrolling);
    final fullText = widget.quizzes[_currentIndex].qText;
    int charIndex = 0;
    _textTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (charIndex < fullText.length) {
        setState(() {
          _displayedText += fullText[charIndex];
          charIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _onBuzz() {
    _textTimer?.cancel();
    setState(() {
      _state = PracticeState.countdown;
      _countdown = 5;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _revealResult();
      }
    });
  }

  void _revealResult() {
    _textTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _state = PracticeState.result;
      _displayedText = widget.quizzes[_currentIndex].qText;
    });
  }

  void _submitEvaluation(bool isCorrect) {
    final user = AuthService().currentUser;
    if (user != null) {
      DatabaseService().savePracticeHistory(
        user.uid,
        widget.quizzes[_currentIndex],
        isCorrect,
      );
    }
    setState(() => _selectedCorrect = isCorrect);
  }

  void _nextQuestion() {
    if (_currentIndex < widget.quizzes.length - 1) {
      setState(() => _currentIndex++);
      _showIntro();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quizzes[_currentIndex];
    final uid = AuthService().currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          '練習中 (${_currentIndex + 1}/${widget.quizzes.length})',
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            alignment: Alignment.topLeft,
            child: _state == PracticeState.intro
                ? _buildIntroWidget()
                : SingleChildScrollView(
                    child: Text(
                      _displayedText,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: _buildControlPanel(quiz, uid),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '問題',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.0, end: 0.0),
              duration: const Duration(milliseconds: 1800),
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.indigo[50],
                color: const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(10),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(Quiz quiz, String? uid) {
    switch (_state) {
      case PracticeState.intro:
        return const SizedBox.shrink();
      case PracticeState.scrolling:
        return Center(
          child: SizedBox(
            width: 140,
            height: 140,
            child: ElevatedButton(
              onPressed: _onBuzz,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: const CircleBorder(),
                elevation: 8,
              ),
              child: const Text(
                'BUZZ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      case PracticeState.countdown:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_countdown',
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w900,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _revealResult,
              child: const Text(
                '答えを表示',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.indigo,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      case PracticeState.result:
        return _buildResultActions(quiz, uid);
    }
  }

  Widget _buildResultActions(Quiz quiz, String? uid) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const Text(
            '【答え】',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Text(
            quiz.aText,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 12),
          if (quiz.explanation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                quiz.explanation,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          Wrap(
            spacing: 8,
            children: quiz.tags
                .map(
                  (t) => Text(
                    '#$t',
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _evaluationButton('誤答', Icons.close, Colors.blue, false),
              _evaluationButton(
                '正解',
                Icons.radio_button_unchecked,
                Colors.red,
                true,
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (uid != null) _buildSocialRow(uid, quiz),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _selectedCorrect != null ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '次の問題へ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _evaluationButton(
    String label,
    IconData icon,
    Color color,
    bool isCorrect,
  ) {
    final isSelected = _selectedCorrect == isCorrect;
    return Column(
      children: [
        GestureDetector(
          onDoubleTap: () => _submitEvaluation(isCorrect),
          child: ElevatedButton(
            onPressed: () => _submitEvaluation(isCorrect),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? color : Colors.white,
              foregroundColor: isSelected ? Colors.white : color,
              elevation: isSelected ? 0 : 2,
              side: BorderSide(
                color: isSelected ? Colors.transparent : color.withOpacity(0.2),
              ),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(20),
            ),
            child: Icon(icon, size: 40),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // 【修正】マイリストボタンを含むソーシャル行
  Widget _buildSocialRow(String uid, Quiz quiz) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // いいね（赤）
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('questions')
              .doc(quiz.id)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final likedBy = List<String>.from(data?['likedBy'] ?? []);
            final isLiked = likedBy.contains(uid);
            return IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
                size: 28,
              ),
              onPressed: () => DatabaseService().toggleLike(uid, quiz.id),
            );
          },
        ),
        const SizedBox(width: 40),
        // ブックマーク（青）
        StreamBuilder<List<String>>(
          stream: DatabaseService().getBookmarkIds(uid),
          builder: (context, snapshot) {
            final isSaved = snapshot.data?.contains(quiz.id) ?? false;
            return IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.blue,
                size: 28,
              ),
              onPressed: () => DatabaseService().toggleBookmark(uid, quiz.id),
            );
          },
        ),
        const SizedBox(width: 40),
        // マイリスト（緑）: チェックボックス形式のピッカーを呼び出し
        IconButton(
          icon: const Icon(Icons.playlist_add, color: Colors.green, size: 28),
          onPressed: () => _showMyListPicker(context, uid, quiz.id),
        ),
      ],
    );
  }

  // --- 共通のマイリストピッカー (QuizCard / PracticeSessionScreen 両方で使用) ---
  void _showMyListPicker(BuildContext context, String uid, String quizId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ダイアログとキーボードの干渉を防ぐ
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
                  // 【新規】新規作成ボタン
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

  // --- リスト作成ダイアログ ---
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
}
