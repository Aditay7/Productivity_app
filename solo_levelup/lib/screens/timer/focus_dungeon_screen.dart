import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/timer_provider.dart';

class FocusDungeonScreen extends ConsumerStatefulWidget {
  const FocusDungeonScreen({super.key});

  @override
  ConsumerState<FocusDungeonScreen> createState() => _FocusDungeonScreenState();
}

class _FocusDungeonScreenState extends ConsumerState<FocusDungeonScreen>
    with WidgetsBindingObserver {
  String _selectedRank = 'C';
  int _selectedDuration = 50;

  final Map<String, int> _ranks = {'E': 25, 'C': 50, 'A': 90, 'S': 120};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the user backgrounds the app or locks phone while active, they fail the raid!
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final timerState = ref.read(timerProvider);
      if (timerState.isActive) {
        ref.read(timerProvider.notifier).failTimer();
      }
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12), // Deeper dark for the dungeon
      appBar: AppBar(
        title: const Text(
          'Focus Dungeon',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white54),
          onPressed: () {
            // Cannot escape if active
            if (state.isActive) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "You cannot escape an active Raid! Fleeing will fail the dungeon.",
                  ),
                ),
              );
              return;
            }
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          // Background ambient glow
          if (state.isActive)
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.15),
                        blurRadius: 150,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (state.isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          else if (state.session?.status == 'completed')
            _buildCompletedScreen(state.session!.xpEarned)
          else if (state.session?.status == 'failed')
            _buildFailedScreen()
          else if (state.isActive)
            _buildActiveRaid(state)
          else
            _buildSetupScreen(),
        ],
      ),
    );
  }

  Widget _buildSetupScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            "SELECT RAID DIFFICULTY",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: _ranks.entries.map((e) {
              final isSelected = _selectedRank == e.key;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRank = e.key;
                    _selectedDuration = e.value;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: (MediaQuery.of(context).size.width - 48 - 16) / 2,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.red.withOpacity(0.15)
                        : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.redAccent : Colors.white12,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${e.key}-RANK',
                        style: TextStyle(
                          color: isSelected ? Colors.redAccent : Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${e.value} MIN',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.redAccent.withOpacity(0.8)
                              : Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          const Text(
            "WARNING: Leaving the app or locking your phone will fail the raid instantly. Abandon all distractions.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(timerProvider.notifier)
                  .startRaid(_selectedDuration, _selectedRank);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 10,
              shadowColor: Colors.redAccent.withOpacity(0.5),
            ),
            child: const Text(
              'ENTER DUNGEON',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildActiveRaid(FocusTimerState state) {
    return Column(
      children: [
        // Boss Health Bar
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: state.progress,
              child: Container(color: Colors.redAccent),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'BOSS HP - ${state.session!.rank}-RANK DUNGEON',
          style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield, color: Colors.white10, size: 100),
                const SizedBox(height: 20),
                Text(
                  _formatTime(state.remainingSeconds),
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'FOCUS MAINTAINED',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1F3A),
                  title: const Text(
                    'FLEE DUNGEON?',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    'Giving up now will result in 0 XP and a failed raid on your record. Flee?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'STAY & FIGHT',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(timerProvider.notifier).failTimer();
                      },
                      child: const Text(
                        'FLEE (FAIL)',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              'FLEE DUNGEON',
              style: TextStyle(color: Colors.white30, letterSpacing: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedScreen(int xp) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withOpacity(0.1),
              border: Border.all(
                color: Colors.amber.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 80,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'BOSS DEFEATED',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '+$xp INT XP',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => ref.read(timerProvider.notifier).resetState(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.withOpacity(0.15),
                foregroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.amber.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                elevation: 0,
              ),
              child: const Text(
                'CLAIM LOOT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent.withOpacity(0.1),
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.dangerous,
              color: Colors.redAccent,
              size: 80,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'RAID FAILED',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'You succumbed to distraction.',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => ref.read(timerProvider.notifier).resetState(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.15),
                foregroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.redAccent.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                elevation: 0,
              ),
              child: const Text(
                'RESURRECT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
