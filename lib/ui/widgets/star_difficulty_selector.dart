import 'package:flutter/material.dart';

class StarDifficultySelector extends StatelessWidget {
  final int? selectedLevel;
  final Function(int?) onSelected;

  const StarDifficultySelector({
    super.key,
    required this.selectedLevel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final level = index + 1;
            // 選択されているレベル以下なら点灯、未選択(null)ならグレー
            final isFilled = selectedLevel != null && level <= selectedLevel!;

            return IconButton(
              onPressed: () => onSelected(level),
              icon: Icon(
                isFilled ? Icons.star : Icons.star_border,
                size: 36,
                color: isFilled ? Colors.orange : Colors.grey[300],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => onSelected(null), // クリアして全表示
          child: const Text(
            '難易度をクリア',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
