import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String name;
  final bool active;
  final DateTime createdAt;

  const TeamModel({
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

  factory TeamModel.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['createdAt'];

    DateTime createdAt;

    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      createdAt =
          DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return TeamModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      createdAt: createdAt,
    );
  }

  TeamModel copyWith({
    String? id,
    String? name,
    bool? active,
    DateTime? createdAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}