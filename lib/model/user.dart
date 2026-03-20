class User {
  final int id; // DB 고유 번호 (숫자)
  final String userId; // 로그인 아이디 (예: subjjang2)
  final String name;
  final String email; // 도메인
  final String role; // USER, ADMIN

  const User({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  // JSON -> 객체
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int, // 타입 캐스팅 명시
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
    );
  }

  // (선택 사항) 객체 -> JSON (보낼 때 필요하면 추가)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
    };
  }
}