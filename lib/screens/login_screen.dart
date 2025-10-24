import 'package:flutter/material.dart';
import 'registration_step1_screen.dart';
import 'dashboard_screen.dart';
import 'blockadmin_dashboard.dart';
import 'districtadmin_dashboard.dart';
import 'stateadmin_dashboard.dart';
import 'superadmin_dashboard.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

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

      // Check if this looks like an admin email (contains admin-related keywords)
      final email = _emailController.text.trim().toLowerCase();
      final isLikelyAdmin =
          email.contains('admin') ||
          email.contains('blockadmin') ||
          email.contains('districtadmin') ||
          email.contains('stateadmin') ||
          email.contains('superadmin');

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
            final adminId = adminResult['adminId'];

            // Save admin login data
            await AuthService.saveLoginData(
              token: token,
              userData: {
                'adminId': adminId,
                'role': adminRole,
                'email': _emailController.text.trim(),
                'isAdmin': true,
              },
            );

            if (mounted) {
              // Route based on admin role
              if (adminRole == 'BlockAdmin') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlockAdminDashboard(adminId: adminId),
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
        final member = result['body']['data']['member'];
        final token = result['token'];

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
