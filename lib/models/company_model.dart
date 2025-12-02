class Company {
  final String id;
  final String memberId;
  final String name;
  final String? industry;
  final String? location;
  final String? city;
  final String? area;
  final String? description;
  final String? website;
  final String? mobile;
  final String? email;
  final String? logoUrl;
  final String status;
  final int productsCount;
  final int views;
  final int connections;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Company({
    required this.id,
    required this.memberId,
    required this.name,
    this.industry,
    this.location,
    this.city,
    this.area,
    this.description,
    this.website,
    this.mobile,
    this.email,
    this.logoUrl,
    required this.status,
    this.productsCount = 0,
    this.views = 0,
    this.connections = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['_id']?.toString() ?? '',
      memberId: json['memberId']?.toString() ?? '',
      name: json['name'] ?? '',
      industry: json['industry'],
      location: json['location'],
      city: json['city'],
      area: json['area'],
      description: json['description'],
      website: json['website'],
      mobile: json['mobile'],
      email: json['email'],
      logoUrl: json['logoUrl'],
      status: json['status'] ?? 'UNDER_REVIEW',
      productsCount: json['productsCount'] ?? 0,
      views: json['views'] ?? 0,
      connections: json['connections'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'name': name,
      'industry': industry,
      'location': location,
      'city': city,
      'area': area,
      'description': description,
      'website': website,
      'mobile': mobile,
      'email': email,
      'logoUrl': logoUrl,
      'status': status,
      'productsCount': productsCount,
      'views': views,
      'connections': connections,
    };
  }

  String get displayLocation {
    final parts = <String>[];
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    } else if (location != null && location!.isNotEmpty) {
      parts.add(location!);
    }
    if (area != null && area!.isNotEmpty) {
      parts.add(area!);
    }
    return parts.join(', ');
  }

  String get displayIndustryLocation {
    final parts = <String>[];
    if (industry != null && industry!.isNotEmpty) {
      parts.add(industry!);
    }
    final loc = displayLocation;
    if (loc.isNotEmpty) {
      parts.add(loc);
    }
    return parts.join(' · ');
  }

  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Active';
      case 'UNDER_REVIEW':
      case 'PENDING':
        return 'Under Review';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }
}
