import 'package:flutter/material.dart';
import '../../../models/quiz.dart';
import '../../../services/database_service.dart';
import '../../widgets/quiz_card.dart';

class KeywordSearchPage extends StatefulWidget {
  const KeywordSearchPage({super.key});

  @override
  State<KeywordSearchPage> createState() => _KeywordSearchPageState();
}

class _KeywordSearchPageState extends State<KeywordSearchPage> {
  String _query = "";
  List<Quiz> _allQuizzes = [];
  List<Quiz> _filteredQuizzes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'キーワードを入力...',
            border: InputBorder.none,
          ),
          onChanged: (val) {
            setState(() {
              _query = val;
              _filterResults();
            });
          },
        ),
      ),
      body: StreamBuilder<List<Quiz>>(
        stream: DatabaseService().getAllQuizzesForSearch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          _allQuizzes = snapshot.data!;
          _filterResults(); // データ取得時にフィルタ実行

          if (_query.isEmpty) {
            return const Center(child: Text('気になるキーワードを入力してください'));
          }
          if (_filteredQuizzes.isEmpty) {
            return const Center(child: Text('該当する問題が見つかりません'));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: _filteredQuizzes.length,
            itemBuilder: (context, i) =>
                ExpandableQuizCard(quiz: _filteredQuizzes[i]),
          );
        },
      ),
    );
  }

  void _filterResults() {
    if (_query.isEmpty) {
      _filteredQuizzes = [];
    } else {
      _filteredQuizzes = _allQuizzes.where((q) {
        final qText = q.qText.toLowerCase();
        final aText = q.aText.toLowerCase();
        final searchLower = _query.toLowerCase();
        return qText.contains(searchLower) || aText.contains(searchLower);
      }).toList();
    }
  }
}
