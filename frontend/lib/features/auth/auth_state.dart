enum AuthStatus {
  initializing,
  authenticated,
  unauthenticated,
  sessionExpired,
  userNotFound,
  accountDisabled,
  membershipRemoved,
}

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String displayName;
  final String username;
  final String status;
  final String? avatarUrl;
  final String? phoneNumber;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    String? displayName,
    String? username,
    String? status,
    this.avatarUrl,
    this.phoneNumber,
  })  : displayName = displayName ?? fullName,
        username = username ?? '',
        status = status ?? 'ACTIVE';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final fn = json['fullName'] as String? ?? json['display_name'] as String? ?? '';
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: fn,
      displayName: json['displayName'] as String? ?? json['display_name'] as String? ?? fn,
      username: json['username'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      phoneNumber: json['phoneNumber'] as String? ?? json['phone_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'displayName': displayName,
      'username': username,
      'status': status,
      'avatarUrl': avatarUrl,
      'phoneNumber': phoneNumber,
    };
  }
}

class AuthState {
  final AuthStatus status;
  final bool isLoading;
  final UserProfile? user;
  final String? errorMessage;
  final String? verificationNotice;
  final String? activeRoomId;

  const AuthState({
    AuthStatus? status,
    bool? isAuthenticated,
    this.isLoading = false,
    this.user,
    this.errorMessage,
    this.verificationNotice,
    this.activeRoomId,
  }) : status = status ??
            (isAuthenticated == true
                ? AuthStatus.authenticated
                : (isAuthenticated == false
                    ? AuthStatus.unauthenticated
                    : AuthStatus.initializing));

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUserNotFound => status == AuthStatus.userNotFound;
  bool get isAccountDisabled => status == AuthStatus.accountDisabled;
  bool get isSessionExpired => status == AuthStatus.sessionExpired;
  bool get isMembershipRemoved => status == AuthStatus.membershipRemoved;

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoading,
    bool? isAuthenticated,
    UserProfile? user,
    String? errorMessage,
    String? verificationNotice,
    String? activeRoomId,
  }) {
    AuthStatus effectiveStatus = status ?? this.status;
    if (status == null && isAuthenticated != null) {
      effectiveStatus = isAuthenticated ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    }
    return AuthState(
      status: effectiveStatus,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
      verificationNotice: verificationNotice ?? this.verificationNotice,
      activeRoomId: activeRoomId ?? this.activeRoomId,
    );
  }
}
