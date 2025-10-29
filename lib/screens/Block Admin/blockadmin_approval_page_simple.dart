import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/application_store.dart';
import '../../models/user_application.dart';

class BlockAdminApprovalPage extends StatelessWidget {
  const BlockAdminApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ApplicationStore>();
    final pending = store.pending;
    final approved = store.approved;

    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Pending', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...pending.map((a) => _PendingTile(app: a)),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Approved', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...approved.map((a) => _ApprovedTile(app: a)),
        ],
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  final UserApplication app;
  const _PendingTile({required this.app});
  @override
  Widget build(BuildContext context) {
    final store = context.read<ApplicationStore>();
    return ListTile(
      title: Text(app.fullName),
      subtitle: const Text('pending'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => store.reject(app.id)),
        IconButton(icon: const Icon(Icons.check), onPressed: () => store.approve(app.id)),
      ]),
    );
  }
}

class _ApprovedTile extends StatelessWidget {
  final UserApplication app;
  const _ApprovedTile({required this.app});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(app.fullName),
      subtitle: const Text('approved'),
    );
  }
}