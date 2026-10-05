class PlayerModel {
  final String id;
  final String name;
  final bool active;
  final DateTime createdAt;
  final String photoUrl;

  const PlayerModel({
    required this.id,
    required this.name,
    this.active = true,
    required this.createdAt,
    this.photoUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'photoUrl': photoUrl,
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
      photoUrl: map['photoUrl'] as String? ?? '',
    );
  }

  PlayerModel copyWith({
    String? id,
    String? name,
    bool? active,
    DateTime? createdAt,
    String? photoUrl,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
