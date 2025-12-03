import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company_model.dart';

class CompanySelectionProvider extends ChangeNotifier {
  Company? _activeCompany;

  Company? get activeCompany => _activeCompany;
  String? get currentCompanyId => _activeCompany?.id;

  /// Set the active company
  void setActiveCompany(Company company) {
    _activeCompany = company;
    _saveToPrefs(company.id);
    notifyListeners();
    print('✅ Active company set to: ${company.name} (${company.id})');
  }

  /// Load saved company ID from SharedPreferences (to be used with API call)
  Future<String?> loadSavedCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('current_company_id');
    if (savedId != null) {
      print('📦 Loaded saved company ID: $savedId');
    }
    return savedId;
  }

  /// Save company ID to SharedPreferences
  Future<void> _saveToPrefs(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_company_id', id);
  }

  /// Clear the active company
  void clearActiveCompany() {
    _activeCompany = null;
    _clearFromPrefs();
    notifyListeners();
  }

  /// Clear from SharedPreferences
  Future<void> _clearFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_company_id');
  }
}
