import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/goal_provider.dart';
import '../../app/theme.dart';
import 'create_goal_screen.dart';

import '../cardio/cardio_screen.dart';
import '../settings/settings_screen.dart';

const _kCard = Color(0xFF1A1630);
const _kSurface = Color(0xFF120F25);

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Row(
        children: [
          // ── Advanced Vertical Sidebar ──────────────────────────────
          const _AdvancedVerticalSidebar(),

          // ── Main Content Area ──────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // ── Custom Header ────────────────────────────────────
                _GoalsHeader(goalsAsync: goalsAsync),

                // ── Content ──────────────────────────────────────────
                Expanded(
                  child: goalsAsync.when(
                    data: (goals) {
                      final active = goals.where((g) => g.isActive).toList();
                      final completed = goals
                          .where((g) => !g.isActive)
                          .toList();

                      if (active.isEmpty && completed.isEmpty) {
                        return _EmptyGoals();
                      }

                      return RefreshIndicator(
                        onRefresh: () async => ref.invalidate(goalProvider),
                        color: AppTheme.gold,
                        backgroundColor: _kCard,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          children: [
                            if (active.isNotEmpty) ...[
                              _GroupLabel(
                                'Active Goals',
                                active.length,
                                Colors.green,
                              ),
                              const SizedBox(height: 8),
                              ...active.map(
                                (g) => _GoalCard(
                                  goal: g,
                                  isActive: true,
                                  ref: ref,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (completed.isNotEmpty) ...[
                              _GroupLabel(
                                'Completed Goals',
                                completed.length,
                                Colors.white38,
                              ),
                              const SizedBox(height: 8),
                              ...completed.map(
                                (g) => _GoalCard(
                                  goal: g,
                                  isActive: false,
                                  ref: ref,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppTheme.gold),
                    ),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$e',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(goalProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _NewGoalFAB(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _GoalsHeader extends StatelessWidget {
  final AsyncValue goalsAsync;
  const _GoalsHeader({required this.goalsAsync});

  @override
  Widget build(BuildContext context) {
    final active = goalsAsync.maybeWhen(
      data: (g) => (g as List).where((x) => x.isActive).length,
      orElse: () => 0,
    );

    return Container(
      color: _kSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: Colors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GOAL TRACKER',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'My Goals',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (active > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.35)),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$active',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const TextSpan(
                          text: ' active',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GROUP LABEL
// ─────────────────────────────────────────────────────────────────────────────
class _GroupLabel extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _GroupLabel(this.title, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOAL CARD
// ─────────────────────────────────────────────────────────────────────────────
class _GoalCard extends StatefulWidget {
  final dynamic goal;
  final bool isActive;
  final WidgetRef ref;
  const _GoalCard({
    required this.goal,
    required this.isActive,
    required this.ref,
  });
  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    final double pct = (widget.goal.progressPercentage / 100.0).clamp(0.0, 1.0);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(
      begin: 0.0,
      end: pct,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final progress = goal.progressPercentage as double;
    final done = progress >= 100;
    final typeColor = _typeColor(goal.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeColor.withOpacity(widget.isActive ? 0.3 : 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: icon + title + badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_typeIcon(goal.type), color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(
                          color: widget.isActive
                              ? Colors.white
                              : Colors.white54,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          decoration: widget.isActive
                              ? null
                              : TextDecoration.lineThrough,
                          decorationColor: Colors.white30,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _typeLabel(goal.type),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                done
                    ? const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 26,
                      )
                    : Text(
                        '${progress.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ],
            ),

            // Description
            if ((goal.description as String).isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                goal.description,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Progress bar
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: _anim.value,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: done ? Colors.green : typeColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Value row + stat chip
            Row(
              children: [
                Text(
                  '${goal.currentValue} / ${goal.targetValue} ${goal.unit.displayName}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (goal.statType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statName(goal.statType),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),

            // Milestones
            if ((goal.milestones as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Milestones',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              ...goal.milestones.take(3).map<Widget>((m) {
                final reached =
                    (goal.currentValue as num) >= (m.targetValue as num);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Icon(
                        reached
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 14,
                        color: reached ? Colors.green : Colors.white24,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          m.title,
                          style: TextStyle(
                            color: reached ? Colors.white38 : Colors.white60,
                            fontSize: 11,
                            decoration: reached
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: Colors.white24,
                          ),
                        ),
                      ),
                      Text(
                        '${m.targetValue} ${goal.unit.displayName}',
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Achievements banner
            if ((goal.achievements as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${goal.achievements.length} Achievement${goal.achievements.length > 1 ? 's' : ''} unlocked',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            if (widget.isActive) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateGoalScreen(goal: widget.goal),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  GestureDetector(
                    onTap: () => _confirmDelete(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 14,
                            color: Colors.red,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Goal', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${widget.goal.title}"?',
          style: const TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await widget.ref
                    .read(goalProvider.notifier)
                    .deleteGoal(widget.goal.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Goal deleted'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _typeColor(dynamic t) {
    switch (t.toString().split('.').last) {
      case 'monthly':
        return Colors.blue;
      case 'yearly':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  IconData _typeIcon(dynamic t) {
    switch (t.toString().split('.').last) {
      case 'monthly':
        return Icons.calendar_today;
      case 'yearly':
        return Icons.calendar_month;
      default:
        return Icons.flag;
    }
  }

  String _typeLabel(dynamic t) {
    switch (t.toString().split('.').last) {
      case 'monthly':
        return 'Monthly Goal';
      case 'yearly':
        return 'Yearly Goal';
      default:
        return 'Custom Goal';
    }
  }

  String _statName(String? s) {
    if (s == null) return '';
    const m = {
      'strength': 'Strength',
      'intelligence': 'Intelligence',
      'discipline': 'Discipline',
      'wealth': 'Wealth',
      'charisma': 'Charisma',
    };
    return m[s.toLowerCase()] ?? s;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyGoals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('🎯', style: TextStyle(fontSize: 52)),
          SizedBox(height: 14),
          Text(
            'No Goals Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tap the button below to create\nyour first goal!',
            style: TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEW GOAL FAB
// ─────────────────────────────────────────────────────────────────────────────
class _NewGoalFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'New Goal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADVANCED VERTICAL SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
class _AdvancedVerticalSidebar extends StatelessWidget {
  const _AdvancedVerticalSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(left: 12, top: 24, bottom: 24, right: 8),
      decoration: BoxDecoration(
        color: _kCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Sidebar decorative top handle
          Container(
            width: 24,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _SidebarItem(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Cardio',
                    color: Colors.redAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CardioScreen()),
                    ),
                  ),
                  const SizedBox(height: 28),

                  _SidebarItem(
                    icon: Icons.settings_outlined,
                    label: 'Options',
                    color: Colors.white70,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          // Decorative bottom fading line
          Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.white.withOpacity(0.05), Colors.transparent],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) {
        setState(() => _isHovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(_isHovered ? 4.0 : 0.0, 0.0, 0.0)
          ..scale(_isHovered ? 1.05 : 1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(_isHovered ? 0.2 : 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(_isHovered ? 0.6 : 0.15),
                  width: _isHovered ? 1.5 : 1.0,
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: widget.color.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.color.withOpacity(_isHovered ? 1.0 : 0.6),
                fontSize: 10,
                fontWeight: _isHovered ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
