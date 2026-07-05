/// user_model.dart
/// Location: lib/model/user_model.dart

class User {
  final int? id;
  final String uid;
  final String name;
  final String email;
  final String password;
  final String? height;
  final String? weight;
  final String? createdAt;
  final String? profileImage;

  User({
    this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.password,
    this.height,
    this.weight,
    this.createdAt,
    this.profileImage,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'uid': uid,
    'name': name,
    'email': email,
    'password': password,
    'height': height,
    'weight': weight,
    'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    'profileImage': profileImage,
  };

  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'],
    uid: map['uid'],
    name: map['name'],
    email: map['email'],
    password: map['password'],
    height: map['height'],
    weight: map['weight'],
    createdAt: map['createdAt'],
    profileImage: map['profileImage'],
  );
}