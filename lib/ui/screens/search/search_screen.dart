import 'package:flutter/material.dart';
import 'keyword_search_page.dart';
import 'tag_search_page.dart';
import 'creator_search_page.dart';
import 'ranking_page.dart';
import 'difficulty_search_page.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'さがす',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _menuCard(
            context,
            'キーワード',
            Icons.search,
            Colors.blue,
            const KeywordSearchPage(),
          ),
          _menuCard(
            context,
            '難易度',
            Icons.star_rate_rounded,
            Colors.purple,
            const DifficultySearchPage(), // 新しく作成するページ
          ),
          _menuCard(
            context,
            'タグ検索',
            Icons.tag,
            Colors.orange,
            const TagSearchPage(),
          ),
          _menuCard(
            context,
            '作問者',
            Icons.person_search,
            Colors.green,
            const CreatorSearchPage(),
          ),
          _menuCard(
            context,
            'ランキング',
            Icons.leaderboard,
            Colors.redAccent,
            const RankingPage(),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
