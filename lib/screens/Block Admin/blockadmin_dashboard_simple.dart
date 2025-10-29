import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/application_store.dart';
import '../../models/user_application.dart';
import '../../models/block_stats.dart';
import 'blockadmin_approval_page_simple.dart';
import 'blockadmin_members_page_simple.dart';

class BlockAdminDashboard extends StatelessWidget {
  const BlockAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ApplicationStore>();
    final pending = store.pending;

    return Scaffold(
      appBar: AppBar(title: const Text('Block Admin Dashboard')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Navigation')),
            ListTile(
              title: const Text('Approvals'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlockAdminApprovalPage()),
              ),
            ),
            ListTile(
              title: const Text('Members'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlockAdminMembersPage()),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const BlockStatsWidget(),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: pending.length,
              itemBuilder: (_, i) => _PendingCard(app: pending[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final UserApplication app;
  const _PendingCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final store = context.read<ApplicationStore>();
    return Card(
      child: ExpansionTile(
        title: Text(app.fullName),
        subtitle: const Text('Status: pending'),
        children: [
          _field('Email', app.email),
          _field('Phone', app.phone),
          _field('State', app.state),
          _field('District', app.district),
          _field('Block', app.block),
          OverflowBar(
            children: [
              TextButton(
                onPressed: () async {
                  try {
                    await store.reject(app.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rejected.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('Reject'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await store.approve(app.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Approved!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String k, String v) => ListTile(title: Text(k), subtitle: Text(v));
}