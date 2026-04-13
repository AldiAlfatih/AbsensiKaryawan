import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class EmployeeLeaderboard extends ConsumerWidget {
  const EmployeeLeaderboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can reuse allEmployeesProvider which fetches users by role 'employee' and calculate the leaderboard
    // The provider already returns List<AppUser>
    final employeesAsync = ref.watch(allEmployeesProvider);
    final myProfile = ref.watch(currentUserProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Papan Peringkat'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: employeesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (employees) {
            if (employees.isEmpty) {
              return const Center(child: Text('Belum ada data poin karyawan.'));
            }

            // Sort descending by points
            final sorted = List.of(employees)
              ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

            // Top 10
            final topUsers = sorted.take(10).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events_rounded, size: 80, color: Colors.amber),
                        const SizedBox(height: 16),
                        Text(
                          'Karyawan Terbaik Bulan Ini',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kumpulkan poin terbanyak dengan absen tanpa terlambat setiap harinya!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ).animate().fadeIn().slideY(begin: 0.1),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final emp = topUsers[index];
                      final isMe = myProfile != null && myProfile.uid == emp.uid;
                      
                      Color medalColor;
                      if (index == 0) medalColor = Colors.amber;
                      else if (index == 1) medalColor = Colors.grey.shade400;
                      else if (index == 2) medalColor = Colors.brown.shade400;
                      else medalColor = Colors.transparent;

                      return Container(
                        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primaryLight : Colors.white,
                          borderRadius: AppRadius.md,
                          boxShadow: AppShadows.card,
                          border: isMe ? Border.all(color: AppColors.primary) : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: index < 3
                                ? Icon(Icons.workspace_premium_rounded, color: medalColor, size: 28)
                                : Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54), textAlign: TextAlign.center),
                            ),
                            const SizedBox(width: 16),
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isMe ? AppColors.primary : Colors.grey.shade200,
                              child: Text(
                                emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                                style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                emp.name + (isMe ? ' (Kamu)' : ''),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${emp.totalPoints} Pts',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                            ),
                          ],
                        ),
                      ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.05);
                    },
                    childCount: topUsers.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
