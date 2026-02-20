import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'quests/quests_screen.dart';
import 'analytics/productivity_dashboard_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    // Get safe area bottom to properly float the nav bar
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      // extendBody so content renders behind the transparent wrapper,
      // but FAB still anchors ABOVE the nav bar height
      extendBody: true,
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        bottomPad: bottomPad,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM FLOATING BOTTOM NAV BAR
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double bottomPad;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.bottomPad,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NI(
        Icons.home_rounded,
        Icons.home_outlined,
        'Home',
        AppTheme.primaryPurple,
      ),
      _NI(Icons.task_alt, Icons.task_alt_outlined, 'Quests', AppTheme.gold),
      _NI(
        Icons.bar_chart_rounded,
        Icons.bar_chart_outlined,
        'Stats',
        Colors.blue,
      ),
      _NI(Icons.flag_rounded, Icons.flag_outlined, 'Goals', Colors.green),
    ];

    // Total height the scaffold reserves for nav = pill(66) + hPad(8+8) + bottomPad
    return SizedBox(
      height: 66 + 16 + bottomPad,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 66,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF14112A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppTheme.primaryPurple.withOpacity(0.12),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final selected = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: selected
                          ? item.color.withOpacity(0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 220),
                          child: Icon(
                            selected ? item.filled : item.outlined,
                            color: selected ? item.color : Colors.white30,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(
                            color: selected ? item.color : Colors.white30,
                            fontSize: selected ? 10 : 9,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
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
