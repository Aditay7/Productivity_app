import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/quest_template.dart';
import '../../providers/quest_template_provider.dart';
import '../../core/constants/stat_types.dart';
import '../../core/constants/difficulty.dart';
import '../../core/constants/recurrence_type.dart';
import '../../app/theme.dart';
import '../../widgets/templates/weekday_picker.dart';

/// Screen for creating or editing quest templates
class CreateTemplateScreen extends ConsumerStatefulWidget {
  final QuestTemplate? template;

  const CreateTemplateScreen({super.key, this.template});

  @override
  ConsumerState<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends ConsumerState<CreateTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late int _timeMinutes;
  late Difficulty _difficulty;
  late StatType _statType;
  late RecurrenceType _recurrenceType;
  List<int> _weekdays = [];
  int _customDays = 1;
  late bool _isHabit;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _titleController.text = widget.template!.title;
      _descriptionController.text = widget.template!.description;
      _timeMinutes = widget.template!.timeMinutes;
      _difficulty = widget.template!.difficulty;
      _statType = widget.template!.statType;
      _recurrenceType = widget.template!.recurrenceType;
      _weekdays = widget.template!.weekdays ?? [];
      _customDays = widget.template!.customDays ?? 1;
      _isHabit = widget.template!.isHabit;
    } else {
      _timeMinutes = 30;
      _difficulty = Difficulty.C;
      _statType = StatType.strength;
      _recurrenceType = RecurrenceType.daily;
      _isHabit = false;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? 'Create Template' : 'Edit Template'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 24),
              _buildTimeSlider(),
              const SizedBox(height: 24),
              _buildDifficultySelector(),
              const SizedBox(height: 24),
              _buildStatTypeSelector(),
              const SizedBox(height: 24),
              _buildRecurrenceTypeSelector(),
              const SizedBox(height: 16),
              _buildRecurrenceOptions(),
              const SizedBox(height: 24),
              _buildHabitTrackingToggle(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Quest Title',
        hintText: 'e.g., Morning Meditation',
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description (Optional)',
        hintText: 'Add details about this quest...',
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
    );
  }

  Widget _buildTimeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time: $_timeMinutes minutes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: _timeMinutes.toDouble(),
          min: 5,
          max: 180,
          divisions: 35,
          label: '$_timeMinutes min',
          onChanged: (value) {
            setState(() {
              _timeMinutes = value.round();
            });
          },
        ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Difficulty',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: Difficulty.values.map((diff) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(diff.displayName),
                  selected: _difficulty == diff,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _difficulty = diff;
                      });
                    }
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stat Type',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: StatType.values.map((stat) {
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(stat.emoji),
                  const SizedBox(width: 4),
                  Text(stat.name.toUpperCase()),
                ],
              ),
              selected: _statType == stat,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _statType = stat;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecurrenceTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recurrence',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Column(
          children: RecurrenceType.values.map((type) {
            return RadioListTile<RecurrenceType>(
              title: Row(
                children: [
                  Text(type.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(type.displayName),
                ],
              ),
              subtitle: Text(type.description),
              value: type,
              groupValue: _recurrenceType,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _recurrenceType = value;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecurrenceOptions() {
    switch (_recurrenceType) {
      case RecurrenceType.weekly:
        return WeekdayPicker(
          selectedDays: _weekdays,
          onChanged: (days) {
            setState(() {
              _weekdays = days;
            });
          },
        );
      case RecurrenceType.custom:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repeat every $_customDays ${_customDays == 1 ? 'day' : 'days'}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Slider(
              value: _customDays.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              label: '$_customDays days',
              onChanged: (value) {
                setState(() {
                  _customDays = value.round();
                });
              },
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHabitTrackingToggle() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habit Tracking',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track streaks and get insights',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isHabit,
                  onChanged: (value) {
                    setState(() {
                      _isHabit = value;
                    });
                  },
                ),
              ],
            ),
            if (_isHabit) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This quest will track your completion streak and show up in habit analytics',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveTemplate,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryPurple,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        widget.template == null ? 'Create Template' : 'Update Template',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate weekly selection
    if (_recurrenceType == RecurrenceType.weekly && _weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    final template = QuestTemplate(
      id: widget.template?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      timeMinutes: _timeMinutes,
      difficulty: _difficulty,
      statType: _statType,
      recurrenceType: _recurrenceType,
      weekdays: _recurrenceType == RecurrenceType.weekly ? _weekdays : null,
      customDays: _recurrenceType == RecurrenceType.custom ? _customDays : null,
      createdAt: widget.template?.createdAt ?? DateTime.now(),
      isActive: widget.template?.isActive ?? true,
      lastGeneratedDate: widget.template?.lastGeneratedDate,
      isHabit: _isHabit,
      habitStreak: widget.template?.habitStreak ?? 0,
      habitLastCompletedDate: widget.template?.habitLastCompletedDate,
    );

    if (widget.template == null) {
      await ref.read(questTemplateProvider.notifier).createTemplate(template);
    } else {
      await ref.read(questTemplateProvider.notifier).updateTemplate(template);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.template == null
                ? 'Template created!'
                : 'Template updated!',
          ),
          backgroundColor: AppTheme.primaryPurple,
        ),
      );
    }
  }
}
