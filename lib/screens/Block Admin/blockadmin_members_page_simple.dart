import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/application_store.dart';

class BlockAdminMembersPage extends StatelessWidget {
  const BlockAdminMembersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ApplicationStore>();
    final members = store.approved; // Only approved members on this tab

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: ListView.builder(
        itemCount: members.length,
        itemBuilder: (_, i) {
          final m = members[i];
          return ListTile(
            title: Text(m.fullName),
            subtitle: const Text('Status: approved'),
          );
        },
      ),
    );
  }
}