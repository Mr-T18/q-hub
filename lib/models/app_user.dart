import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String bio;
  final String photoUrl;
  final String department;
  final String year;
  final String title;
  final int totalQuizCount; // 追加
  final int practiceCount; // 追加
  final String role;

  AppUser({
    required this.id,
    required this.name,
    required this.bio,
    required this.photoUrl,
    required this.department,
    required this.year,
    required this.title,
    this.totalQuizCount = 0,
    this.practiceCount = 0,
    this.role = 'user',
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      bio: data['bio'] ?? '',
      photoUrl: data['photoUrl'] ?? 'https://via.placeholder.com/150',
      department: data['department'] ?? '',
      year: data['year'] ?? '',
      title: data['title'] ?? '専Q部員',
      totalQuizCount: (data['totalQuizCount'] ?? 0).toInt(),
      practiceCount: (data['practiceCount'] ?? 0).toInt(),
      role: data['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bio': bio,
      'photoUrl': photoUrl,
      'department': department,
      'year': year,
      'title': title,
      'totalQuizCount': totalQuizCount,
      'practiceCount': practiceCount,
    };
  }
}
