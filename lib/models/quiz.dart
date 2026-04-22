import 'package:cloud_firestore/cloud_firestore.dart';

class Quiz {
  final String id;
  final String qText;
  final String aText;
  final String explanation;
  final List<String> tags;
  final int difficulty;
  final String creatorId;
  final String creatorName;
  final int likeCount;
  final bool isPublic;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.qText,
    required this.aText,
    required this.explanation,
    required this.tags,
    required this.difficulty,
    required this.creatorId,
    required this.creatorName,
    required this.likeCount,
    required this.isPublic,
    required this.createdAt,
  });

  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Quiz(
      id: doc.id,
      qText: data['qText'] ?? '',
      aText: data['aText'] ?? '',
      explanation: data['explanation'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      difficulty: data['difficulty'] ?? 1,
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '詠み人知らず',
      likeCount: data['likeCount'] ?? 0,
      isPublic: data['isPublic'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
