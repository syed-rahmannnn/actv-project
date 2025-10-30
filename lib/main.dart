import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:activ/screens/Login/login_screen.dart';
import 'package:activ/screens/onboarding_screen.dart';
import 'package:activ/screens/Member%20Bottom%20Navigation/dashboard_screen.dart';
import 'package:activ/services/auth_service.dart';
import 'package:activ/services/user_profile_provider.dart';
import 'package:activ/screens/Block%20Admin/blockadmin_settings.dart';
import 'package:activ/screens/Application%20Status/application_submitted_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProfileProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ACTIV Portal',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/settings': (context) => const BlockAdminSettingsPage(),
          '/application_submitted': (context) {
            final userData = ModalRoute.of(context)?.settings.arguments;
            return ApplicationSubmittedScreen(userData: userData as Map<String, dynamic>);
          },
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: AuthService.getUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.data != null) {
                return DashboardScreen(userData: userSnapshot.data!);
              }

              return const OnboardingScreen();
            },
          );
        }

        return const OnboardingScreen();
      },
    );
  }
}
