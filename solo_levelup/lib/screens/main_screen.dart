import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'quests/quests_screen.dart';
import 'quests/add_quest_screen.dart';
import 'analytics/productivity_dashboard_screen.dart';
import 'templates/manage_templates_screen.dart';
import 'goals/create_goal_screen.dart';
import 'goals/goals_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const QuestsScreen(),
    const ProductivityDashboardScreen(),
    const GoalsScreen(),
  ];

  void _openForgeSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ForgeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        onForgeTap: _openForgeSheet,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORGE BOTTOM SHEET  — the action menu that pops out from the center button
// ─────────────────────────────────────────────────────────────────────────────
class _ForgeSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1630),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),

          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt, color: AppTheme.gold, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FORGE',
                    style: TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'Create something great',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),
          Container(height: 1, color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 20),

          // Action tiles
          _ForgeTile(
            icon: Icons.add_circle_outline_rounded,
            iconColor: AppTheme.primaryPurple,
            title: 'New Quest',
            subtitle: 'Add a one-time or recurring mission',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddQuestScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _ForgeTile(
            icon: Icons.library_books_outlined,
            iconColor: const Color(0xFF4ECDC4),
            title: 'New Template',
            subtitle: 'Build a reusable quest blueprint',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageTemplatesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _ForgeTile(
            icon: Icons.flag_outlined,
            iconColor: Colors.green,
            title: 'New Goal',
            subtitle: 'Set a monthly or yearly milestone',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ForgeTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ForgeTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_ForgeTile> createState() => _ForgeTileState();
}

class _ForgeTileState extends State<_ForgeTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF120F25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.iconColor.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.iconColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: widget.iconColor.withOpacity(0.4),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOATING NAV BAR  with center FORGE button
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onForgeTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onForgeTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final left = [
      _NI(
        Icons.home_rounded,
        Icons.home_outlined,
        'Home',
        AppTheme.primaryPurple,
      ),
      _NI(Icons.task_alt, Icons.task_alt_outlined, 'Quests', AppTheme.gold),
    ];
    final right = [
      _NI(
        Icons.bar_chart_rounded,
        Icons.bar_chart_outlined,
        'Stats',
        Colors.blue,
      ),
      _NI(
        Icons.favorite_rounded,
        Icons.favorite_border_rounded,
        'Cardio',
        Colors.redAccent,
      ),
    ];

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: bottomPad + 12,
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF120F25),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left tabs (Home, Quests)
            ...left.asMap().entries.map((e) => _tabItem(e.key, e.value)),

            // ─── Center FORGE button ───
            _ForgeButton(onTap: onForgeTap),

            // Right tabs (Stats, Goals) — indices 2, 3
            ...right.asMap().entries.map((e) => _tabItem(e.key + 2, e.value)),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(int i, _NI item) {
    final selected = currentIndex == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(i),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? item.color.withOpacity(0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.14 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  selected ? item.filled : item.outlined,
                  color: selected ? item.color : Colors.white30,
                  size: 21,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: selected ? item.color : Colors.white30,
                  fontSize: 9.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Glowing center Forge button ──────────────────────────────────────────────
class _ForgeButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ForgeButton({required this.onTap});

  @override
  State<_ForgeButton> createState() => _ForgeButtonState();
}

class _ForgeButtonState extends State<_ForgeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glow = Tween(
      begin: 0.4,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedBuilder(
          animation: _glow,
          builder: (_, child) => Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withOpacity(_glow.value * 0.6),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.bolt, color: Colors.black, size: 26),
          ),
        ),
      ),
    );
  }
}

class _NI {
  final IconData filled, outlined;
  final String label;
  final Color color;
  const _NI(this.filled, this.outlined, this.label, this.color);
}
