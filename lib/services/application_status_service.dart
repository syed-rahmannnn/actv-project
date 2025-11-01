import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_service.dart';

class ApplicationStatusService {
  static Future<ApplicationStatusResponse> fetchApplicationStatus() async {
    // Get user data from AuthService
    final userData = await AuthService.getUserData();
    if (userData == null) {
      throw Exception('User not logged in');
    }

    // Get user ID from userData (can be 'id', 'memberId', or '_id')
    final String? userId =
        userData['id']?.toString() ??
        userData['memberId']?.toString() ??
        userData['_id']?.toString();

    if (userId == null) {
      throw Exception('User ID not found');
    }

    // Get authentication token
    final String? token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/applications/user/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return ApplicationStatusResponse.fromJson(data);
    } else {
      throw Exception(
        'Failed to load application status: ${response.statusCode}',
      );
    }
  }
}

class ApplicationStatusResponse {
  final bool success;
  final List<ApplicationData> applications;
  final int count;

  ApplicationStatusResponse({
    required this.success,
    required this.applications,
    required this.count,
  });

  factory ApplicationStatusResponse.fromJson(Map<String, dynamic> json) {
    return ApplicationStatusResponse(
      success: json['success'] ?? false,
      applications:
          (json['applications'] as List?)
              ?.map((app) => ApplicationData.fromJson(app))
              .toList() ??
          [],
      count: json['count'] ?? 0,
    );
  }
}

class ApplicationData {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String state;
  final String district;
  final String block;
  final Map<String, dynamic> formData;
  final String status;
  final AdminData? assignedBlockAdmin;
  final AdminData? assignedDistrictAdmin;
  final AdminData? assignedStateAdmin;
  final String? rejectionReason;
  final DateTime? blockApprovedAt;
  final DateTime? districtApprovedAt;
  final DateTime? stateApprovedAt;
  final ReviewedBy? reviewedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApplicationData({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.state,
    required this.district,
    required this.block,
    required this.formData,
    required this.status,
    this.assignedBlockAdmin,
    this.assignedDistrictAdmin,
    this.assignedStateAdmin,
    this.rejectionReason,
    this.blockApprovedAt,
    this.districtApprovedAt,
    this.stateApprovedAt,
    this.reviewedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApplicationData.fromJson(Map<String, dynamic> json) {
    return ApplicationData(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      block: json['block'] ?? '',
      formData: json['formData'] ?? {},
      status: json['status'] ?? 'Pending-Block',
      assignedBlockAdmin: json['assignedBlockAdmin'] != null
          ? AdminData.fromJson(json['assignedBlockAdmin'])
          : null,
      assignedDistrictAdmin: json['assignedDistrictAdmin'] != null
          ? AdminData.fromJson(json['assignedDistrictAdmin'])
          : null,
      assignedStateAdmin: json['assignedStateAdmin'] != null
          ? AdminData.fromJson(json['assignedStateAdmin'])
          : null,
      rejectionReason: json['rejectionReason'],
      blockApprovedAt: json['blockApprovedAt'] != null
          ? DateTime.parse(json['blockApprovedAt'])
          : null,
      districtApprovedAt: json['districtApprovedAt'] != null
          ? DateTime.parse(json['districtApprovedAt'])
          : null,
      stateApprovedAt: json['stateApprovedAt'] != null
          ? DateTime.parse(json['stateApprovedAt'])
          : null,
      reviewedBy: json['reviewedBy'] != null
          ? ReviewedBy.fromJson(json['reviewedBy'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Helper methods to determine status
  bool get isBlockApproved =>
      blockApprovedAt != null || status != 'Pending-Block';
  bool get isDistrictApproved =>
      districtApprovedAt != null ||
      ['Pending-State', 'Approved'].contains(status);
  bool get isStateApproved => stateApprovedAt != null || status == 'Approved';
  bool get isRejected => status == 'Rejected';

  String get currentStage {
    if (status == 'Rejected') return 'Rejected';
    if (status == 'Approved') return 'Approved';
    if (status == 'Pending-State') return 'State Admin Review';
    if (status == 'Pending-District') return 'District Admin Review';
    return 'Block Admin Review';
  }

  double get progressPercentage {
    switch (status) {
      case 'Pending-Block':
        return 0.25;
      case 'Pending-District':
        return 0.5;
      case 'Pending-State':
        return 0.75;
      case 'Approved':
        return 1.0;
      case 'Rejected':
        return 0.0;
      default:
        return 0.25;
    }
  }
}

class AdminData {
  final String id;
  final String fullName;
  final String email;

  AdminData({required this.id, required this.fullName, required this.email});

  factory AdminData.fromJson(Map<String, dynamic> json) {
    return AdminData(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class ReviewedBy {
  final String? blockAdmin;
  final String? districtAdmin;
  final String? stateAdmin;

  ReviewedBy({this.blockAdmin, this.districtAdmin, this.stateAdmin});

  factory ReviewedBy.fromJson(Map<String, dynamic> json) {
    return ReviewedBy(
      blockAdmin: json['blockAdmin'],
      districtAdmin: json['districtAdmin'],
      stateAdmin: json['stateAdmin'],
    );
  }
}
