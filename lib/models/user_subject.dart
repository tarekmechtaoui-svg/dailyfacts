class UserSubject {
  final String id;
  final String userId;
  final String subjectId;
  final bool subscribed;
  final DateTime createdAt;

  UserSubject({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.subscribed,
    required this.createdAt,
  });

  factory UserSubject.fromJson(Map<String, dynamic> json) {
    return UserSubject(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String,
      subscribed: json['subscribed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'subscribed': subscribed,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
