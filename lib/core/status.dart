import 'package:flutter/material.dart';

class MemberStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

/// Normalize any backend value to our lowercase enum.
/// Unknown/null -> pending
String normalizeStatus(String? value) {
  final s = (value ?? '').trim().toLowerCase();
  switch (s) {
    case MemberStatus.approved:
      return MemberStatus.approved;
    case MemberStatus.rejected:
      return MemberStatus.rejected;
    default:
      return MemberStatus.pending;
  }
}

bool isPendingStatus(String? s)  => normalizeStatus(s) == MemberStatus.pending;
bool isApprovedStatus(String? s) => normalizeStatus(s) == MemberStatus.approved;
bool isRejectedStatus(String? s) => normalizeStatus(s) == MemberStatus.rejected;

/// Short label for badges/cards
String getStatusDisplayText(String? s) {
  switch (normalizeStatus(s)) {
    case MemberStatus.approved:
      return 'Approved';
    case MemberStatus.rejected:
      return 'Rejected';
    default:
      return 'Pending';
  }
}

/// Color helper for chips/badges
Color getStatusColor(String? s) {
  switch (normalizeStatus(s)) {
    case MemberStatus.approved:
      return const Color(0xFF16A34A); // green-600
    case MemberStatus.rejected:
      return const Color(0xFFDC2626); // red-600
    default:
      return const Color(0xFFF59E0B); // amber-500
  }
}
