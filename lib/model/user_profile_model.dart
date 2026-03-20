class UserProfileModel {

  final String userId;
  final String name;
  final String role; // 'ADMIN', 'USER', 'AUDITOR' 등

  UserProfileModel({

    required this.userId,
    required this.name,
    required this.role,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(

      userId: json['userId'],
      name: json['name'],
      role: json['role'],
    );
  }

  // 관리자 여부 확인용 헬퍼
  bool get isAdmin => role == 'ADMIN';
  bool get isAuditor => role == 'AUDITOR';
}