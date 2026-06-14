/// member_model.dart
/// Location: lib/models/member_model.dart
///
/// Data model for a Shredded Squad member.
/// Maps to the SQLite 'members' table.

class Member {
  final int? id;           // null until inserted into DB
  final String name;
  final String email;
  final String? phone;
  final double? height;        // cm
  final double? weight;        // kg
  final double? targetWeight;  // kg
  final String activityLevel;  // Beginner / Intermediate / Advanced
  final String joinDate;       // ISO 8601 string
  final String? goal;          // e.g. "Lose weight", "Build muscle"

  const Member({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.height,
    this.weight,
    this.targetWeight,
    this.activityLevel = 'Beginner',
    required this.joinDate,
    this.goal,
  });

  // ─── Serialisation ────────────────────────────────────────────────────────

  /// Converts Member to a Map for SQLite insertion/update.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'height': height,
      'weight': weight,
      'targetWeight': targetWeight,
      'activityLevel': activityLevel,
      'joinDate': joinDate,
      'goal': goal,
    };
  }

  /// Constructs a Member from a SQLite row map.
  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      height: map['height'] as double?,
      weight: map['weight'] as double?,
      targetWeight: map['targetWeight'] as double?,
      activityLevel: map['activityLevel'] as String? ?? 'Beginner',
      joinDate: map['joinDate'] as String,
      goal: map['goal'] as String?,
    );
  }

  /// Returns a copy of this Member with updated fields.
  Member copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    double? height,
    double? weight,
    double? targetWeight,
    String? activityLevel,
    String? joinDate,
    String? goal,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      activityLevel: activityLevel ?? this.activityLevel,
      joinDate: joinDate ?? this.joinDate,
      goal: goal ?? this.goal,
    );
  }

  /// Initials from name for the avatar circle (e.g. "John Doe" → "JD")
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}