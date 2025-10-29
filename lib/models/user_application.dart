import '../core/status.dart';

class UserApplication {
  final String id;
  final String status;

  UserApplication({
    required this.id,
    required this.status,
  });

  factory UserApplication.fromJson(Map<String, dynamic> json) {
    final rawStatus = normalizeStatus(json['status'] as String?);
    final normalized = rawStatus.isEmpty ? MemberStatus.pending : rawStatus;
    return UserApplication(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      status: normalized,
    );
  }
}