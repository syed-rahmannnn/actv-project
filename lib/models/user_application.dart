// user_application.dart
import 'member_status.dart';

class UserApplication {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String state;
  final String district;
  final String block;
  final Map<String, dynamic> formData;
  MemberStatus status;

  UserApplication({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.state,
    required this.district,
    required this.block,
    required this.formData,
    required this.status,
  });

  factory UserApplication.fromJson(Map<String, dynamic> j) {
    return UserApplication(
      id: (j['_id'] ?? j['id']).toString(),
      fullName: j['fullName'] ?? '',
      email: j['email'] ?? '',
      phone: j['phone'] ?? '',
      state: j['state'] ?? '',
      district: j['district'] ?? '',
      block: j['block'] ?? '',
      formData: (j['formData'] as Map?)?.cast<String, dynamic>() ?? {},
      status: MemberStatusX.from(j['status'] ?? 'pending'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'state': state,
        'district': district,
        'block': block,
        'formData': formData,
        'status': status.value,
      };

  UserApplication copyWith({MemberStatus? status}) => UserApplication(
        id: id,
        fullName: fullName,
        email: email,
        phone: phone,
        state: state,
        district: district,
        block: block,
        formData: formData,
        status: status ?? this.status,
      );
}