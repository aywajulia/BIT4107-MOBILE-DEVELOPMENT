/// personal_record_model.dart
/// Data model for a Personal Record entry.
/// Maps directly to the 'personal_records' table in SQLite.
library;

class PersonalRecord {
  final int? id;             // null until inserted into DB
  final String exercise;     // e.g. "Bench Press"
  final double value;        // e.g. 80.0
  final String unit;         // e.g. "kg", "min", "reps"
  final String date;         // e.g. "2026-06-14"
  final String? notes;       // optional e.g. "Personal best, full depth"

  const PersonalRecord({
    this.id,
    required this.exercise,
    required this.value,
    required this.unit,
    required this.date,
    this.notes,
  });

  /// Convert to Map for SQLite INSERT / UPDATE
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'exercise': exercise,
    'value': value,
    'unit': unit,
    'date': date,
    'notes': notes,
  };

  /// Build a PersonalRecord from a SQLite row Map
  factory PersonalRecord.fromMap(Map<String, dynamic> map) =>
      PersonalRecord(
        id: map['id'] as int?,
        exercise: map['exercise'] as String,
        value: (map['value'] as num).toDouble(),
        unit: map['unit'] as String,
        date: map['date'] as String,
        notes: map['notes'] as String?,
      );

  /// e.g. "80 kg" or "24.5 min"
  String get displayValue =>
      '${value % 1 == 0 ? value.toInt() : value} $unit';
}