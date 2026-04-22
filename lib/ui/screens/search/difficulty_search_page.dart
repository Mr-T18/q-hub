import 'package:flutter/material.dart';
import '../../../services/database_service.dart';
import '../../../models/quiz.dart';
import '../../widgets/quiz_card.dart';
import '../../widgets/star_difficulty_selector.dart';

class DifficultySearchPage extends StatefulWidget {
  const DifficultySearchPage({super.key});
  @override
  State<DifficultySearchPage> createState() => _DifficultySearchPageState();
}

class _DifficultySearchPageState extends State<DifficultySearchPage> {
  int? _selectedLevel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('難易度でさがす'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A237E),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 上部の白いエリアに星UIを配置
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: StarDifficultySelector(
              selectedLevel: _selectedLevel,
              onSelected: (val) => setState(() => _selectedLevel = val),
            ),
          ),
          // 結果表示エリア
          Expanded(
            child: StreamBuilder<List<Quiz>>(
              stream: DatabaseService().getQuizzesByDifficulty(_selectedLevel),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final list = snapshot.data!;
                if (list.isEmpty)
                  return const Center(child: Text('該当する問題がありません'));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (context, index) =>
                      ExpandableQuizCard(quiz: list[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceChip(int? level, String label) {
    final isSelected = _selectedLevel == level;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedLevel = level),
        selectedColor: const Color.fromARGB(255, 246, 255, 0),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
