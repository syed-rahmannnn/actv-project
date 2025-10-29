// Shared status constants and normalization, reusing existing utilities
import '../utils/member_status.dart' as util;

class MemberStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

String normalizeStatus(String? s) => util.normalizeStatus(s);