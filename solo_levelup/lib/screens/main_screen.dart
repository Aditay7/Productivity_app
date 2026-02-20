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
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOATING NAV BAR  (no extendBody — FAB auto-anchors above this widget)
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
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

    return Container(
      // Transparent outer so background shows through the gaps
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
          children: items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final selected = currentIndex == i;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: selected
                        ? item.color.withOpacity(0.16)
                        : Colors.transparent,
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
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          letterSpacing: 0.2,
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
    );
  }
}

class _NI {
  final IconData filled, outlined;
  final String label;
  final Color color;
  const _NI(this.filled, this.outlined, this.label, this.color);
}
