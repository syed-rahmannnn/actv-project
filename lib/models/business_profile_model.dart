class BusinessProfile {
  final String businessId;
  final String name;
  final String? tagline;
  final String? description;
  final String? industry;
  final String? city;
  final String? location;
  final String? area;
  final String? mobile;
  final String? logoUrl;
  final String? website;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BusinessProfile({
    required this.businessId,
    required this.name,
    this.tagline,
    this.description,
    this.industry,
    this.city,
    this.location,
    this.area,
    this.mobile,
    this.logoUrl,
    this.website,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      businessId: json['memberId']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['organizationName'] ?? json['name'] ?? '',
      tagline: json['tagline'],
      description: json['businessDescription'] ?? json['description'],
      industry: json['businessType'] ?? json['industry'],
      city: json['city'],
      location: json['location'],
      area: json['area'],
      mobile: json['mobile'],
      logoUrl: json['logoUrl'],
      website: json['website'] ?? json['businessWebsite'],
      status: json['status'] ?? 'UNDER_REVIEW',
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
      'businessId': businessId,
      'name': name,
      'tagline': tagline,
      'description': description,
      'industry': industry,
      'city': city,
      'location': location,
      'area': area,
      'mobile': mobile,
      'logoUrl': logoUrl,
      'website': website,
      'status': status,
    };
  }

  String get displayIndustryLocation {
    final parts = <String>[];
    if (industry != null && industry!.isNotEmpty) parts.add(industry!);
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    } else if (location != null && location!.isNotEmpty) {
      parts.add(location!);
    }
    return parts.join(' • ');
  }

  String get displayBusinessTypeAndMobile {
    final parts = <String>[];
    if (industry != null && industry!.isNotEmpty) parts.add(industry!);
    if (mobile != null && mobile!.isNotEmpty) parts.add(mobile!);
    return parts.join(' • ');
  }

  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'UNDER_REVIEW':
      case 'PENDING':
        return 'Under Review';
      case 'APPROVED':
      case 'ACTIVE':
        return 'Active';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }
}

class BusinessMetrics {
  final int profileViews;
  final double profileViewsChangePercent;
  final int productsCount;
  final int featuredProductsCount;

  BusinessMetrics({
    required this.profileViews,
    required this.profileViewsChangePercent,
    required this.productsCount,
    required this.featuredProductsCount,
  });

  factory BusinessMetrics.fromJson(Map<String, dynamic> json) {
    return BusinessMetrics(
      profileViews: json['profileViews'] ?? 0,
      profileViewsChangePercent: (json['profileViewsChangePercent'] ?? 0)
          .toDouble(),
      productsCount: json['productsCount'] ?? 0,
      featuredProductsCount: json['featuredProductsCount'] ?? 0,
    );
  }

  String get profileViewsChangeDisplay {
    if (profileViewsChangePercent == 0) return 'No change';
    final sign = profileViewsChangePercent > 0 ? '+' : '';
    return '$sign${profileViewsChangePercent.toStringAsFixed(1)}% this week';
  }

  String get featuredProductsDisplay {
    if (featuredProductsCount == 0) return '';
    return '$featuredProductsCount featured';
  }
}

class BusinessAssociation {
  final String id;
  final String name;
  final String role;
  final String location;
  final String? logoUrl;

  BusinessAssociation({
    required this.id,
    required this.name,
    required this.role,
    required this.location,
    this.logoUrl,
  });

  factory BusinessAssociation.fromJson(Map<String, dynamic> json) {
    return BusinessAssociation(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      location: json['location'] ?? '',
      logoUrl: json['logoUrl'],
    );
  }

  String get displayRoleLocation => '$role  •  $location';
}

class CompanyInfo {
  final String id;
  final String name;
  final String? businessType;
  final String? mobile;
  final String status;

  CompanyInfo({
    required this.id,
    required this.name,
    this.businessType,
    this.mobile,
    required this.status,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['organizationName'] ?? json['name'] ?? '',
      businessType: json['businessType'],
      mobile: json['mobile'],
      status: json['status'] ?? 'ACTIVE',
    );
  }
}
