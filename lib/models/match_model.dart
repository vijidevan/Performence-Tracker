class MatchModel {
  final String id;
  final String stumpsMatchId;
  final String team1Id;
  final String team2Id;
  final DateTime matchDate;
  final String format;
  final int overs;
  final String venue;
  final String tossWinnerTeamId;
  final String tossDecision;
  final String result;
  final String organiser;
  final String scorer;
  final bool completed;
  final DateTime createdAt;

  const MatchModel({
    required this.id,
    required this.stumpsMatchId,
    required this.team1Id,
    required this.team2Id,
    required this.matchDate,
    required this.format,
    required this.overs,
    required this.venue,
    required this.tossWinnerTeamId,
    required this.tossDecision,
    required this.result,
    required this.organiser,
    required this.scorer,
    this.completed = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stumpsMatchId': stumpsMatchId,
      'team1Id': team1Id,
      'team2Id': team2Id,
      'matchDate': matchDate.toIso8601String(),
      'format': format,
      'overs': overs,
      'venue': venue,
      'tossWinnerTeamId': tossWinnerTeamId,
      'tossDecision': tossDecision,
      'result': result,
      'organiser': organiser,
      'scorer': scorer,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      id: map['id'] as String? ?? '',
      stumpsMatchId: map['stumpsMatchId'] as String? ?? '',
      team1Id: map['team1Id'] as String? ?? '',
      team2Id: map['team2Id'] as String? ?? '',
      matchDate: DateTime.tryParse(
            map['matchDate'] as String? ?? '',
          ) ??
          DateTime.now(),
      format: map['format'] as String? ?? '',
      overs: (map['overs'] as num?)?.toInt() ?? 0,
      venue: map['venue'] as String? ?? '',
      tossWinnerTeamId: map['tossWinnerTeamId'] as String? ?? '',
      tossDecision: map['tossDecision'] as String? ?? '',
      result: map['result'] as String? ?? '',
      organiser: map['organiser'] as String? ?? '',
      scorer: map['scorer'] as String? ?? '',
      completed: map['completed'] as bool? ?? true,
      createdAt: DateTime.tryParse(
            map['createdAt'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }

  MatchModel copyWith({
    String? id,
    String? stumpsMatchId,
    String? team1Id,
    String? team2Id,
    DateTime? matchDate,
    String? format,
    int? overs,
    String? venue,
    String? tossWinnerTeamId,
    String? tossDecision,
    String? result,
    String? organiser,
    String? scorer,
    bool? completed,
    DateTime? createdAt,
  }) {
    return MatchModel(
      id: id ?? this.id,
      stumpsMatchId: stumpsMatchId ?? this.stumpsMatchId,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      matchDate: matchDate ?? this.matchDate,
      format: format ?? this.format,
      overs: overs ?? this.overs,
      venue: venue ?? this.venue,
      tossWinnerTeamId: tossWinnerTeamId ?? this.tossWinnerTeamId,
      tossDecision: tossDecision ?? this.tossDecision,
      result: result ?? this.result,
      organiser: organiser ?? this.organiser,
      scorer: scorer ?? this.scorer,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}