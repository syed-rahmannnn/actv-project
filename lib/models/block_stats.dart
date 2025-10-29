import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/application_store.dart';

// Data model for block statistics
class BlockStats {
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const BlockStats({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });
}

// Widget to display block statistics
class BlockStatsWidget extends StatelessWidget {
  const BlockStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ApplicationStore>();
    return Row(
      children: [
        _StatCard(label: 'Pending', count: store.pendingCount),
        _StatCard(label: 'Approved', count: store.approvedCount),
        _StatCard(label: 'Rejected', count: store.rejectedCount),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  const _StatCard({required this.label, required this.count});
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('$count'),
          ]),
        ),
      ),
    );
  }
}

// Legacy model class for backward compatibility
class BlockStatsModel {
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const BlockStatsModel({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });
}