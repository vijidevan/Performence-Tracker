class PlayerTeamModel {
  final String id;
  final String playerId;
  final String teamId;
  final bool active;
  final DateTime joinedAt;

  const PlayerTeamModel({
    required this.id,
    required this.playerId,
    required this.teamId,
    this.active = true,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playerId': playerId,
      'teamId': teamId,
      'active': active,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory PlayerTeamModel.fromMap(Map<String, dynamic> map) {
    return PlayerTeamModel(
      id: map['id'] as String? ?? '',
      playerId: map['playerId'] as String? ?? '',
      teamId: map['teamId'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      joinedAt: DateTime.tryParse(
            map['joinedAt'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }

  PlayerTeamModel copyWith({
    String? id,
    String? playerId,
    String? teamId,
    bool? active,
    DateTime? joinedAt,
  }) {
    return PlayerTeamModel(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      active: active ?? this.active,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}