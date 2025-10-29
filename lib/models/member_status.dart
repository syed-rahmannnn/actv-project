// member_status.dart
import 'package:flutter/material.dart';

enum MemberStatus { pending, approved, rejected }

extension MemberStatusX on MemberStatus {
  String get value {
    switch (this) {
      case MemberStatus.pending:
        return 'pending';
      case MemberStatus.approved:
        return 'approved';
      case MemberStatus.rejected:
        return 'rejected';
    }
  }

  String get displayName {
    switch (this) {
      case MemberStatus.pending:
        return 'Pending';
      case MemberStatus.approved:
        return 'Approved';
      case MemberStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case MemberStatus.pending:
        return Colors.orange;
      case MemberStatus.approved:
        return Colors.green;
      case MemberStatus.rejected:
        return Colors.red;
    }
  }

  static MemberStatus from(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'approved':
        return MemberStatus.approved;
      case 'rejected':
        return MemberStatus.rejected;
      case 'pending':
      default:
        return MemberStatus.pending;
    }
  }

  static MemberStatus fromString(String raw) {
    return from(raw);
  }
}

// Helper functions for string-based status handling
String getStatusLabel(String? status) {
  switch ((status ?? '').trim().toLowerCase()) {
    case 'approved':
      return 'Approved';
    case 'rejected':
      return 'Rejected';
    case 'pending':
    default:
      return 'Pending';
  }
}

Color getStatusColor(String? status) {
  switch ((status ?? '').trim().toLowerCase()) {
    case 'approved':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    case 'pending':
    default:
      return Colors.orange;
  }
}

MemberStatus getCanonicalStatus(String? status) {
  return MemberStatusX.from(status ?? '');
}