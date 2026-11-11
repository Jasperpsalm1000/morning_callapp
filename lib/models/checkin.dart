class Checkin {
  final int? id;
  final String createdAt;
  final String yesterday;
  final String goals;
  final double score;
  final String label;

  const Checkin({
    this.id,
    required this.createdAt,
    required this.yesterday,
    required this.goals,
    required this.score,
    required this.label,
  });

  DateTime get date => DateTime.parse(createdAt);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt,
      'yesterday': yesterday,
      'goals': goals,
      'score': score,
      'label': label,
    };
  }

  factory Checkin.fromMap(Map<String, dynamic> map) {
    return Checkin(
      id: map['id'] as int?,
      createdAt: map['created_at'] as String,
      yesterday: map['yesterday'] as String,
      goals: map['goals'] as String,
      score: (map['score'] as num).toDouble(),
      label: map['label'] as String,
    );
  }
}
