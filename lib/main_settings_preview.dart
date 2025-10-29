import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/application_service.dart';
import 'services/user_profile_provider.dart';
import 'models/block_stats.dart';
import 'screens/Block Admin/blockadmin_settings.dart';

class PreviewApplicationService extends ApplicationService {
  PreviewApplicationService() : super('');

  @override
  Future<BlockStats> getBlockStatsModel({required String blockId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const BlockStats(total: 128, pending: 12, approved: 100, rejected: 16);
  }
}

void main() {
  runApp(const _PreviewApp());
}

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    final profile = BlockAdminProfile(
      blockId: 'preview-block-id',
      blockName: 'Preview Block',
      email: 'blockadmin@example.com',
      district: 'Preview District',
      block: 'Preview Block',
      isActive: true,
    );

    final profileProvider = UserProfileProvider()..setBlockAdminForPreview(profile);

    return MultiProvider(
      providers: [
        Provider<ApplicationService>(create: (_) => PreviewApplicationService()),
        ChangeNotifierProvider<UserProfileProvider>(create: (_) => profileProvider),
      ],
      child: MaterialApp(
        title: 'Block Admin Settings Preview',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        home: const BlockAdminSettingsPage(),
      ),
    );
  }
}