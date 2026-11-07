class Summary {
  const Summary({
    required this.date,
    required this.goal,
    required this.visitsTotal,
    required this.visitsDone,
    required this.visitsPending,
    required this.focosFound,
  });

  final DateTime date;
  final int goal;
  final int visitsTotal;
  final int visitsDone;
  final int visitsPending;
  final int focosFound;

  /// Progresso da meta do dia, de 0.0 a 1.0.
  double get progress =>
      goal <= 0 ? 0 : (visitsDone / goal).clamp(0.0, 1.0).toDouble();

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
        date: DateTime.parse(json['date'] as String),
        goal: (json['goal'] as num).toInt(),
        visitsTotal: (json['visits_total'] as num).toInt(),
        visitsDone: (json['visits_done'] as num).toInt(),
        visitsPending: (json['visits_pending'] as num).toInt(),
        focosFound: (json['focos_found'] as num).toInt(),
      );
}
