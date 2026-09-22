import '../models/job_application.dart';

List<(String, int)> distributionCounts(
  List<JobApplication> apps,
  String Function(JobApplication) field,
) {
  final counts = <String, int>{};
  for (final a in apps) {
    final v = field(a).trim();
    if (v.isEmpty) continue;
    counts[v] = (counts[v] ?? 0) + 1;
  }
  final entries = counts.entries.toList()
    ..sort((a, b) {
      final c = b.value.compareTo(a.value);
      if (c != 0) return c;
      return a.key.compareTo(b.key);
    });
  return entries.map((e) => (e.key, e.value)).toList();
}

List<(String, int)> topDistribution(
  List<JobApplication> apps,
  String Function(JobApplication) field,
  int n,
) {
  final counts = distributionCounts(apps, field);
  if (n <= 0) return [];
  if (counts.length <= n) return counts;
  return counts.sublist(0, n);
}