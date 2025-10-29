import 'package:flutter/material.dart';

/// Status constants and utilities for consistent member status handling
/// across all Block Admin screens.
class MemberStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  
  // Block-specific status values that should be treated as pending
  static const List<String> pendingStatuses = [
    'pending',
    'pending-block',
    'pending-district',
    'pending-state',
    'submitted',
  ];
  
  // Status values that should be treated as approved
  static const List<String> approvedStatuses = [
    'Approved',
    'approved',
  ];
  
  // Status values that should be treated as rejected
  static const List<String> rejectedStatuses = [
    'Rejected',
    'rejected',
  ];
}

/// Normalizes status strings to lowercase and trims whitespace
String normalizeStatus(String? status) {
  return (status ?? '').trim().toLowerCase();
}

/// Determines the canonical status from any status string
String getCanonicalStatus(String? status) {
  final normalized = normalizeStatus(status);
  
  // Check for approved statuses first
  for (final approvedStatus in MemberStatus.approvedStatuses) {
    if (normalized == normalizeStatus(approvedStatus)) {
      return MemberStatus.approved;
    }
  }
  
  // Check for rejected statuses
  for (final rejectedStatus in MemberStatus.rejectedStatuses) {
    if (normalized == normalizeStatus(rejectedStatus) || 
        normalized.contains('rejected')) {
      return MemberStatus.rejected;
    }
  }
  
  // Check for pending statuses
  for (final pendingStatus in MemberStatus.pendingStatuses) {
    if (normalized == normalizeStatus(pendingStatus)) {
      return MemberStatus.pending;
    }
  }

  // Fallback: treat any status starting with 'pending' as pending
  if (normalized.startsWith('pending')) {
    return MemberStatus.pending;
  }
  
  // Default to pending for any unknown status
  return MemberStatus.pending;
}

/// Helper functions for status checking
bool isPendingStatus(String? status) {
  return getCanonicalStatus(status) == MemberStatus.pending;
}

bool isApprovedStatus(String? status) {
  return getCanonicalStatus(status) == MemberStatus.approved;
}

bool isRejectedStatus(String? status) {
  return getCanonicalStatus(status) == MemberStatus.rejected;
}

/// Gets the display text for a status
String getStatusDisplayText(String? status) {
  switch (getCanonicalStatus(status)) {
    case MemberStatus.approved:
      return 'Approved';
    case MemberStatus.rejected:
      return 'Rejected';
    case MemberStatus.pending:
    default:
      return 'Pending';
  }
}

/// Gets the appropriate color for a status
class StatusColors {
  static const approved = Color(0xFF16A34A); // Green
  static const rejected = Color(0xFFDC2626); // Red  
  static const pending = Color(0xFF1E88FF);  // Blue
}

/// Gets the color for a given status
Color getStatusColor(String? status) {
  switch (getCanonicalStatus(status)) {
    case MemberStatus.approved:
      return StatusColors.approved;
    case MemberStatus.rejected:
      return StatusColors.rejected;
    case MemberStatus.pending:
    default:
      return StatusColors.pending;
  }
}