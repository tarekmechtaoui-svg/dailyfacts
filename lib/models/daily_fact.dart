class DailyFact {
  final String id;
  final String subjectId;
  final String factText;
  final DateTime createdAt;
  final DateTime? sentAt;

  DailyFact({
    required this.id,
    required this.subjectId,
    required this.factText,
    required this.createdAt,
    this.sentAt,
  });

  factory DailyFact.fromJson(Map<String, dynamic> json) {
    return DailyFact(
      id: json['id'] as String,
      subjectId: json['subject_id'] as String,
      factText: json['fact_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'fact_text': factText,
      'created_at': createdAt.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
    };
  }
}
