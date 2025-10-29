import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_service.dart';

class BlockAdminProfile {
  final String blockId;
  final String? blockName;
  final String? email;
  final String? district;
  final String? block;
  final bool? isActive;

  BlockAdminProfile({
    required this.blockId,
    this.blockName,
    this.email,
    this.district,
    this.block,
    this.isActive,
  });

  factory BlockAdminProfile.fromJson(Map<String, dynamic> json) {
    return BlockAdminProfile(
      blockId: (json['blockId'] ?? json['id'] ?? json['_id'] ?? '').toString(),
      blockName: (json['blockName'] ?? json['name'] ?? json['block_name'])?.toString(),
      email: (json['email'])?.toString(),
      district: (json['district'] ?? json['districtName'])?.toString(),
      block: (json['block'] ?? json['blockName'])?.toString(),
      isActive: (json['active'] == true) || (json['isActive'] == true),
    );
  }
}

class UserProfileProvider extends ChangeNotifier {
  BlockAdminProfile? _blockAdmin;
  String? _state;
  String? _district;
  String? _block;
  String? _city;

  // Getters
  String? get state => _state;
  String? get district => _district;
  String? get block => _block;
  String? get city => _city;
  BlockAdminProfile? get blockAdmin => _blockAdmin;
  String? get blockId => _blockAdmin?.blockId;

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

  // Load the logged-in Block Admin profile
  Future<void> loadBlockAdminProfile({
    required String baseUrl,
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/block-admin/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) {
        _blockAdmin = BlockAdminProfile.fromJson(body);
        notifyListeners();
        return;
      }
    }

    // Fallback: try a generic admin profile endpoint if available
    try {
      final alt = await http.get(
        Uri.parse('$baseUrl/admin/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (alt.statusCode == 200) {
        final body = jsonDecode(alt.body);
        if (body is Map<String, dynamic>) {
          _blockAdmin = BlockAdminProfile.fromJson(body);
          notifyListeners();
        }
      }
    } catch (_) {
      // ignore errors; leave profile as null
    }
  }

  // Convenience: load profile using global services (no args required)
  Future<void> loadBlockAdminProfileAuto() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return;
    await loadBlockAdminProfile(baseUrl: ApiService.baseUrl, token: token);
  }

  // Preview/testing helper to inject a BlockAdmin profile without network.
  void setBlockAdminForPreview(BlockAdminProfile profile) {
    _blockAdmin = profile;
    notifyListeners();
  }
}