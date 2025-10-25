import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileProvider extends ChangeNotifier {
  String? _state;
  String? _district;
  String? _block;
  String? _city;

  // Getters
  String? get state => _state;
  String? get district => _district;
  String? get block => _block;
  String? get city => _city;

  // Update location data
  void updateLocation({
    String? state,
    String? district,
    String? block,
    String? city,
  }) {
    _state = state;
    _district = district;
    _block = block;
    _city = city;
    
    // Save to SharedPreferences for persistence
    _saveLocationToPrefs();
    
    notifyListeners();
  }

  // Save location data to SharedPreferences
  Future<void> _saveLocationToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_state != null) await prefs.setString('user_state', _state!);
    if (_district != null) await prefs.setString('user_district', _district!);
    if (_block != null) await prefs.setString('user_block', _block!);
    if (_city != null) await prefs.setString('user_city', _city!);
  }

  // Load location data from SharedPreferences
  Future<void> loadLocationFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    _state = prefs.getString('user_state');
    _district = prefs.getString('user_district');
    _block = prefs.getString('user_block');
    _city = prefs.getString('user_city');
    
    notifyListeners();
  }

  // Clear location data
  void clearLocation() {
    _state = null;
    _district = null;
    _block = null;
    _city = null;
    
    _clearLocationFromPrefs();
    notifyListeners();
  }

  // Clear location data from SharedPreferences
  Future<void> _clearLocationFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove('user_state');
    await prefs.remove('user_district');
    await prefs.remove('user_block');
    await prefs.remove('user_city');
  }

  // Get location as a map (useful for API calls)
  Map<String, String?> getLocationData() {
    return {
      'state': _state,
      'district': _district,
      'block': _block,
      'city': _city,
    };
  }
}