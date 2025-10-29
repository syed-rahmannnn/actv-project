import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/user_application.dart';
import '../models/member_status.dart';
import 'api_service.dart';

class ApplicationStore extends ChangeNotifier {
  final ApiService api;

  final List<UserApplication> _pending = [];
  final List<UserApplication> _approved = [];
  final List<UserApplication> _rejected = [];

  int _pendingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;

  UnmodifiableListView<UserApplication> get pending => UnmodifiableListView(_pending);
  UnmodifiableListView<UserApplication> get approved => UnmodifiableListView(_approved);
  UnmodifiableListView<UserApplication> get rejected => UnmodifiableListView(_rejected);

  int get pendingCount => _pendingCount;
  int get approvedCount => _approvedCount;
  int get rejectedCount => _rejectedCount;

  ApplicationStore(this.api);

  Future<void> bootstrap() async {
    await Future.wait([
      refreshStats(),
      refreshList(MemberStatus.pending),
      refreshList(MemberStatus.approved),
      refreshList(MemberStatus.rejected),
    ]);
  }

  Future<void> refreshStats() async {
    final m = await ApiService.fetchStats();
    _pendingCount = (m['pending'] ?? m['data']?['pending'] ?? 0) as int;
    _approvedCount = (m['approved'] ?? m['data']?['approved'] ?? 0) as int;
    _rejectedCount = (m['rejected'] ?? m['data']?['rejected'] ?? 0) as int;
    notifyListeners();
  }

  Future<void> refreshList(MemberStatus s) async {
    final raw = await ApiService.fetchByStatus(s.value);
    final list = raw.map((e) => UserApplication.fromJson(e as Map<String, dynamic>)).cast<UserApplication>().toList();
    switch (s) {
      case MemberStatus.pending:
        _pending
          ..clear()
          ..addAll(list);
        break;
      case MemberStatus.approved:
        _approved
          ..clear()
          ..addAll(list);
        break;
      case MemberStatus.rejected:
        _rejected
          ..clear()
          ..addAll(list);
        break;
    }
    notifyListeners();
  }

  // --- Mutations (optimistic) ---
  Future<void> approve(String id) async {
    final app = _removeFromAll(id);
    if (app != null) {
      final approvedApp = app.copyWith(status: MemberStatus.approved);
      _approved.insert(0, approvedApp);
      _pendingCount = (_pendingCount - 1).clamp(0, 1 << 30);
      _approvedCount += 1;
      notifyListeners();
    }
    try {
      await ApiService.approve(id);
    } catch (e) {
      // rollback if server failed
      if (app != null) {
        _approved.removeWhere((a) => a.id == id);
        _pending.insert(0, app);
        _pendingCount += 1;
        _approvedCount = (_approvedCount - 1).clamp(0, 1 << 30);
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> reject(String id) async {
    final app = _removeFromAll(id);
    if (app != null) {
      final rejectedApp = app.copyWith(status: MemberStatus.rejected);
      _rejected.insert(0, rejectedApp);
      _pendingCount = (_pendingCount - 1).clamp(0, 1 << 30);
      _rejectedCount += 1;
      notifyListeners();
    }
    try {
      await ApiService.reject(id);
    } catch (e) {
      if (app != null) {
        _rejected.removeWhere((a) => a.id == id);
        _pending.insert(0, app);
        _pendingCount += 1;
        _rejectedCount = (_rejectedCount - 1).clamp(0, 1 << 30);
        notifyListeners();
      }
      rethrow;
    }
  }

  UserApplication? _removeFromAll(String id) {
    final r1 = _takeOut(_pending, id);
    final r2 = _takeOut(_approved, id);
    final r3 = _takeOut(_rejected, id);
    return r1 ?? r2 ?? r3;
  }

  UserApplication? _takeOut(List<UserApplication> list, String id) {
    final i = list.indexWhere((e) => e.id == id);
    if (i != -1) return list.removeAt(i);
    return null;
  }
}