class AdoptionRequest {
  const AdoptionRequest({
    required this.id,
    required this.userId,
    required this.petName,
    required this.petType,
    required this.breed,
    required this.city,
    required this.status,
    required this.createdAt,
    required this.photoUrls,
    required this.applicantName,
    required this.applicantEmail,
    required this.reportCount,
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
  final String applicantName;
  final String applicantEmail;
  final int reportCount;
}
