class UserModel {
  final String username;
  final String? fullName;
  final String? email;
  final String? mobileNumber;
  final String? role;
  final String? profilePic;

  UserModel({
    required this.username,
    this.fullName,
    this.email,
    this.mobileNumber,
    this.role,
    this.profilePic,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      fullName: json['full_name'],
      email: json['email'],
      mobileNumber: json['mobile_number'],
      role: json['role'],
      profilePic: json['profile_pic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'full_name': fullName,
      'email': email,
      'mobile_number': mobileNumber,
      'role': role,
      'profile_pic': profilePic,
    };
  }

  UserModel copyWith({
    String? username,
    String? fullName,
    String? email,
    String? mobileNumber,
    String? role,
    String? profilePic,
  }) {
    return UserModel(
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      role: role ?? this.role,
      profilePic: profilePic ?? this.profilePic,
    );
  }
}
