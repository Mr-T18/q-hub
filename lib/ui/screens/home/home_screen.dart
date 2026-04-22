import 'package:flutter/material.dart';
import '../../../services/database_service.dart';
import '../../../models/quiz.dart';
import '../../widgets/quiz_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 3つのタブ
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Image.asset(
            'assets/images/logo.png',
            height: 45,
            fit: BoxFit.contain,
          ),
          // 【新規】タブバーの設置
          bottom: const TabBar(
            labelColor: Color(0xFF1A237E), // 専Qネイビー
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF1A237E),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: '新着'),
              Tab(text: 'いいね数'),
              Tab(text: 'シャッフル'),
            ],
          ),
        ),
        // 【新規】タブの内容（TabBarView）
        body: TabBarView(
          children: [
            _buildQuizList(context, 'new'), // 新着順
            _buildQuizList(context, 'likes'), // いいね順
            _buildQuizList(context, 'shuffle'), // シャッフル
          ],
        ),
      ),
    );
  }

  // クイズリストをビルドする共通メソッド
  Widget _buildQuizList(BuildContext context, String sortType) {
    return StreamBuilder<List<Quiz>>(
      // 以前作成した全件取得ストリームを使用（名前は適宜合わせてください）
      stream: DatabaseService().getTimelineQuizzes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('エラーが発生しました:\n${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final quizzes = snapshot.data ?? [];

        if (quizzes.isEmpty) {
          return const Center(child: Text('データが見つかりません。'));
        }

        // --- 並び替えロジック ---
        // 参照渡しによる元データの破壊を防ぐため、コピーを作成してからソート
        List<Quiz> sortedList = List.from(quizzes);

        if (sortType == 'new') {
          // 新着順（createdAtが新しい順）
          sortedList.sort(
            (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
              a.createdAt ?? DateTime.now(),
            ),
          );
        } else if (sortType == 'likes') {
          // いいね数順（likeCountが多い順）
          // Quizモデルに likeCount プロパティがある前提です
          sortedList.sort(
            (a, b) => (b.likeCount ?? 0).compareTo(a.likeCount ?? 0),
          );
        } else if (sortType == 'shuffle') {
          // シャッフル
          sortedList.shuffle();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: sortedList.length,
          itemBuilder: (context, index) =>
              ExpandableQuizCard(quiz: sortedList[index]),
        );
      },
    );
  }
}
