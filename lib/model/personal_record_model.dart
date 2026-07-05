/// personal_record_model.dart
/// Location: lib/model/personal_record_model.dart
library;

class PersonalRecord {
  final int? id;
  final String exercise;
  final double value;
  final String unit;
  final String date;
  final String? notes;

  const PersonalRecord({
    this.id,
    required this.exercise,
    required this.value,
    required this.unit,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'exercise': exercise,
    'value': value,
    'unit': unit,
    'date': date,
    'notes': notes,
  };

  factory PersonalRecord.fromMap(Map<String, dynamic> map) => PersonalRecord(
    id: map['id'] as int?,
    exercise: map['exercise'] as String,
    value: (map['value'] as num).toDouble(),
    unit: map['unit'] as String,
    date: map['date'] as String,
    notes: map['notes'] as String?,
  );

  String get displayValue =>
      '${value % 1 == 0 ? value.toInt() : value} $unit';
}