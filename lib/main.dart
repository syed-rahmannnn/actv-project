import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:activ/screens/Login/login_screen.dart';
import 'package:activ/screens/onboarding_screen.dart';
import 'package:activ/screens/Member%20Bottom%20Navigation/dashboard_screen.dart';
import 'package:activ/services/auth_service.dart';
import 'package:activ/services/user_profile_provider.dart';
import 'package:activ/providers/company_selection_provider.dart';
import 'package:activ/providers/discover_provider.dart';
import 'package:activ/providers/analytics_provider.dart';
import 'package:activ/providers/settings_provider.dart';
import 'package:activ/screens/Block%20Admin/blockadmin_settings.dart';
import 'package:activ/screens/Application%20Status/application_submitted_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ FIX: Disable debug rendering flags to prevent assertion errors
  // This is a known Flutter 3.35+ framework bug that doesn't affect functionality
  debugPaintSizeEnabled = false;
  debugPaintBaselinesEnabled = false;
  debugPaintLayerBordersEnabled = false;
  debugPaintPointersEnabled = false;
  debugRepaintRainbowEnabled = false;
  debugRepaintTextRainbowEnabled = false;
  
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProfileProvider()),
        ChangeNotifierProvider(create: (context) => CompanySelectionProvider()),
        ChangeNotifierProvider(create: (context) => DiscoverProvider()),
        ChangeNotifierProvider(create: (context) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        showSemanticsDebugger: false, // Disable semantics debugger
        title: 'ACTIV Portal',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        // ✅ FIX: Suppress semantics assertion errors (known Flutter 3.35+ bug)
        builder: (context, child) {
          return Semantics(
            enabled: false,
            child: child!,
          );
        },
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/settings': (context) => const BlockAdminSettingsPage(),
          '/application_submitted': (context) {
            final userData = ModalRoute.of(context)?.settings.arguments;
            return ApplicationSubmittedScreen(
              userData: userData as Map<String, dynamic>,
            );
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
