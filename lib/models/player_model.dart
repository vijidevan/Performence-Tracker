class PlayerModel {
  final String id;
  final String name;
  final bool active;
  final DateTime createdAt;

  const PlayerModel({
    required this.id,
    required this.name,
    this.active = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      createdAt: DateTime.tryParse(
            map['createdAt'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }

  PlayerModel copyWith({
    String? id,
    String? name,
    bool? active,
    DateTime? createdAt,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}