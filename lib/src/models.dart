class AdminProfile {
  const AdminProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    required this.role,
  });

  final String id;
  final String email;
  final String fullName;
  final String username;
  final String role;

  String get displayName => fullName.isNotEmpty
      ? fullName
      : username.isNotEmpty
      ? username
      : email;

  factory AdminProfile.fromMap(Map<String, dynamic> map) {
    return AdminProfile(
      id: (map['id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      username: (map['username'] ?? '').toString(),
      role: (map['role'] ?? 'user').toString(),
    );
  }
}

class AdminAdoption {
  const AdminAdoption({
    required this.id,
    required this.userId,
    required this.petName,
    required this.petType,
    required this.breed,
    required this.city,
    required this.status,
    required this.createdAt,
    this.photoUrls = const [],
    this.ownerName = 'User',
    this.reportCount = 0,
  });

  final String id;
  final String userId;
  final String petName;
  final String petType;
  final String breed;
  final String city;
  final String status;
  final DateTime? createdAt;
  final List<String> photoUrls;
  final String ownerName;
  final int reportCount;

  factory AdminAdoption.fromMap(Map<String, dynamic> map) {
    return AdminAdoption(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      petName: (map['pet_name'] ?? '').toString(),
      petType: (map['pet_type'] ?? '').toString(),
      breed: (map['breed'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
      photoUrls:
          (map['photo_urls'] as List?)
              ?.map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList() ??
          const [],
    );
  }

  AdminAdoption copyWith({String? ownerName, int? reportCount}) {
    return AdminAdoption(
      id: id,
      userId: userId,
      petName: petName,
      petType: petType,
      breed: breed,
      city: city,
      status: status,
      createdAt: createdAt,
      photoUrls: photoUrls,
      ownerName: ownerName ?? this.ownerName,
      reportCount: reportCount ?? this.reportCount,
    );
  }
}

class AdoptionReportItem {
  const AdoptionReportItem({
    required this.id,
    required this.adoptionId,
    required this.reporterUserId,
    required this.reason,
    required this.createdAt,
    this.petName = '',
    this.postStatus = '',
    this.reporterName = 'User',
  });

  final String id;
  final String adoptionId;
  final String reporterUserId;
  final String reason;
  final DateTime? createdAt;
  final String petName;
  final String postStatus;
  final String reporterName;

  factory AdoptionReportItem.fromMap(Map<String, dynamic> map) {
    return AdoptionReportItem(
      id: (map['id'] ?? '').toString(),
      adoptionId: (map['adoption_id'] ?? '').toString(),
      reporterUserId: (map['reporter_user_id'] ?? '').toString(),
      reason: (map['reason'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
    );
  }

  AdoptionReportItem copyWith({
    String? petName,
    String? postStatus,
    String? reporterName,
  }) {
    return AdoptionReportItem(
      id: id,
      adoptionId: adoptionId,
      reporterUserId: reporterUserId,
      reason: reason,
      createdAt: createdAt,
      petName: petName ?? this.petName,
      postStatus: postStatus ?? this.postStatus,
      reporterName: reporterName ?? this.reporterName,
    );
  }
}

class UserReportItem {
  const UserReportItem({
    required this.id,
    required this.reportedUserId,
    required this.reporterUserId,
    required this.reason,
    required this.details,
    required this.createdAt,
    this.reportedUserName = 'User',
    this.reporterName = 'User',
  });

  final String id;
  final String reportedUserId;
  final String reporterUserId;
  final String reason;
  final String details;
  final DateTime? createdAt;
  final String reportedUserName;
  final String reporterName;

  factory UserReportItem.fromMap(Map<String, dynamic> map) {
    return UserReportItem(
      id: (map['id'] ?? '').toString(),
      reportedUserId: (map['reported_user_id'] ?? '').toString(),
      reporterUserId: (map['reporter_user_id'] ?? '').toString(),
      reason: (map['reason'] ?? '').toString(),
      details: (map['details'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
    );
  }

  UserReportItem copyWith({String? reportedUserName, String? reporterName}) {
    return UserReportItem(
      id: id,
      reportedUserId: reportedUserId,
      reporterUserId: reporterUserId,
      reason: reason,
      details: details,
      createdAt: createdAt,
      reportedUserName: reportedUserName ?? this.reportedUserName,
      reporterName: reporterName ?? this.reporterName,
    );
  }
}

class FeedbackItem {
  const FeedbackItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.createdAt,
    this.userName = 'User',
  });

  final String id;
  final String userId;
  final String type;
  final String message;
  final DateTime? createdAt;
  final String userName;

  factory FeedbackItem.fromMap(Map<String, dynamic> map) {
    return FeedbackItem(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      type: (map['type'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
    );
  }

  FeedbackItem copyWith({String? userName}) {
    return FeedbackItem(
      id: id,
      userId: userId,
      type: type,
      message: message,
      createdAt: createdAt,
      userName: userName ?? this.userName,
    );
  }
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    required this.role,
    required this.accountStatus,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String username;
  final String role;
  final String accountStatus;
  final DateTime? createdAt;

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: (map['id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      username: (map['username'] ?? '').toString(),
      role: (map['role'] ?? '').toString(),
      accountStatus: (map['account_status'] ?? 'active').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
    );
  }
}
