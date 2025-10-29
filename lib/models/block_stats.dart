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