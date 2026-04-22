import 'package:flutter/material.dart';
import '../../../models/quiz.dart';
import '../../../services/database_service.dart';
import '../../widgets/quiz_card.dart';

class MyListDetailScreen extends StatelessWidget {
  final Map<String, dynamic> listData;
  const MyListDetailScreen({super.key, required this.listData});

  @override
  Widget build(BuildContext context) {
    // リスト内のクイズIDを取得
    final List<String> quizIds = List<String>.from(listData['quizIds'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          listData['title'] ?? 'マイリスト',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Quiz>>(
        stream: DatabaseService().getQuizzesByIds(quizIds),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final quizzes = snapshot.data ?? [];
          if (quizzes.isEmpty) {
            return const Center(child: Text('このリストにはまだ問題がありません'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: quizzes.length,
            itemBuilder: (context, i) => ExpandableQuizCard(quiz: quizzes[i]),
          );
        },
      ),
    );
  }
}
