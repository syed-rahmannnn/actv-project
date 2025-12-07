import 'package:flutter/material.dart';
import '../Member Registration/registration_step1_screen.dart';
import '../Member Bottom Navigation/dashboard_screen.dart';
import '../Block Admin/blockadmin_dashboard.dart';
import '../District Admin/districtadmin_dashboard.dart';
import '../State Admin/stateadmin_dashboard.dart';
import '../Super Admin/superadmin_dashboard.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey, // Wrap the form fields in a Form widget
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),

                // ACTIV Logo
                Center(
                  child: Image.asset('assets/images/activlogo.png', height: 80),
                ),
                const SizedBox(height: 40),

                // Welcome Back
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  "Sign in to your account or create a new one",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Email Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!, width: 1),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Enter your email",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Password Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!, width: 1),
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: "Enter your password",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Register link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegistrationStep1Screen(),
                        ),
                      );
                    },
                    child: const Text.rich(
                      TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.grey),
                        children: [
                          TextSpan(
                            text: "Register as member",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Divider
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "Or continue with",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Social Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Image.asset(
                          "assets/images/google.png",
                          width: 24,
                          height: 24,
                        ),
                        label: const Text("Continue with Google"),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide.none,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Image.asset(
                          "assets/images/facebook.png",
                          width: 24,
                          height: 24,
                        ),
                        label: const Text("Continue with Facebook"),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide.none,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Image.asset(
                          "assets/images/linkedin.png",
                          width: 24,
                          height: 24,
                        ),
                        label: const Text("Continue with LinkedIn"),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide.none,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Handle login via backend API
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create ApiService instance
      final apiService = ApiService();

      // Check if this looks like an admin email
      // Accept patterns generated by seeding script like:
      // block.<block>.<district>.<state>@activ.com, district.<district>.<state>@activ.com, state.<state>@activ.com
      // Also accept explicit "admin" keywords
      final email = _emailController.text.trim().toLowerCase();
      final isLikelyAdmin =
          email.contains('admin') ||
          (email.contains('@activ.com') &&
              (email.startsWith('block.') ||
                  email.startsWith('district.') ||
                  email.startsWith('state.') ||
                  email.startsWith('super.')));

      // First try admin login with different roles
      Map<String, dynamic>? adminResult;
      final adminRoles = [
        'BlockAdmin',
        'DistrictAdmin',
        'StateAdmin',
        'SuperAdmin',
      ];
      bool adminLoginAttempted = false;
      String? lastAdminError;

      for (String role in adminRoles) {
        try {
          adminLoginAttempted = true;
          adminResult = await apiService.loginAdmin(
            _emailController.text.trim(),
            _passwordController.text,
            role,
          );
          if (adminResult['ok'] == true) {
            // Admin login successful
            final token = adminResult['token'];
            final adminRole = adminResult['role'];
            final adminData =
                adminResult['body'] ??
                adminResult; // Extract from body first, fallback to adminResult
            final adminId =
                adminData['id'] ??
                adminResult['adminId']; // Get id from body first
            final mongoId =
                adminData['id'] ??
                adminResult['mongoId']; // Get id from body first
            final apiBaseUrl = ApiService.baseUrl;

            final userDataToSave = {
              'adminId': adminId, // Using the MongoDB _id as adminId
              'mongoId':
                  mongoId, // Store MongoDB _id separately for backward compatibility
              'role': adminRole,
              'email': adminData['email'] ?? _emailController.text.trim(),
              'fullName': adminData['fullName'] ?? '',
              'adminName': adminData['fullName'] ?? '', // Alias for fullName
              'block':
                  adminData['location']?['block'] ??
                  adminData['meta']?['block'] ??
                  '',
              'blockName':
                  adminData['location']?['block'] ??
                  adminData['meta']?['block'] ??
                  '', // Extract from location.block first
              'district':
                  adminData['location']?['district'] ??
                  adminData['meta']?['district'] ??
                  '',
              'districtName':
                  adminData['location']?['district'] ??
                  adminData['meta']?['district'] ??
                  '', // Extract from location.district first
              'state':
                  adminData['location']?['state'] ??
                  adminData['meta']?['state'] ??
                  '',
              'stateName':
                  adminData['location']?['state'] ??
                  adminData['meta']?['state'] ??
                  '', // Extract from location.state first
              'active': adminData['active'] ?? true,
              'isAdmin': true,
              // Add meta structure that AuthProvider expects
              'meta': {
                'state':
                    adminData['location']?['state'] ??
                    adminData['meta']?['state'] ??
                    '',
                'district':
                    adminData['location']?['district'] ??
                    adminData['meta']?['district'] ??
                    '',
                'block':
                    adminData['location']?['block'] ??
                    adminData['meta']?['block'] ??
                    '',
                'stateName':
                    adminData['location']?['state'] ??
                    adminData['meta']?['state'] ??
                    '',
                'districtName':
                    adminData['location']?['district'] ??
                    adminData['meta']?['district'] ??
                    '',
                'blockName':
                    adminData['location']?['block'] ??
                    adminData['meta']?['block'] ??
                    '',
              },
            };

            // Save admin login data with complete metadata
            await AuthService.saveLoginData(
              token: token,
              userData: userDataToSave,
            );

            if (mounted) {
              // Route based on admin role
              if (adminRole == 'BlockAdmin') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlockAdminDashboard(
                      apiBaseUrl: apiBaseUrl,
                      authToken: token,
                      blockAdminId: adminId,
                      blockName: adminData['block'] ?? 'Unknown Block',
                      adminEmail: adminData['email'] ?? '',
                    ),
                  ),
                );
              } else if (adminRole == 'DistrictAdmin') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DistrictAdminDashboard(adminId: adminId),
                  ),
                );
              } else if (adminRole == 'StateAdmin') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StateAdminDashboard(adminId: adminId),
                  ),
                );
              } else if (adminRole == 'SuperAdmin') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SuperAdminDashboard(adminId: adminId),
                  ),
                );
              } else {
                // For any other admin roles, show a placeholder message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$adminRole dashboard not implemented yet'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
            return; // Exit the function after successful admin login
          } else {
            // Store the last admin error message
            lastAdminError =
                adminResult['body']?['message'] ?? 'Admin login failed';
          }
        } catch (e) {
          // Store the error and continue to next role
          lastAdminError = 'Admin login error: $e';
          continue;
        }
      }

      // If this looks like an admin email and admin login failed, show admin error
      if (isLikelyAdmin && adminLoginAttempted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lastAdminError ?? 'Admin not found or invalid credentials',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return; // Don't try member login for admin emails
      }

      // If admin login failed and it's not obviously an admin email, try regular member login
      final result = await apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result['ok'] == true) {
        // Member login successful
        // Safely extract member data with proper type checking
        final body = result['body'];
        if (body == null || body is! Map) {
          throw Exception('Invalid response format: body is null or not a Map');
        }
        
        // Handle different possible response structures
        Map<String, dynamic> member;
        
        // Try to extract member data from different possible structures
        if (body['data'] != null && body['data'] is Map) {
          // Structure: { data: { member: {...} } }
          final data = body['data'] as Map;
          if (data['member'] != null && data['member'] is Map) {
            member = Map<String, dynamic>.from(data['member'] as Map);
          } else {
            member = Map<String, dynamic>.from(data);
          }
        } else if (body['member'] != null && body['member'] is Map) {
          // Structure: { member: {...} }
          member = Map<String, dynamic>.from(body['member'] as Map);
        } else {
          // Fallback: use body directly if it contains member fields
          member = Map<String, dynamic>.from(body);
        }
        final token = result['token'];

        // Debug: Print what member data we got from login
        print('=== LOGIN SUCCESS DEBUG ===');
        print('Member data from API: $member');
        print('Member keys: ${member.keys.toList()}');
        if (member['id'] != null) {
          print('Found member.id: ${member['id']}');
        }
        if (member['_id'] != null) {
          print('Found member._id: ${member['_id']}');
        }
        if (member['memberId'] != null) {
          print('Found member.memberId: ${member['memberId']}');
        }

        // Ensure member has memberId field for consistency
        if (member['id'] != null && member['memberId'] == null) {
          member['memberId'] = member['id'];
          print('📝 Added memberId from id: ${member['memberId']}');
        }

        await AuthService.saveLoginData(token: token, userData: member);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(userData: member),
            ),
          );
        }
      } else {
        // Member login also failed
        final errorMessage = result['body']?['message'] ?? 'Login failed';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
