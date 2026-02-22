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
  ConsumerState<CreateTemplateScreen> createState() =>
      _CreateTemplateScreenState();
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
        title: Text(
          widget.template == null ? 'Create Template' : 'Edit Template',
        ),
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
    return _buildPremiumTextField(
      controller: _titleController,
      label: 'Template Title',
      hintText: 'e.g., Morning Meditation',
      icon: Icons.title,
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Please enter a title' : null,
    );
  }

  Widget _buildDescriptionField() {
    return _buildPremiumTextField(
      controller: _descriptionController,
      label: 'Description (Optional)',
      hintText: 'Add details about this template...',
      icon: Icons.description,
      maxLines: 3,
    );
  }

  Widget _buildTimeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Time Investment', Icons.schedule),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      () => _timeMinutes = (_timeMinutes - 5).clamp(5, 999),
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
                      () => _timeMinutes = (_timeMinutes + 5).clamp(5, 999),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.2),
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
      ],
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Difficulty', Icons.local_fire_department_outlined),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Difficulty.values.map((diff) {
            final isSelected = _difficulty == diff;
            return GestureDetector(
              onTap: () => setState(() => _difficulty = diff),
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
                  diff.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primaryPurple.withOpacity(0.9)
                        : Colors.white70,
                  ),
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
        _buildSectionHeader('Category', Icons.category_outlined),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: StatType.values.map((stat) {
            final isSelected = _statType == stat;
            final color = Color(stat.colorValue);
            return GestureDetector(
              onTap: () => setState(() => _statType = stat),
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
                    color: isSelected ? color.withOpacity(0.8) : Colors.white12,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(stat.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(
                      stat.name.toUpperCase(),
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
      ],
    );
  }

  Widget _buildRecurrenceTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Recurrence', Icons.repeat),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: RecurrenceType.values.map((type) {
              final isSelected = _recurrenceType == type;
              return InkWell(
                onTap: () => setState(() => _recurrenceType = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryPurple.withOpacity(0.1)
                        : Colors.transparent,
                    border: Border(
                      bottom: type != RecurrenceType.values.last
                          ? const BorderSide(color: Colors.white12)
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(type.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.displayName,
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.primaryPurple
                                    : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            Text(
                              type.description,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryPurple,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecurrenceOptions() {
    switch (_recurrenceType) {
      case RecurrenceType.weekly:
        return WeekdayPicker(
          selectedDays: _weekdays,
          onChanged: (days) => setState(() => _weekdays = days),
        );
      case RecurrenceType.custom:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Repeat every $_customDays ${_customDays == 1 ? 'day' : 'days'}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _customDays.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                activeColor: AppTheme.primaryPurple,
                onChanged: (value) =>
                    setState(() => _customDays = value.round()),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHabitTrackingToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isHabit ? Colors.orange.withOpacity(0.5) : Colors.white12,
          width: _isHabit ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: IgnorePointer(
          ignoring: false,
          child: SwitchListTile(
            value: _isHabit,
            onChanged: (value) => setState(() => _isHabit = value),
            activeColor: Colors.orange,
            title: const Text(
              'Habit Tracking',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              'Track completion streaks and get habit insights.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ElevatedButton(
        onPressed: _saveTemplate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppTheme.primaryPurple.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          widget.template == null ? 'CREATE TEMPLATE' : 'UPDATE TEMPLATE',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
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
            widget.template == null ? 'Template created!' : 'Template updated!',
          ),
          backgroundColor: AppTheme.primaryPurple,
        ),
      );
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
