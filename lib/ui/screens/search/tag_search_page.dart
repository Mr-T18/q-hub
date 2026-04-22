import 'package:flutter/material.dart';
import '../../../models/quiz.dart';
import '../../../services/database_service.dart';
import '../../widgets/quiz_card.dart';

class TagSearchPage extends StatefulWidget {
  const TagSearchPage({super.key});
  @override
  State<TagSearchPage> createState() => _TagSearchPageState();
}

class _TagSearchPageState extends State<TagSearchPage> {
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('タグで探す'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<List<String>>(
              future: DatabaseService().getAllTags(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final tags = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    // タグを散らす
                    spacing: 8,
                    runSpacing: 8,
                    children: tags
                        .map(
                          (tag) => ActionChip(
                            label: Text('#$tag'),
                            onPressed: () => setState(
                              () => _selectedTag = (_selectedTag == tag
                                  ? null
                                  : tag),
                            ),
                            backgroundColor: _selectedTag == tag
                                ? Colors.indigo
                                : Colors.indigo[50],
                            labelStyle: TextStyle(
                              color: _selectedTag == tag
                                  ? Colors.white
                                  : Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
            const Divider(),
            if (_selectedTag != null)
              // 【重要】StreamBuilderの待機状態を適切にハンドリング
              StreamBuilder<List<Quiz>>(
                stream: DatabaseService().getQuizzesByTag(_selectedTag!),
                builder: (context, snapshot) {
                  // dataがnullの間だけぐるぐるを出す
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final list = snapshot.data!;
                  if (list.isEmpty)
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('問題が見つかりません'),
                    );

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, i) =>
                        ExpandableQuizCard(quiz: list[i]),
                  );
                },
              )
            else
              const Padding(
                padding: EdgeInsets.all(40),
                child: Text('興味のあるタグをタップ！'),
              ),
          ],
        ),
      ),
    );
  }
}
