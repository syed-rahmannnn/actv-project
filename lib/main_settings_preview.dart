import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'services/application_store.dart';
import 'services/user_profile_provider.dart';
import 'screens/Block Admin/blockadmin_dashboard_simple.dart';

void main() {
  final api = ApiService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApplicationStore(api)..bootstrap()),
        ChangeNotifierProvider(create: (_) => _setupUserProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

UserProfileProvider _setupUserProfileProvider() {
  final profile = BlockAdminProfile(
    blockId: 'preview-block-id',
    blockName: 'Preview Block',
    email: 'blockadmin@example.com',
    district: 'Preview District',
    block: 'Preview Block',
    isActive: true,
  );
  
  return UserProfileProvider()..setBlockAdminForPreview(profile);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const BlockAdminDashboard(),
    );
  }
}
