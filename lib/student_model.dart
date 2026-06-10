// STUDENT DATA MODEL
// Defines the structure of a Student object
class Student {
  final String id;
  final String name;
  final String course;

  Student({
    required this.id,
    required this.name,
    required this.course,
  });

  // Convert Student to string for storage
  String toStorageString() {
    return '$id|$name|$course';
  }

  // Create Student from storage string
  factory Student.fromStorageString(String str) {
    final parts = str.split('|');
    return Student(
      id: parts[0],
      name: parts[1],
      course: parts[2],
    );
  }
}