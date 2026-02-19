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
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Quest Title',
                      hintText: 'e.g., Morning gym session',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Optional notes...',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Stat Type Selection
                  Text(
                    'Stat Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: StatType.values.map((statType) {
                      final isSelected = _selectedStatType == statType;
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(statType.emoji),
                            const SizedBox(width: 8),
                            Text(statType.displayName),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatType = statType;
                          });
                        },
                        selectedColor: Color(
                          statType.colorValue,
                        ).withOpacity(0.3),
                        backgroundColor: AppTheme.cardBackground,
                        side: BorderSide(
                          color: isSelected
                              ? Color(statType.colorValue)
                              : Colors.white24,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Difficulty Selection
                  Text(
                    'Difficulty',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (isShadowMode)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade900, Colors.black],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '⚔️ SHADOW MODE: ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'HARD ONLY',
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: Difficulty.values.map((difficulty) {
                        final isSelected = _selectedDifficulty == difficulty;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Center(
                                child: Text(
                                  difficulty.displayName,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedDifficulty = difficulty;
                                });
                              },
                              selectedColor: AppTheme.primaryPurple.withOpacity(
                                0.3,
                              ),
                              backgroundColor: AppTheme.cardBackground,
                              side: BorderSide(
                                color: isSelected
                                    ? AppTheme.primaryPurple
                                    : Colors.white24,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),

                  // Time Investment
                  Text(
                    'Time Investment',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryPurple.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _timeMinutes = (_timeMinutes - 5).clamp(5, 999);
                            });
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppTheme.gold,
                        ),
                        Column(
                          children: [
                            Text(
                              '$_timeMinutes',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            Text(
                              'minutes',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.white54),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _timeMinutes = (_timeMinutes + 5).clamp(5, 999);
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppTheme.gold,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick time buttons
                  Row(
                    children: [15, 30, 60].map((minutes) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _timeMinutes = minutes;
                              });
                            },
                            child: Text('+$minutes min'),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // XP Preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isShadowMode
                          ? Colors.purple.shade900.withOpacity(0.3)
                          : AppTheme.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isShadowMode
                            ? Colors.purple
                            : AppTheme.gold.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'XP Reward',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (isShadowMode)
                              Text(
                                '⚔️ 3X SHADOW BONUS',
                                style: TextStyle(
                                  color: Colors.purple.shade300,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          '+$xpPreview XP',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: isShadowMode
                                    ? Colors.purple.shade300
                                    : AppTheme.gold,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
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
                ],
              ),
            ),
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
}
