class HomeModel {
  final String id;
  final String name;
  final String inviteCode;
  final String currentUserRole;
  final int memberCount;

  HomeModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.currentUserRole,
    required this.memberCount,
  });

  factory HomeModel.fromJson(Map<String, dynamic> json) {
    return HomeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      inviteCode: json['inviteCode'] ?? '',
      currentUserRole: json['currentUserRole'] ?? 'MEMBER',
      memberCount: json['memberCount'] ?? 1,
    );
  }

  bool get isOwner => currentUserRole == 'OWNER';
  bool get isAdmin => currentUserRole == 'ADMIN' || currentUserRole == 'OWNER';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'inviteCode': inviteCode,
    'currentUserRole': currentUserRole,
    'memberCount': memberCount,
  };
}

class HomeMemberModel {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String role;
  final String joinedAt;

  HomeMemberModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  factory HomeMemberModel.fromJson(Map<String, dynamic> json) {
    return HomeMemberModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      role: json['role'] ?? 'MEMBER',
      joinedAt: json['joinedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'fullName': fullName,
    'email': email,
    'avatarUrl': avatarUrl,
    'role': role,
    'joinedAt': joinedAt,
  };
}
