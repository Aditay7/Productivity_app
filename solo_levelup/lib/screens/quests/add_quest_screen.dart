import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/quest.dart';
import '../../core/constants/stat_types.dart';
import '../../core/constants/difficulty.dart';
import '../../core/utils/xp_calculator.dart';
import '../../providers/quest_provider.dart';
import '../../providers/player_provider.dart';
import '../../app/theme.dart';
import '../../widgets/common/rpg_button.dart';

/// Add/Edit Quest Screen - create or edit quests
class AddQuestScreen extends ConsumerStatefulWidget {
  final Quest? quest; // Optional quest for editing

  const AddQuestScreen({super.key, this.quest});

  @override
  ConsumerState<AddQuestScreen> createState() => _AddQuestScreenState();
}

class _AddQuestScreenState extends ConsumerState<AddQuestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  StatType _selectedStatType = StatType.strength;
  Difficulty _selectedDifficulty = Difficulty.C;
  int _timeMinutes = 30;
  DateTime? _deadline;
  bool _isLoading = false;

  bool get _isEditing => widget.quest != null;

  @override
  void initState() {
    super.initState();

    // Pre-fill form if editing
    if (_isEditing) {
      _titleController.text = widget.quest!.title;
      _descriptionController.text = widget.quest!.description ?? '';
      _selectedStatType = widget.quest!.statType;
      _selectedDifficulty = widget.quest!.difficulty;
      _timeMinutes = widget.quest!.timeEstimatedMinutes;
      _deadline = widget.quest!.deadline;
    }

    // Force Hard difficulty in Shadow Mode (only for new quests)
    if (!_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final player = ref.read(playerProvider).value;
        if (player?.isShadowMode ?? false) {
          setState(() {
            _selectedDifficulty = Difficulty.B;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStreak = ref.watch(playerStreakProvider);
    final isShadowMode = ref.watch(isShadowModeProvider);
    final xpPreview = XPCalculator.calculateXP(
      timeMinutes: _timeMinutes,
      difficultyMultiplier: _selectedDifficulty.multiplier,
      currentStreak: currentStreak,
      isShadowMode: isShadowMode,
    );

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Quest' : 'New Quest')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title field
                  _buildPremiumTextField(
                    controller: _titleController,
                    label: 'Quest Title',
                    hintText: 'e.g., Deep Work Session',
                    icon: Icons.title,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter a title'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  _buildPremiumTextField(
                    controller: _descriptionController,
                    label: 'Description (Optional)',
                    hintText: 'Extra notes...',
                    icon: Icons.notes,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Category/Stat Selection
                  _buildSectionHeader('Category', Icons.category_outlined),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: StatType.values.map((statType) {
                      final isSelected = _selectedStatType == statType;
                      final color = Color(statType.colorValue);
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedStatType = statType),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.15)
                                : AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? color.withOpacity(0.8)
                                  : Colors.white12,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                statType.emoji,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                statType.displayName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? color.withOpacity(0.9)
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Difficulty Selection
                  _buildSectionHeader(
                    'Difficulty',
                    Icons.local_fire_department_outlined,
                  ),
                  const SizedBox(height: 12),
                  if (isShadowMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade900.withOpacity(0.5),
                            Colors.black,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '⚔️ SHADOW MODE: ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'HARD ONLY',
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Difficulty.values.map((difficulty) {
                        final isSelected = _selectedDifficulty == difficulty;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedDifficulty = difficulty),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryPurple.withOpacity(0.15)
                                  : AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryPurple.withOpacity(0.8)
                                    : Colors.white12,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              difficulty.displayName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.primaryPurple.withOpacity(0.9)
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),

                  // Time Investment
                  _buildSectionHeader('Time Investment', Icons.schedule),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => setState(
                                () => _timeMinutes = (_timeMinutes - 5).clamp(
                                  5,
                                  999,
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  '$_timeMinutes',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.gold,
                                  ),
                                ),
                                const Text(
                                  'MINUTES',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => setState(
                                () => _timeMinutes = (_timeMinutes + 5).clamp(
                                  5,
                                  999,
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryPurple.withOpacity(
                                    0.2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: AppTheme.primaryPurple,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [15, 30, 45, 60].map((mins) {
                            return InkWell(
                              onTap: () => setState(() => _timeMinutes = mins),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _timeMinutes == mins
                                      ? AppTheme.primaryPurple.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _timeMinutes == mins
                                        ? AppTheme.primaryPurple
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  '$mins m',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _timeMinutes == mins
                                        ? Colors.white
                                        : Colors.white54,
                                    fontWeight: _timeMinutes == mins
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // XP Preview
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isShadowMode
                            ? [
                                Colors.purple.shade900.withOpacity(0.4),
                                Colors.black,
                              ]
                            : [AppTheme.gold.withOpacity(0.15), Colors.black],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isShadowMode
                            ? Colors.purple.withOpacity(0.5)
                            : AppTheme.gold.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Expected Reward',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                            if (isShadowMode)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  '⚔️ 3X SHADOW BONUS',
                                  style: TextStyle(
                                    color: Colors.purpleAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+$xpPreview',
                              style: TextStyle(
                                color: isShadowMode
                                    ? Colors.purpleAccent
                                    : AppTheme.gold,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Text(
                                'XP',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(context).viewInsets.bottom > 0
                ? 16
                : 32, // Adjust for keyboard
          ),
          child: Row(
            children: [
              Expanded(
                child: RPGButton(
                  text: 'Cancel',
                  isPrimary: false,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: RPGButton(
                  text: _isEditing ? 'Update Quest' : 'Create Quest',
                  isLoading: _isLoading,
                  onPressed: _saveQuest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveQuest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentStreak = ref.read(playerStreakProvider);
      final isShadowMode = ref.read(isShadowModeProvider);
      final xpReward = XPCalculator.calculateXP(
        timeMinutes: _timeMinutes,
        difficultyMultiplier: _selectedDifficulty.multiplier,
        currentStreak: currentStreak,
        isShadowMode: isShadowMode,
      );

      if (_isEditing) {
        // Update existing quest
        final updatedQuest = widget.quest!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          statType: _selectedStatType,
          difficulty: _selectedDifficulty,
          timeEstimatedMinutes: _timeMinutes,
          deadline: _deadline,
          xpReward: xpReward,
        );

        await ref.read(questProvider.notifier).updateQuest(updatedQuest);
      } else {
        // Create new quest
        final quest = Quest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          statType: _selectedStatType,
          difficulty: _selectedDifficulty,
          timeEstimatedMinutes: _timeMinutes,
          deadline: _deadline,
          xpReward: xpReward,
          createdAt: DateTime.now(),
        );

        await ref.read(questProvider.notifier).createQuest(quest);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Quest updated!' : 'Quest created!'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating quest: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 13,
        ),
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 13,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppTheme.primaryPurple,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
      ),
      validator: validator,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
