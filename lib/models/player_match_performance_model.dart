class PlayerMatchPerformanceModel {
  final String id;
  final String matchId;
  final String playerId;
  final String teamId;

  final int runs;
  final int ballsFaced;
  final int fours;
  final int sixes;
  final double strikeRate;
  final String dismissal;

  final double overs;
  final int maidens;
  final int runsConceded;
  final int wickets;
  final double economy;
  final int dotBalls;
  final int bowlingFours;
  final int bowlingSixes;
  final int wides;
  final int noBalls;

  final int catches;
  final int caughtAndBowled;
  final int runOuts;
  final int stumpings;

  final DateTime createdAt;

  const PlayerMatchPerformanceModel({
    required this.id,
    required this.matchId,
    required this.playerId,
    required this.teamId,
    this.runs = 0,
    this.ballsFaced = 0,
    this.fours = 0,
    this.sixes = 0,
    this.strikeRate = 0.0,
    this.dismissal = '',
    this.overs = 0.0,
    this.maidens = 0,
    this.runsConceded = 0,
    this.wickets = 0,
    this.economy = 0.0,
    this.dotBalls = 0,
    this.bowlingFours = 0,
    this.bowlingSixes = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.catches = 0,
    this.caughtAndBowled = 0,
    this.runOuts = 0,
    this.stumpings = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'playerId': playerId,
      'teamId': teamId,
      'runs': runs,
      'ballsFaced': ballsFaced,
      'fours': fours,
      'sixes': sixes,
      'strikeRate': strikeRate,
      'dismissal': dismissal,
      'overs': overs,
      'maidens': maidens,
      'runsConceded': runsConceded,
      'wickets': wickets,
      'economy': economy,
      'dotBalls': dotBalls,
      'bowlingFours': bowlingFours,
      'bowlingSixes': bowlingSixes,
      'wides': wides,
      'noBalls': noBalls,
      'catches': catches,
      'caughtAndBowled': caughtAndBowled,
      'runOuts': runOuts,
      'stumpings': stumpings,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlayerMatchPerformanceModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return PlayerMatchPerformanceModel(
      id: map['id'] as String? ?? '',
      matchId: map['matchId'] as String? ?? '',
      playerId: map['playerId'] as String? ?? '',
      teamId: map['teamId'] as String? ?? '',
      runs: (map['runs'] as num?)?.toInt() ?? 0,
      ballsFaced:
          (map['ballsFaced'] as num?)?.toInt() ?? 0,
      fours: (map['fours'] as num?)?.toInt() ?? 0,
      sixes: (map['sixes'] as num?)?.toInt() ?? 0,
      strikeRate:
          (map['strikeRate'] as num?)?.toDouble() ?? 0.0,
      dismissal: map['dismissal'] as String? ?? '',
      overs: (map['overs'] as num?)?.toDouble() ?? 0.0,
      maidens: (map['maidens'] as num?)?.toInt() ?? 0,
      runsConceded:
          (map['runsConceded'] as num?)?.toInt() ?? 0,
      wickets: (map['wickets'] as num?)?.toInt() ?? 0,
      economy:
          (map['economy'] as num?)?.toDouble() ?? 0.0,
      dotBalls:
          (map['dotBalls'] as num?)?.toInt() ?? 0,
      bowlingFours:
          (map['bowlingFours'] as num?)?.toInt() ?? 0,
      bowlingSixes:
          (map['bowlingSixes'] as num?)?.toInt() ?? 0,
      wides: (map['wides'] as num?)?.toInt() ?? 0,
      noBalls: (map['noBalls'] as num?)?.toInt() ?? 0,
      catches: (map['catches'] as num?)?.toInt() ?? 0,
      caughtAndBowled:
          (map['caughtAndBowled'] as num?)?.toInt() ?? 0,
      runOuts: (map['runOuts'] as num?)?.toInt() ?? 0,
      stumpings:
          (map['stumpings'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(
            map['createdAt'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }

  PlayerMatchPerformanceModel copyWith({
    String? id,
    String? matchId,
    String? playerId,
    String? teamId,
    int? runs,
    int? ballsFaced,
    int? fours,
    int? sixes,
    double? strikeRate,
    String? dismissal,
    double? overs,
    int? maidens,
    int? runsConceded,
    int? wickets,
    double? economy,
    int? dotBalls,
    int? bowlingFours,
    int? bowlingSixes,
    int? wides,
    int? noBalls,
    int? catches,
    int? caughtAndBowled,
    int? runOuts,
    int? stumpings,
    DateTime? createdAt,
  }) {
    return PlayerMatchPerformanceModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      runs: runs ?? this.runs,
      ballsFaced: ballsFaced ?? this.ballsFaced,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
      strikeRate: strikeRate ?? this.strikeRate,
      dismissal: dismissal ?? this.dismissal,
      overs: overs ?? this.overs,
      maidens: maidens ?? this.maidens,
      runsConceded: runsConceded ?? this.runsConceded,
      wickets: wickets ?? this.wickets,
      economy: economy ?? this.economy,
      dotBalls: dotBalls ?? this.dotBalls,
      bowlingFours: bowlingFours ?? this.bowlingFours,
      bowlingSixes: bowlingSixes ?? this.bowlingSixes,
      wides: wides ?? this.wides,
      noBalls: noBalls ?? this.noBalls,
      catches: catches ?? this.catches,
      caughtAndBowled:
          caughtAndBowled ?? this.caughtAndBowled,
      runOuts: runOuts ?? this.runOuts,
      stumpings: stumpings ?? this.stumpings,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}