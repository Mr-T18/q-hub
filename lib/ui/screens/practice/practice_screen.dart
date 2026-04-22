import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/quiz.dart';

class PracticeScreen extends StatefulWidget {
  final Quiz quiz;
  const PracticeScreen({super.key, required this.quiz});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  String _displayTexts = ""; // 現在表示されている文字
  int _charIndex = 0; // 何文字目まで表示したか
  Timer? _timer;
  bool _isStopped = false; // ボタンが押されたか
  int _countdown = 5; // カウントダウン秒数
  Timer? _countdownTimer;
  bool _showAnswer = false; // 答えを表示するか

  @override
  void initState() {
    super.initState();
    _startDisplaying();
  }

  // 1文字ずつ表示を開始
  void _startDisplaying() {
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_charIndex < widget.quiz.qText.length) {
        setState(() {
          _displayTexts += widget.quiz.qText[_charIndex];
          _charIndex++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  // 早押しボタンが押された時
  void _onPressed() {
    if (_isStopped) return;
    _timer?.cancel();
    setState(() => _isStopped = true);

    // 5秒のカウントダウン開始
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _showResult();
      }
    });
  }

  // 解答表示（カウント終了または解答確認ボタン押下）
  void _showResult() {
    _countdownTimer?.cancel();
    setState(() {
      _isStopped = true;
      _showAnswer = true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E), // 深いネイビーで集中力を高める
      appBar: AppBar(
        leading: const CloseButton(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          // 問題文表示エリア
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              alignment: Alignment.center,
              child: Text(
                _displayTexts,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // 下部コントロールエリア
          Container(
            height: 350,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildControls(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildControls() {
    if (_showAnswer) {
      // 解答・判定フェーズ
      return [
        const Text(
          '答え',
          style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
        ),
        Text(
          widget.quiz.aText,
          style: const TextStyle(
            fontSize: 32,
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            widget.quiz.explanation,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _judgmentBtn('誤答', Colors.grey, Icons.close),
            _judgmentBtn('正解', Colors.orange, Icons.check),
          ],
        ),
      ];
    } else if (_isStopped) {
      // カウントダウンフェーズ
      return [
        const Text('Thinking Time', style: TextStyle(color: Colors.grey)),
        Text(
          '$_countdown',
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: _countdown <= 2 ? Colors.red : Colors.indigo,
          ),
        ),
        const SizedBox(height: 20),
        TextButton(onPressed: _showResult, child: const Text('答えを見る')),
      ];
    } else {
      // 早押し待ちフェーズ
      return [
        GestureDetector(
          onTap: _onPressed,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'PUSH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ];
    }
  }

  Widget _judgmentBtn(String label, Color color, IconData icon) {
    return Column(
      children: [
        IconButton.filled(
          onPressed: () => Navigator.pop(context),
          icon: Icon(icon, size: 32),
          style: IconButton.styleFrom(
            backgroundColor: color,
            minimumSize: const Size(80, 80),
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
}
