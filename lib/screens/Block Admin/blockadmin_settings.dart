import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/block_stats.dart';
import '../../services/application_service.dart';
import '../../services/user_profile_provider.dart';

class BlockAdminSettingsPage extends StatefulWidget {
  final String? apiBaseUrl;
  final String? token;
  final String? authToken;
  final String? blockAdminId;
  final String? blockName;
  final String? blockEmail;
  final bool? isActive;
  const BlockAdminSettingsPage({
    super.key,
    this.apiBaseUrl,
    this.token,
    this.authToken,
    this.blockAdminId,
    this.blockName,
    this.blockEmail,
    this.isActive,
  });

  @override
  State<BlockAdminSettingsPage> createState() => _BlockAdminSettingsPageState();
}

class _BlockAdminSettingsPageState extends State<BlockAdminSettingsPage> {
  late final ApplicationService _appService;

  Future<(BlockStats, BlockAdminProfile)> _load() async {
    final profileProvider = context.read<UserProfileProvider>();

    // Ensure profile exists
    if (profileProvider.blockAdmin == null) {
      await profileProvider.loadBlockAdminProfileAuto();
    }
    final profile = profileProvider.blockAdmin!;
    final blockId = profile.blockId;

    // Stats
    final stats = await _appService.getBlockStatsModel(blockId: blockId);

    return (stats, profile);
  }

  @override
  void initState() {
    super.initState();
    // You already construct ApplicationService elsewhere; if not, build it here:
    _appService = context.read<ApplicationService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: FutureBuilder<(BlockStats, BlockAdminProfile)>(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load settings. ${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final (stats, profile) = snap.data!;
          final blockName = profile.blockName?.trim().isNotEmpty == true
              ? profile.blockName!.trim()
              : '—';
          final email = profile.email?.trim().isNotEmpty == true
              ? profile.email!.trim()
              : '—';
          final area = [
            if ((profile.district ?? '').isNotEmpty) profile.district,
            if ((profile.block ?? '').isNotEmpty) profile.block,
          ].whereType<String>().join(', ');
          final areaText = area.isNotEmpty ? area : '—';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        child: Text(
                          (blockName.isNotEmpty && blockName != '—')
                              ? blockName[0].toUpperCase()
                              : 'B',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              blockName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.mail, size: 16),
                                const SizedBox(width: 6),
                                Flexible(child: Text(email)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.place, size: 16),
                                const SizedBox(width: 6),
                                Flexible(child: Text(areaText)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Active Status: '),
                                Chip(
                                  label: Text(
                                    (profile.isActive == true)
                                        ? 'Active'
                                        : 'Inactive',
                                  ),
                                  backgroundColor: (profile.isActive == true)
                                      ? Colors.green.withOpacity(.15)
                                      : Colors.grey.withOpacity(.15),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Stats card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _statRow('Total Members', stats.total),
                      const SizedBox(height: 10),
                      _statRow('Pending Approvals', stats.pending),
                      const SizedBox(height: 10),
                      _statRow('Approved', stats.approved),
                      const SizedBox(height: 10),
                      _statRow('Rejected', stats.rejected),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Support
              Card(
                child: ListTile(
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // navigate to support
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statRow(String label, int value) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
